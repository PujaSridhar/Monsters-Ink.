import Foundation

/// A cell on the tile grid. (0, 0) is the top-left; y grows downward.
struct GridPoint: Hashable {
    var x: Int
    var y: Int

    func moved(_ direction: Direction) -> GridPoint {
        GridPoint(x: x + direction.dx, y: y + direction.dy)
    }

    /// The four orthogonal neighbors. Movement is 4-way, like classic 8-bit games.
    var neighbors: [GridPoint] {
        Direction.allCases.map(moved)
    }

    func manhattanDistance(to other: GridPoint) -> Int {
        abs(x - other.x) + abs(y - other.y)
    }

    /// The direction of a single step from `self` to an adjacent `other`.
    func direction(to other: GridPoint) -> Direction? {
        Direction.allCases.first { moved($0) == other }
    }
}

enum Direction: CaseIterable {
    case up
    case down
    case left
    case right

    var dx: Int {
        switch self {
        case .left: -1
        case .right: 1
        case .up, .down: 0
        }
    }

    var dy: Int {
        switch self {
        case .up: -1
        case .down: 1
        case .left, .right: 0
        }
    }
}
