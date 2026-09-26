import Foundation
import Observation

/// The single source of truth for the game. Views read from it; only the root view feeds it input.
///
/// Inputs (set by `RootView`): `hingeDidChange`, `sizeClassDidChange`, `scenePhaseDidChange`.
/// Outputs (read by any view): `state`, `buildings`, `cityHealth`, `hinge`, `hapticIntensity`,
/// `focusSeconds`, `buildProgress`, and the event counters for animations.
@Observable
final class KaijuEngine {
    // MARK: City

    private(set) var buildings: [Building]
    private(set) var cityHealth: Double = 100

    /// Seconds of uninterrupted focus in the current session. Reset by rampage.
    private(set) var focusSeconds: TimeInterval = 0
    /// 0...1 progress toward the next floor during incubation. Resets on every state change.
    private(set) var buildProgress: Double = 0

    // MARK: Event counters (use as `.onChange` / `.sensoryFeedback` / animation triggers)

    private(set) var floorsBuiltCount = 0
    private(set) var floorsDestroyedCount = 0
    private(set) var lastChangedBuildingID: Int?
    /// Set when the app returns from the background with decay applied. Clear with `dismissNeglectReport()`.
    private(set) var neglectReport: NeglectReport?

    // MARK: Inputs

    private(set) var realHinge: HingeReading?
    private(set) var isCompactWidth = false
    private(set) var isBackgrounded = false
    private var backgroundedAt: Date?

    // MARK: Debug / demo controls (driven by the State Visualizer)

    /// When non-nil, overrides the physical hinge. Lets anyone develop on a regular simulator.
    private(set) var simulatedHinge: HingeReading?
    /// When non-nil, overrides the split-screen detection.
    private(set) var simulatedMultitasking: Bool?
    var isDemoMode = true

    private let haptics = HapticsController()
    private var destructionBudget: Double = 0

    init() {
        buildings = Self.freshBuildings()
    }

    private static func freshBuildings() -> [Building] {
        (0..<GameTuning.lotCount).map { index in
            Building(
                id: index,
                style: BuildingStyle.allCases[index % BuildingStyle.allCases.count],
                floors: 1,
                maxFloors: Int.random(in: 5...9)
            )
        }
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

    /// 0...1, linear from 15° to 179°. Drives haptics and can drive visuals (red eyes, shake).
    var hapticIntensity: Double {
        HapticsController.intensity(forAngle: hinge.angleDegrees)
    }

    /// True when the device (or simulation) should show the outer, closed-display experience.
    var showsClosedExperience: Bool { hinge.status == .closed && !isMultitasking }

    var totalFloors: Int { buildings.reduce(0) { $0 + $1.floors } }

    private var buildInterval: TimeInterval {
        isDemoMode ? GameTuning.demoBuildInterval : GameTuning.realBuildInterval
    }

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
        if isBackground, !isBackgrounded {
            isBackgrounded = true
            backgroundedAt = .now
        } else if isActive, isBackgrounded {
            isBackgrounded = false
            applyNeglectDecay()
        }
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
        buildings = Self.freshBuildings()
        cityHealth = 100
        focusSeconds = 0
        buildProgress = 0
        destructionBudget = 0
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
        switch current {
        case .incubation:
            focusSeconds += dt
            buildProgress += dt / buildInterval
            if buildProgress >= 1 {
                buildProgress = 0
                buildFloor()
            }
        case .warning, .agitation, .rampage, .multitasking:
            applyDamage(current.destructionPerSecond * dt)
        case .neglect:
            break
        }

        if current == .warning || current == .agitation {
            haptics.update(intensity: hapticIntensity)
        }
    }

    // MARK: Private

    private func stateMayHaveChanged(from previous: GameState) {
        let current = state
        guard current != previous else { return }
        // Spec: every transition resets the build timer.
        buildProgress = 0
        destructionBudget = 0
        if current == .rampage || current == .multitasking {
            // Spec: rampage deletes session progress instantly.
            focusSeconds = 0
            haptics.slam()
        }
    }

    private func buildFloor() {
        let candidates = buildings.indices.filter { buildings[$0].canGrow }
        guard let index = candidates.randomElement() else { return }
        buildings[index].floors += 1
        buildings[index].rust = max(0, buildings[index].rust - 0.25)
        cityHealth = min(100, cityHealth + GameTuning.healthPerFloor)
        lastChangedBuildingID = buildings[index].id
        floorsBuiltCount += 1
    }

    private func applyDamage(_ amount: Double) {
        cityHealth = max(0, cityHealth - amount)
        destructionBudget += amount
        while destructionBudget >= GameTuning.damagePerFloor {
            destructionBudget -= GameTuning.damagePerFloor
            destroyFloor()
        }
    }

    private func destroyFloor() {
        let standing = buildings.indices.filter { !buildings[$0].isRubble }
        guard let index = standing.randomElement() else { return }
        buildings[index].floors -= 1
        lastChangedBuildingID = buildings[index].id
        floorsDestroyedCount += 1
        if buildings[index].isRubble {
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
        let rust = 1 - cityHealth / 100
        for index in buildings.indices {
            buildings[index].rust = max(buildings[index].rust, rust)
        }
        neglectReport = NeglectReport(secondsAway: secondsAway, healthLost: healthLost)
    }
}
