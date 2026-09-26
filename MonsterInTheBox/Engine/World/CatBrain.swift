import Foundation

/// The per-mode game logic. The engine calls exactly one brain per tick, based on the state:
/// - `BuilderBrain` (Closed/Logic, Dev A) during incubation.
/// - `DestroyerBrain` (Open/Logic, Dev B) during warning, agitation, rampage, and multitasking.
///
/// Brains mutate the world and report what happened as `WorldEvent`s. The engine turns events
/// into health, counters, and haptics, so brains never touch those directly.
protocol CatBrain {
    /// Called when the game enters a state this brain handles.
    mutating func enter(_ state: GameState, world: inout CityWorld)
    mutating func tick(world: inout CityWorld, context: BrainContext) -> [WorldEvent]
}

struct BrainContext {
    var state: GameState
    var dt: TimeInterval
    /// Seconds between floors (5 minutes, or a few seconds in demo mode).
    var buildInterval: TimeInterval
    /// 0...1 hinge intensity, same curve as the haptics.
    var intensity: Double
}

enum WorldEvent: Equatable {
    case floorBuilt(GridPoint)
    case floorDestroyed(GridPoint)
    case towerCollapsed(GridPoint)
    case blockDeveloped(BlockID)
}
