import Foundation

/// DEV B — Logic for every open-phone state.
/// - Warning: the cat hides. Everything freezes; the view shows only its glowing eyes.
///   Nothing is destroyed yet.
/// - Agitation (150°+), Rampage (flat), Multitasking: the one hero cat is a kaiju (drawn 2×).
///   It ignores roads, hunts the citizen cats that helped build the city and eats them, and
///   when none are nearby it smashes the nearest tower floor by floor.
struct DestroyerBrain: CatBrain {
    private var destroyBudget: Double = 0
    /// The tower being smashed, if any.
    private(set) var target: GridPoint?
    /// The citizen being hunted, if any.
    private(set) var preyID: Int?

    mutating func enter(_ state: GameState, world: inout CityWorld) {
        destroyBudget = 0
        target = nil
        preyID = nil
        world.actors.hero.stop()
        world.actors.hero.activity = .idle
        switch state {
        case .warning:
            world.snapHeroToRoad()
            world.actors.hero.facing = .down
            for index in world.actors.citizens.indices {
                world.actors.citizens[index].stop()
                world.actors.citizens[index].activity = .idle
            }
        case .agitation, .rampage, .multitasking:
            world.actors.hero.stepDuration = GameTuning.kaijuStep
        case .incubation, .neglect:
            break
        }
    }

    mutating func tick(world: inout CityWorld, context: BrainContext) -> [WorldEvent] {
        world.actors.hero.advance(dt: context.dt)
        destroyBudget += context.state.floorsDestroyedPerSecond * context.dt

        switch context.state {
        case .agitation, .rampage, .multitasking:
            let meals = eatNearbyCats(world: &world)
            return meals + (hunt(world: &world) ? [] : smashTowers(world: &world))
        case .warning, .incubation, .neglect:
            return []
        }
    }

    // MARK: Eating

    private mutating func eatNearbyCats(world: inout CityWorld) -> [WorldEvent] {
        let hero = world.actors.hero.position
        let meals = world.actors.citizens.filter { $0.position.manhattanDistance(to: hero) <= GameTuning.eatRadius }
        for cat in meals {
            world.removeCitizen(id: cat.id)
            if cat.id == preyID { preyID = nil }
        }
        if !meals.isEmpty {
            world.actors.hero.activity = .stomping
        }
        return meals.map { .catEaten($0.position) }
    }

    /// Chases the nearest citizen within `huntRadius`. Returns false if there's nobody to hunt.
    private mutating func hunt(world: inout CityWorld) -> Bool {
        let hero = world.actors.hero
        guard let prey = world.actors.citizens
            .filter({ $0.position.manhattanDistance(to: hero.position) <= GameTuning.huntRadius })
            .min(by: { $0.position.manhattanDistance(to: hero.position) < $1.position.manhattanDistance(to: hero.position) })
        else {
            preyID = nil
            return false
        }
        preyID = prey.id
        target = nil
        // Re-route only when the prey has moved away from where we're heading.
        let isOnCourse = hero.path.last.map { $0.manhattanDistance(to: prey.position) <= 1 } ?? false
        if !isOnCourse, let path = world.path(from: hero.position, to: prey.position, rule: .anywhere) {
            world.actors.hero.walk(path)
            world.actors.hero.activity = .idle
        }
        return true
    }

    // MARK: Smashing

    /// Walks to the nearest standing tower's front door, then knocks floors off it.
    private mutating func smashTowers(world: inout CityWorld) -> [WorldEvent] {
        if let current = target, world.map.lots[current]?.isEmpty != false {
            target = nil
        }
        if target == nil {
            target = world.map.nearestStandingLot(to: world.actors.hero.position)
        }
        guard let target else {
            // Nothing left standing: roam the ruins.
            if !world.actors.hero.isMoving { world.wanderHero() }
            return []
        }

        let door = CityLayout.frontDoor(of: target)
        let hero = world.actors.hero
        guard hero.position == door else {
            if hero.path.last != door, let path = world.path(from: hero.position, to: door, rule: .anywhere) {
                world.actors.hero.walk(path)
                world.actors.hero.activity = .idle
            }
            return []
        }

        world.actors.hero.facing = .up
        world.actors.hero.activity = .stomping
        var events: [WorldEvent] = []
        while destroyBudget >= 1 {
            destroyBudget -= 1
            let collapsed = world.map.removeFloor(at: target)
            events.append(.floorDestroyed(target))
            if collapsed { events.append(.towerCollapsed(target)) }
        }
        return events
    }
}
