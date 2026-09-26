import Foundation
import Observation
import os

/// Status of the user's focus commitment.
enum FocusSessionStatus: Equatable {
    /// Ready for the user to choose their target time and begin.
    case notStarted
    /// Focus session in progress. Time is counting down.
    case active
    /// Full duration completed with focus. Reward granted, new city state saved!
    case completed
    /// User stopped manually before target was reached. Progress reverted to initial state.
    case cancelled
    /// Timer finished but phone was used/destroyed during session. Damaged state saved.
    case penaltyEnded
}

/// The single source of truth. Views read from it; only `RootView` feeds it hardware input.
///
/// - Inputs: `hingeDidChange`, `sizeClassDidChange`, `scenePhaseDidChange` (+ `simulate…` for debug).
/// - World: `map` (roads, lots, towers) and `actors` (cats), stored separately so views that
///   only draw the map don't redraw on every cat step.
/// - Logic: each tick runs `builder` (Dev A) or `destroyer` (Dev B) depending on `state.mode`.
@Observable
final class KaijuEngine {
    // MARK: World

    private(set) var map: CityMap
    private(set) var actors: CityActors
    private(set) var builder = BuilderBrain()
    private(set) var destroyer = DestroyerBrain()

    // MARK: Focus Session & Game Mechanics

    private(set) var sessionStatus: FocusSessionStatus = .notStarted
    var targetFocusDuration: TimeInterval = 25 * 60 // Default: 25 minutes
    private(set) var sessionElapsed: TimeInterval = 0

    // Initial state snapshot saved at session start. Used for 100% rollback on early cancel.
    private var initialMapSnapshot: CityMap?
    private var initialActorsSnapshot: CityActors?
    private var initialCityHealth: Double = 100

    var remainingSessionTime: TimeInterval {
        max(0, targetFocusDuration - sessionElapsed)
    }

    var isSessionActive: Bool {
        sessionStatus == .active
    }

    // MARK: Score

    private(set) var cityHealth: Double = 100
    /// Seconds of uninterrupted focus in the current session. Wiped by rampage.
    private(set) var focusSeconds: TimeInterval = 0

    // MARK: Event counters (use as `.onChange` / `.sensoryFeedback` / animation triggers)

    private(set) var floorsBuiltCount = 0
    private(set) var floorsDestroyedCount = 0
    private(set) var blocksDevelopedCount = 0
    private(set) var lastChangedLot: GridPoint?
    private(set) var catsEatenCount = 0
    private(set) var lastEatenPosition: GridPoint?
    /// Set when the app returns from the background with decay applied.
    private(set) var neglectReport: NeglectReport?

    // MARK: Inputs

    private(set) var realHinge: HingeReading?
    private(set) var isCompactWidth = false
    private(set) var isBackgrounded = false
    private var backgroundedAt: Date?

    // MARK: Debug / demo controls

    private(set) var simulatedHinge: HingeReading?
    private(set) var simulatedMultitasking: Bool?
    var isDemoMode = true

    private let haptics = HapticsController()
    private static let log = Logger(subsystem: "com.monstersink.MonsterInTheBox", category: "Engine")

    init() {
        if let saved = CityPersistence.load() {
            let restoredMap = CityMap(snapshot: saved)
            map = restoredMap
            cityHealth = saved.cityHealth
            floorsBuiltCount = saved.floorsBuiltCount
            floorsDestroyedCount = saved.floorsDestroyedCount
            blocksDevelopedCount = saved.blocksDevelopedCount
            focusSeconds = saved.totalFocusSeconds

            var world = CityWorld(
                map: restoredMap,
                actors: CityActors(hero: CatActor(id: 0, look: .hero, position: restoredMap.startingPosition, stepDuration: GameTuning.heroStep))
            )
            for _ in 0..<max(GameTuning.startingCitizens, restoredMap.developedBlocks.count) {
                world.addCitizen()
            }
            actors = world.actors
        } else {
            let world = CityWorld()
            map = world.map
            actors = world.actors
        }
    }

    // MARK: Persistence

    func persistCurrentState() {
        let snapshot = map.toSnapshot(
            cityHealth: cityHealth,
            floorsBuilt: floorsBuiltCount,
            floorsDestroyed: floorsDestroyedCount,
            blocksDeveloped: blocksDevelopedCount,
            totalFocusSeconds: focusSeconds
        )
        CityPersistence.save(snapshot)
    }

    // MARK: Derived state

    /// The effective hinge: simulated if set, else physical, else closed.
    var hinge: HingeReading { simulatedHinge ?? realHinge ?? .closed }

    var hasPhysicalHinge: Bool { realHinge != nil }

    /// Split screen only counts when the device is open. The closed outer display is compact too.
    var isMultitasking: Bool {
        if let simulatedMultitasking { return simulatedMultitasking }
        return isCompactWidth && hinge.status != .closed
    }

    /// The cat becomes destructive ONLY during an active session when the user commits an infraction
    /// (e.g. opens the phone, multitasks, or backgrounds the app).
    /// When there is no active session, the city is peaceful and safe from destruction.
    var state: GameState {
        guard isSessionActive else {
            return .incubation
        }

        if isBackgrounded { return .neglect }
        if isMultitasking { return .multitasking }
        switch hinge.status {
        case .closed: return .incubation
        case .fullyOpen: return .rampage
        case .partiallyOpen:
            if hinge.angleDegrees >= GameTuning.rampageAngle { return .rampage }
            if hinge.angleDegrees >= GameTuning.agitationAngle { return .agitation }
            return .warning
        }
    }

    /// 0...1, linear from 15° to 179°. Drives haptics and visuals (shake, red tint).
    var hapticIntensity: Double {
        guard isSessionActive else { return 0 }
        return HapticsController.intensity(forAngle: hinge.angleDegrees)
    }

    /// True when the closed, outer-display (building) experience should show.
    var showsClosedExperience: Bool { hinge.status == .closed && !isMultitasking }

    var buildInterval: TimeInterval {
        isDemoMode ? GameTuning.demoBuildInterval : GameTuning.realBuildInterval
    }

    /// 0...1 progress toward the cat's next construction job.
    var buildProgress: Double { builder.progress(buildInterval: buildInterval) }

    private var decaySecondsPerPoint: TimeInterval {
        isDemoMode ? GameTuning.demoDecaySecondsPerPoint : GameTuning.realDecaySecondsPerPoint
    }

    // MARK: Session Control

    /// Starts a session for the given duration. Snapshots initial state for potential rollback.
    func startFocusSession(duration: TimeInterval) {
        targetFocusDuration = duration
        sessionElapsed = 0
        focusSeconds = 0
        // Snapshot initial state
        initialMapSnapshot = map
        initialActorsSnapshot = actors
        initialCityHealth = cityHealth
        sessionStatus = .active
    }

    /// User chose to give up / stop before time ended. Reverts 100% back to initial state.
    func stopFocusSession() {
        guard sessionStatus == .active else { return }
        if let initialMapSnapshot, let initialActorsSnapshot {
            map = initialMapSnapshot
            actors = initialActorsSnapshot
            cityHealth = initialCityHealth
        }
        sessionStatus = .cancelled
        persistCurrentState()
    }

    /// Resets session status to .notStarted so user can start a new focus session.
    func dismissSessionSummary() {
        sessionStatus = .notStarted
        sessionElapsed = 0
    }

    // MARK: Inputs from the root view

    func hingeDidChange(_ reading: HingeReading?) {
        let previous = state
        realHinge = reading
        Self.log.info("Hinge: \(reading?.status.rawValue ?? "none", privacy: .public) at \(reading?.angleDegrees ?? -1, privacy: .public)° → \(self.state.rawValue, privacy: .public)")
        stateMayHaveChanged(from: previous)
    }

    func sizeClassDidChange(isCompact: Bool) {
        let previous = state
        isCompactWidth = isCompact
        stateMayHaveChanged(from: previous)
    }

    func scenePhaseDidChange(isBackground: Bool, isActive: Bool) {
        let previous = state
        if isBackground, !isBackgrounded {
            isBackgrounded = true
            backgroundedAt = .now
            persistCurrentState()
        } else if isActive, isBackgrounded {
            isBackgrounded = false
            applyNeglectDecay()
            persistCurrentState()
        }
        stateMayHaveChanged(from: previous)
    }

    /// Pass nil to go back to the physical hinge.
    func simulate(hinge reading: HingeReading?) {
        let previous = state
        simulatedHinge = reading
        stateMayHaveChanged(from: previous)
    }

    /// Pass nil to go back to real split-screen detection.
    func simulate(multitasking: Bool?) {
        let previous = state
        simulatedMultitasking = multitasking
        stateMayHaveChanged(from: previous)
    }

    func dismissNeglectReport() {
        neglectReport = nil
    }

    /// Starts a fresh city and clears persisted storage.
    func resetCity() {
        CityPersistence.clear()
        let world = CityWorld()
        map = world.map
        actors = world.actors
        builder = BuilderBrain()
        destroyer = DestroyerBrain()
        cityHealth = 100
        focusSeconds = 0
        sessionElapsed = 0
        sessionStatus = .notStarted
        initialMapSnapshot = nil
        initialActorsSnapshot = nil
        neglectReport = nil
    }

    // MARK: Game loop

    /// Run from the root view's `.task`. Ticks until the task is cancelled.
    func run() async {
        let dt = 1 / GameTuning.tickRate
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(dt))
            tick(dt: dt)
        }
    }

    func tick(dt: TimeInterval) {
        let current = state
        guard current.mode != .paused else { return }

        // Advance session timing if active
        if sessionStatus == .active {
            sessionElapsed += dt
            if sessionElapsed >= targetFocusDuration {
                // Time has ended! Evaluate whether patient reward or distraction penalty
                if cityHealth < initialCityHealth || current.isDestructive {
                    // Penalty: phone was used or city was damaged. New damaged state is saved permanently.
                    sessionStatus = .penaltyEnded
                    initialMapSnapshot = map
                    initialActorsSnapshot = actors
                    initialCityHealth = cityHealth
                    persistCurrentState()
                } else {
                    // Reward: user focused for the target duration. New built state is saved permanently.
                    sessionStatus = .completed
                    initialMapSnapshot = map
                    initialActorsSnapshot = actors
                    initialCityHealth = cityHealth
                    persistCurrentState()
                }
            }
        }

        var world = CityWorld(map: map, actors: actors)
        let context = BrainContext(state: current, dt: dt, buildInterval: buildInterval, intensity: hapticIntensity)
        let events: [WorldEvent]
        switch current.mode {
        case .building:
            // Cat only builds when there is an active focus session
            if sessionStatus == .active {
                focusSeconds += dt
                events = builder.tick(world: &world, context: context)
            } else {
                // Idle roaming when waiting for session
                world.wanderHero(within: 3)
                events = []
            }
        case .destroying:
            // Cat only destroys when there is an active focus session and phone is opened/misused
            if sessionStatus == .active {
                events = destroyer.tick(world: &world, context: context)
            } else {
                events = []
            }
        case .paused:
            events = []
        }
        if !current.freezesCitizens {
            world.tickCitizens(dt: dt, fleeingFrom: (current.isDestructive && isSessionActive) ? world.actors.hero.position : nil)
        }

        // Only assign when changed, so observers of `map` don't redraw on every cat step.
        if world.map != map { map = world.map }
        if world.actors != actors { actors = world.actors }
        apply(events)

        if isSessionActive && (current == .warning || current == .agitation) {
            haptics.update(intensity: hapticIntensity)
        }
    }

    // MARK: Private

    private func apply(_ events: [WorldEvent]) {
        for event in events {
            switch event {
            case .floorBuilt(let lot):
                cityHealth = min(100, cityHealth + GameTuning.healthPerFloor)
                lastChangedLot = lot
                floorsBuiltCount += 1
                persistCurrentState()
            case .floorDestroyed(let lot):
                cityHealth = max(0, cityHealth - GameTuning.healthPerDestroyedFloor)
                lastChangedLot = lot
                floorsDestroyedCount += 1
                persistCurrentState()
            case .towerCollapsed:
                haptics.slam()
            case .blockDeveloped:
                blocksDevelopedCount += 1
                persistCurrentState()
            case .catEaten(let position):
                catsEatenCount += 1
                lastEatenPosition = position
                haptics.slam()
            }
        }
    }

    private func stateMayHaveChanged(from previous: GameState) {
        let current = state
        guard current != previous else { return }
        var world = CityWorld(map: map, actors: actors)
        switch current.mode {
        case .building: builder.enter(current, world: &world)
        case .destroying:
            if isSessionActive {
                destroyer.enter(current, world: &world)
            } else {
                builder.enter(.incubation, world: &world)
            }
        case .paused: world.actors.hero.stop()
        }
        if world.actors != actors { actors = world.actors }

        if current.isKaiju && isSessionActive {
            focusSeconds = 0
            haptics.slam()
        }
    }

    /// Spec: one health point per 60 seconds of absence; buildings rust mathematically.
    private func applyNeglectDecay() {
        guard let backgroundedAt else { return }
        self.backgroundedAt = nil
        // The cat and neglect destroy the city ONLY during an active session
        guard isSessionActive else { return }
        let secondsAway = Date.now.timeIntervalSince(backgroundedAt)
        let healthLost = min(cityHealth, secondsAway / decaySecondsPerPoint)
        guard healthLost > 0 else { return }
        cityHealth -= healthLost
        map.applyRust(healthLost / 100)
        neglectReport = NeglectReport(secondsAway: secondsAway, healthLost: healthLost)
    }
}
