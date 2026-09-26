import Foundation

/// Everyone who moves around the map. Kept separate from `CityMap` so the ground and building
/// layers don't redraw every time a cat takes a step.
struct CityActors: Equatable {
    /// The main cat: builds while closed, becomes the kaiju when opened.
    var hero: CatActor
    /// Background cats roaming the roads. One more moves in each time the city expands.
    var citizens: [CatActor] = []
}

/// Map + actors, handed to a `CatBrain` each tick. Contains movement helpers both brains share.
struct CityWorld: Equatable {
    var map: CityMap
    var actors: CityActors

    init() {
        let map = CityMap()
        let start = map.roads.min { ($0.y, $0.x) > ($1.y, $1.x) } ?? GridPoint(x: 0, y: 0)
        self.map = map
        actors = CityActors(hero: CatActor(id: 0, look: .hero, position: start, stepDuration: GameTuning.heroStep))
        addCitizen()
    }

    init(map: CityMap, actors: CityActors) {
        self.map = map
        self.actors = actors
    }

    // MARK: Walking rules

    enum WalkRule {
        /// Normal cats stay on roads.
        case roads
        /// The kaiju is giant and ignores roads.
        case anywhere
    }

    func path(from start: GridPoint, to goal: GridPoint, rule: WalkRule) -> [GridPoint]? {
        switch rule {
        case .roads: Pathfinder.path(from: start, to: goal) { map.isRoad($0) }
        case .anywhere: Pathfinder.path(from: start, to: goal) { _ in true }
        }
    }

    func randomRoad(near point: GridPoint? = nil, within radius: Int = .max) -> GridPoint? {
        map.roads.filter { candidate in
            guard let point else { return true }
            return candidate.manhattanDistance(to: point) <= radius
        }.randomElement()
    }

    func nearestRoad(to point: GridPoint) -> GridPoint? {
        map.roads.min { $0.manhattanDistance(to: point) < $1.manhattanDistance(to: point) }
    }

    // MARK: Hero helpers

    /// Sends the hero to a random road cell, optionally nearby.
    mutating func wanderHero(within radius: Int = .max) {
        guard let goal = randomRoad(near: actors.hero.position, within: radius),
              let path = path(from: actors.hero.position, to: goal, rule: .roads) else { return }
        actors.hero.walk(path)
    }

    /// Puts the hero back on the road network (after the kaiju roamed off-road).
    mutating func snapHeroToRoad() {
        guard !map.isRoad(actors.hero.position), let road = nearestRoad(to: actors.hero.position) else { return }
        actors.hero.teleport(to: road)
    }

    // MARK: Citizens

    mutating func addCitizen() {
        guard let spot = randomRoad() else { return }
        let looks = CatLook.allCases.filter { $0 != .hero }
        let id = (actors.citizens.map(\.id).max() ?? 0) + 1
        actors.citizens.append(
            CatActor(id: id, look: looks[id % looks.count], position: spot, stepDuration: GameTuning.citizenStep)
        )
    }

    /// Citizens wander the roads. When `isFleeing`, they sprint.
    mutating func tickCitizens(dt: TimeInterval, isFleeing: Bool) {
        for index in actors.citizens.indices {
            actors.citizens[index].stepDuration = isFleeing ? GameTuning.fleeStep : GameTuning.citizenStep
            actors.citizens[index].advance(dt: dt)
            guard !actors.citizens[index].isMoving else { continue }
            if !isFleeing, Double.random(in: 0...1) > GameTuning.citizenWanderChance {
                actors.citizens[index].activity = .grooming
                continue
            }
            let start = actors.citizens[index].position
            if let goal = randomRoad(), let path = path(from: start, to: goal, rule: .roads) {
                actors.citizens[index].walk(path)
            } else if let road = nearestRoad(to: start) {
                actors.citizens[index].teleport(to: road)
            }
        }
    }
}
