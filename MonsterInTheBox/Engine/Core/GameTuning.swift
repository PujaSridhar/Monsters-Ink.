import Foundation

/// Every gameplay number in one place, so both devs can tune without touching engine logic.
enum GameTuning {
    // MARK: Time

    /// Spec: towers grow every five minutes. Demo mode shrinks that to seconds for judges.
    static let realBuildInterval: TimeInterval = 5 * 60
    static let demoBuildInterval: TimeInterval = 2

    /// Spec: one health point per 60 seconds of absence. Demo: one per second.
    static let realDecaySecondsPerPoint: TimeInterval = 60
    static let demoDecaySecondsPerPoint: TimeInterval = 1

    static let tickRate: Double = 10

    // MARK: Building

    /// Seconds the cat spends hammering before a floor appears.
    static let buildDuration: TimeInterval = 0.8
    /// The next block unlocks once every tower in the city has this many floors.
    static let floorsToExpand = 2
    static let healthPerFloor: Double = 3

    // MARK: Destroying

    static let warningFloorsPerSecond: Double = 0.15
    static let agitationFloorsPerSecond: Double = 0.5
    static let rampageFloorsPerSecond: Double = 3
    static let healthPerDestroyedFloor: Double = 4

    // MARK: Movement (seconds per tile)

    static let heroStep: TimeInterval = 0.3
    static let erraticStep: TimeInterval = 0.12
    static let kaijuStep: TimeInterval = 0.35
    static let citizenStep: TimeInterval = 0.5
    static let fleeStep: TimeInterval = 0.12
    /// Chance per tick that an idle citizen stays put instead of wandering.
    static let citizenWanderChance: Double = 0.97

    // MARK: Hinge (degrees, 0 = closed, 180 = flat)

    static let hapticStartAngle: Double = 15
    static let hapticMaxAngle: Double = 179
    static let agitationAngle: Double = 75
    static let rampageAngle: Double = 178
}
