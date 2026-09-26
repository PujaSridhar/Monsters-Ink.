import Foundation

/// DEV B — Destruction logic for every open-phone state.
/// - Warning: the cat freezes and stares; tremors knock floors off random towers slowly.
/// - Agitation: the cat paces erratically near where it stands; tremors speed up.
/// - Rampage / Multitasking: the cat is a giant kaiju that ignores roads, marches to the
///   nearest tower, and stomps it floor by floor.
struct DestroyerBrain: CatBrain {
    private var destroyBudget: Double = 0
    private(set) var target: GridPoint?

    mutating func enter(_ state: GameState, world: inout CityWorld) {
        destroyBudget = 0
        target = nil
        world.actors.hero.stop()
        world.actors.hero.activity = .idle
        switch state {
        case .warning:
            world.snapHeroToRoad()
            world.actors.hero.facing = .down
        case .agitation:
            world.snapHeroToRoad()
            world.actors.hero.stepDuration = GameTuning.erraticStep
        case .rampage, .multitasking:
            world.actors.hero.stepDuration = GameTuning.kaijuStep
        case .incubation, .neglect:
            break
        }
    }

    mutating func tick(world: inout CityWorld, context: BrainContext) -> [WorldEvent] {
        world.actors.hero.advance(dt: context.dt)
        destroyBudget += context.state.floorsDestroyedPerSecond * context.dt

        switch context.state {
        case .warning:
            return tremors(world: &world)
        case .agitation:
            if !world.actors.hero.isMoving {
                world.wanderHero(within: 3)
            }
            return tremors(world: &world)
        case .rampage, .multitasking:
            return stomp(world: &world)
        case .incubation, .neglect:
            return []
        }
    }

    /// Knocks floors off random towers as the budget allows.
    private mutating func tremors(world: inout CityWorld) -> [WorldEvent] {
        var events: [WorldEvent] = []
        while destroyBudget >= 1 {
            destroyBudget -= 1
            guard let lot = world.map.standingLots.randomElement()?.position else { break }
            events += knockFloor(at: lot, world: &world)
        }
        return events
    }

    /// Kaiju: walk to the nearest tower, then smash it.
    private mutating func stomp(world: inout CityWorld) -> [WorldEvent] {
        if target == nil || world.map.lots[target!]?.isEmpty != false {
            target = world.map.nearestStandingLot(to: world.actors.hero.position)
            if let target, let path = world.path(from: world.actors.hero.position, to: CityLayout.frontDoor(of: target), rule: .anywhere) {
                world.actors.hero.walk(path)
                world.actors.hero.activity = .idle
            }
        }
        guard let target else {
            // Nothing left standing: roam the ruins.
            if !world.actors.hero.isMoving { world.wanderHero() }
            return []
        }
        guard !world.actors.hero.isMoving else { return [] }

        world.actors.hero.facing = .up
        world.actors.hero.activity = .stomping
        var events: [WorldEvent] = []
        while destroyBudget >= 1 {
            destroyBudget -= 1
            events += knockFloor(at: target, world: &world)
        }
        return events
    }

    private func knockFloor(at lot: GridPoint, world: inout CityWorld) -> [WorldEvent] {
        let collapsed = world.map.removeFloor(at: lot)
        return collapsed ? [.floorDestroyed(lot), .towerCollapsed(lot)] : [.floorDestroyed(lot)]
    }
}
