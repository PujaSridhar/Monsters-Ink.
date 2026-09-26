import Foundation

/// A cat on the grid. Moves one tile at a time along a path; the view animates between tiles.
struct CatActor: Identifiable, Equatable {
    let id: Int
    var look: CatLook
    private(set) var position: GridPoint
    var facing: Direction = .right
    var activity: CatActivity = .idle
    /// Seconds per tile. Lower = faster.
    var stepDuration: TimeInterval
    private(set) var path: [GridPoint] = []
    private var stepElapsed: TimeInterval = 0

    init(id: Int, look: CatLook, position: GridPoint, stepDuration: TimeInterval) {
        self.id = id
        self.look = look
        self.position = position
        self.stepDuration = stepDuration
    }

    var isMoving: Bool { !path.isEmpty }

    /// Starts (or re-routes) a walk. Re-routing mid-walk keeps the step timer, so a chasing
    /// cat that re-paths often still moves.
    mutating func walk(_ newPath: [GridPoint]) {
        if path.isEmpty { stepElapsed = 0 }
        path = newPath
    }

    mutating func stop() {
        path = []
        stepElapsed = 0
    }

    /// Instantly moves the cat (e.g. back onto a road after the kaiju wandered off-road).
    mutating func teleport(to point: GridPoint) {
        stop()
        position = point
    }

    /// Advances along the path. Returns true on the tick the cat reaches the end of its path.
    @discardableResult
    mutating func advance(dt: TimeInterval) -> Bool {
        guard let next = path.first else { return false }
        stepElapsed += dt
        guard stepElapsed >= stepDuration else { return false }
        stepElapsed = 0
        if let direction = position.direction(to: next) {
            facing = direction
        }
        position = next
        path.removeFirst()
        return path.isEmpty
    }
}

/// Every cat is the same white sprite; the look tints it so citizens are distinguishable.
enum CatLook: CaseIterable {
    case hero
    case ginger
    case gray
    case black
}

/// What the cat is doing when it isn't walking. Views map this to a sprite sheet.
enum CatActivity {
    case idle
    case building
    case stomping
    case sleeping
    case grooming
}
