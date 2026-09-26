import Foundation

/// Every gameplay number in one place, so both devs can tune without touching engine logic.
enum GameTuning {
    /// Demo mode shrinks minutes to seconds so judges see things happen.
    /// The State Visualizer can toggle this at runtime via `KaijuEngine.isDemoMode`.
    static let realBuildInterval: TimeInterval = 5 * 60
    static let demoBuildInterval: TimeInterval = 3

    /// Spec: one health point per 60 seconds of absence. Demo: one per second.
    static let realDecaySecondsPerPoint: TimeInterval = 60
    static let demoDecaySecondsPerPoint: TimeInterval = 1

    static let warningDamagePerSecond: Double = 1
    static let agitationDamagePerSecond: Double = 4
    static let rampageDamagePerSecond: Double = 25

    /// Health restored each time Bite adds a floor.
    static let healthPerFloor: Double = 3
    /// Health points of damage that knock one floor off a tower.
    static let damagePerFloor: Double = 3

    /// Hinge angle thresholds, in degrees (0 = closed, 180 = flat).
    static let hapticStartAngle: Double = 15
    static let hapticMaxAngle: Double = 179
    static let agitationAngle: Double = 75
    static let rampageAngle: Double = 178

    static let lotCount = 8
    static let tickRate: Double = 10
}
