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
    /// Helper cats in a new city (one more joins per developed block). The kaiju eats them.
    static let startingCitizens = 3

    // MARK: Destroying

    /// Warning is only a stare-down (red eyes); destruction starts at 90°.
    static let warningFloorsPerSecond: Double = 0
    static let agitationFloorsPerSecond: Double = 0.5
    static let rampageFloorsPerSecond: Double = 3
    static let healthPerDestroyedFloor: Double = 4

    // MARK: Movement (seconds per tile)

    static let heroStep: TimeInterval = 0.3
    static let erraticStep: TimeInterval = 0.12
    /// The kaiju cuts through blocks while citizens are stuck on roads, so it can catch them
    /// even though it's slightly slower.
    static let kaijuStep: TimeInterval = 0.24
    static let citizenStep: TimeInterval = 0.5
    static let fleeStep: TimeInterval = 0.28

    // MARK: Eating (open phone)

    /// The kaiju hunts any citizen within this many tiles; otherwise it smashes towers.
    static let huntRadius = 7
    /// A citizen this close (in tiles) gets eaten.
    static let eatRadius = 1
    /// Chance per tick that an idle citizen stays put instead of wandering.
    static let citizenWanderChance: Double = 0.97

    // MARK: Hinge (degrees, 0 = closed, 180 = flat)

    /// The debug slider's smallest open angle. Real hardware uses the system-reported status.
    static let crackAngle: Double = 1
    static let hapticStartAngle: Double = 15
    static let hapticMaxAngle: Double = 179
    /// Below this, a partially open phone shows only the hiding cat's eyes. Set equal to
    /// `rampageAngle`, so every partially open angle is the eyes and only flat (180°) shows the
    /// city and the kaiju. Lower it to bring back an in-between agitation state.
    static let agitationAngle: Double = 178
    static let rampageAngle: Double = 178
}
