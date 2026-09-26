import Foundation
import Observation

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

    // MARK: Debug / demo controls (driven by the State Visualizer)

    private(set) var simulatedHinge: HingeReading?
    private(set) var simulatedMultitasking: Bool?
    var isDemoMode = true

    private let haptics = HapticsController()

    init() {
        let world = CityWorld()
        map = world.map
        actors = world.actors
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

    var state: GameState {
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
        HapticsController.intensity(forAngle: hinge.angleDegrees)
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

    // MARK: Inputs from the root view

    func hingeDidChange(_ reading: HingeReading?) {
        let previous = state
        realHinge = reading
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
        } else if isActive, isBackgrounded {
            isBackgrounded = false
            applyNeglectDecay()
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

    /// Starts a fresh city and focus session.
    func resetCity() {
        let world = CityWorld()
        map = world.map
        actors = world.actors
        builder = BuilderBrain()
        destroyer = DestroyerBrain()
        cityHealth = 100
        focusSeconds = 0
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

        var world = CityWorld(map: map, actors: actors)
        let context = BrainContext(state: current, dt: dt, buildInterval: buildInterval, intensity: hapticIntensity)
        let events: [WorldEvent]
        switch current.mode {
        case .building:
            focusSeconds += dt
            events = builder.tick(world: &world, context: context)
        case .destroying:
            events = destroyer.tick(world: &world, context: context)
        case .paused:
            events = []
        }
        if !current.freezesCitizens {
            world.tickCitizens(dt: dt, fleeingFrom: current.isDestructive ? world.actors.hero.position : nil)
        }

        // Only assign when changed, so observers of `map` don't redraw on every cat step.
        if world.map != map { map = world.map }
        if world.actors != actors { actors = world.actors }
        apply(events)

        if current == .warning || current == .agitation {
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
            case .floorDestroyed(let lot):
                cityHealth = max(0, cityHealth - GameTuning.healthPerDestroyedFloor)
                lastChangedLot = lot
                floorsDestroyedCount += 1
            case .towerCollapsed:
                haptics.slam()
            case .blockDeveloped:
                blocksDevelopedCount += 1
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
        case .destroying: destroyer.enter(current, world: &world)
        case .paused: world.actors.hero.stop()
        }
        if world.actors != actors { actors = world.actors }

        if current.isKaiju {
            // Spec: rampage deletes session progress instantly.
            focusSeconds = 0
            haptics.slam()
        }
    }

    /// Spec: one health point per 60 seconds of absence; buildings rust mathematically.
    private func applyNeglectDecay() {
        guard let backgroundedAt else { return }
        self.backgroundedAt = nil
        let secondsAway = Date.now.timeIntervalSince(backgroundedAt)
        let healthLost = min(cityHealth, secondsAway / decaySecondsPerPoint)
        guard healthLost > 0 else { return }
        cityHealth -= healthLost
        map.applyRust(healthLost / 100)
        neglectReport = NeglectReport(secondsAway: secondsAway, healthLost: healthLost)
    }
}
