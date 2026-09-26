import Foundation

/// The fixed street grid, Pokémon-town style:
///
///     R R R R R R R R R R R R R      R = road (every 6th row and column)
///     R . . . . . R . . . . . R      . = yard (towers grow up into it)
///     R . . . . . R . . . . . R      L = lot (a tower's base, facing the road below)
///     R . . . . . R . . . . . R
///     R . . . . . R . . . . . R
///     R L L L L L R L L L L L R
///     R R R R R R R R R R R R R
///     …three block rows in total
///
/// The city starts with one block developed and unlocks more in `expansionOrder`.
enum CityLayout {
    static let blockSize = 5
    static let period = blockSize + 1
    static let blockColumns = 2
    static let blockRows = 3
    static let columns = blockColumns * period + 1
    static let rows = blockRows * period + 1

    /// A tower is drawn as `floors + 1` tiles (base, middles, roof), so it fits in its block.
    static let maxFloors = blockSize - 1

    /// Grows from the bottom-left block outward and upward.
    static let expansionOrder: [BlockID] = [
        BlockID(column: 0, row: 2),
        BlockID(column: 1, row: 2),
        BlockID(column: 0, row: 1),
        BlockID(column: 1, row: 1),
        BlockID(column: 0, row: 0),
        BlockID(column: 1, row: 0),
    ]

    static func contains(_ point: GridPoint) -> Bool {
        (0..<columns).contains(point.x) && (0..<rows).contains(point.y)
    }

    static func isRoad(_ point: GridPoint) -> Bool {
        contains(point) && (point.x % period == 0 || point.y % period == 0)
    }

    static func block(containing point: GridPoint) -> BlockID? {
        guard contains(point), !isRoad(point) else { return nil }
        return BlockID(column: point.x / period, row: point.y / period)
    }

    /// The road cell directly below a lot, where a cat stands to work on it.
    static func frontDoor(of lot: GridPoint) -> GridPoint {
        lot.moved(.down)
    }

    static var allPoints: [GridPoint] {
        (0..<rows).flatMap { y in (0..<columns).map { x in GridPoint(x: x, y: y) } }
    }
}

struct BlockID: Hashable {
    var column: Int
    var row: Int

    var origin: GridPoint {
        GridPoint(x: column * CityLayout.period + 1, y: row * CityLayout.period + 1)
    }

    /// The bottom row of the block, where towers stand.
    var lots: [GridPoint] {
        let y = origin.y + CityLayout.blockSize - 1
        return (0..<CityLayout.blockSize).map { GridPoint(x: origin.x + $0, y: y) }
    }

    var cells: [GridPoint] {
        (0..<CityLayout.blockSize).flatMap { dy in
            (0..<CityLayout.blockSize).map { dx in GridPoint(x: origin.x + dx, y: origin.y + dy) }
        }
    }

    /// Road cells that ring this block (including corners).
    var surroundingRoads: [GridPoint] {
        let minX = origin.x - 1, maxX = origin.x + CityLayout.blockSize
        let minY = origin.y - 1, maxY = origin.y + CityLayout.blockSize
        var roads: [GridPoint] = []
        for x in minX...maxX {
            roads.append(GridPoint(x: x, y: minY))
            roads.append(GridPoint(x: x, y: maxY))
        }
        for y in (minY + 1)..<maxY {
            roads.append(GridPoint(x: minX, y: y))
            roads.append(GridPoint(x: maxX, y: y))
        }
        return roads
    }
}
