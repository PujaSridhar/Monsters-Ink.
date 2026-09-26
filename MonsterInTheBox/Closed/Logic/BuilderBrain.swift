import Foundation

/// DEV A — Incubation logic. The hero cat wanders the roads, and every `buildInterval` it walks to
/// the shortest tower, hammers for a moment, and adds a floor. Once every tower has
/// `GameTuning.floorsToExpand` floors, the next block of the city opens up.
struct BuilderBrain: CatBrain {
    enum Phase: Equatable {
        case wandering
        case walkingTo(GridPoint)
        case building(GridPoint, elapsed: TimeInterval)
    }

    private(set) var phase: Phase = .wandering
    private var cooldown: TimeInterval = 0

    func progress(buildInterval: TimeInterval) -> Double {
        switch phase {
        case .wandering: min(1, cooldown / buildInterval)
        case .walkingTo, .building: 1
        }
    }

    /// The lot the cat is currently heading to or building on, if any.
    var targetLot: GridPoint? {
        switch phase {
        case .wandering: nil
        case .walkingTo(let lot), .building(let lot, _): lot
        }
    }

    mutating func enter(_ state: GameState, world: inout CityWorld) {
        // Spec: every transition resets the build timer.
        cooldown = 0
        phase = .wandering
        world.snapHeroToRoad()
        world.actors.hero.stop()
        world.actors.hero.activity = .idle
        world.actors.hero.stepDuration = GameTuning.heroStep
    }

    mutating func tick(world: inout CityWorld, context: BrainContext) -> [WorldEvent] {
        world.actors.hero.advance(dt: context.dt)
        var events: [WorldEvent] = []

        switch phase {
        case .wandering:
            cooldown += context.dt
            if cooldown >= context.buildInterval, startJob(world: &world) {
                cooldown = 0
            } else if !world.actors.hero.isMoving, Double.random(in: 0...1) < 0.05 {
                world.actors.hero.activity = .idle
                world.wanderHero(within: 6)
            }

        case .walkingTo(let lot):
            if !world.actors.hero.isMoving {
                world.actors.hero.facing = .up
                world.actors.hero.activity = .building
                phase = .building(lot, elapsed: 0)
            }

        case .building(let lot, let elapsed):
            guard elapsed + context.dt >= GameTuning.buildDuration else {
                phase = .building(lot, elapsed: elapsed + context.dt)
                break
            }
            world.map.addFloor(at: lot)
            events.append(.floorBuilt(lot))
            world.actors.hero.activity = .idle
            phase = .wandering
            if world.map.isReadyToExpand(minimumFloors: GameTuning.floorsToExpand),
               let block = world.map.developNextBlock() {
                world.addCitizen()
                events.append(.blockDeveloped(block))
            }
        }
        return events
    }

    /// Picks the next lot and starts walking there. Returns false if there's nothing to build.
    private mutating func startJob(world: inout CityWorld) -> Bool {
        let hero = world.actors.hero
        guard let lot = world.map.nextLotToBuild(near: hero.position),
              let path = world.path(from: hero.position, to: CityLayout.frontDoor(of: lot), rule: .roads)
        else { return false }
        world.actors.hero.walk(path)
        phase = .walkingTo(lot)
        return true
    }
}
