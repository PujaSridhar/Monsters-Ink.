import Foundation

/// What's on the ground at a cell. Rendering picks tiles for each in `TileArt`.
enum Ground {
    /// Undeveloped land (grass, trees). Future city.
    case wild
    /// A road connected to the developed city. Cats walk here.
    case road
    /// Open space inside a developed block, behind the towers.
    case yard
    /// A tower's base cell.
    case lot
}

/// The static part of the world: roads, blocks, and towers. Knows nothing about cats.
struct CityMap: Equatable {
    private(set) var developedBlocks: [BlockID] = []
    private(set) var lots: [GridPoint: Lot] = [:]
    private(set) var roads: Set<GridPoint> = []

    init() {
        developNextBlock()
    }

    // MARK: Queries

    func ground(at point: GridPoint) -> Ground {
        if roads.contains(point) { return .road }
        if lots[point] != nil { return .lot }
        if let block = CityLayout.block(containing: point), developedBlocks.contains(block) { return .yard }
        return .wild
    }

    func isRoad(_ point: GridPoint) -> Bool { roads.contains(point) }

    /// Top-to-bottom, so lower towers draw over higher ones.
    var sortedLots: [Lot] {
        lots.values.sorted { ($0.position.y, $0.position.x) < ($1.position.y, $1.position.x) }
    }

    var standingLots: [Lot] { lots.values.filter { !$0.isEmpty } }
    var totalFloors: Int { lots.values.reduce(0) { $0 + $1.floors } }
    var capacity: Int { lots.values.reduce(0) { $0 + $1.maxFloors } }

    var nextBlock: BlockID? {
        CityLayout.expansionOrder.first { !developedBlocks.contains($0) }
    }

    /// The city expands once every lot in it has a tower at least this tall.
    func isReadyToExpand(minimumFloors: Int) -> Bool {
        nextBlock != nil && lots.values.allSatisfy { $0.floors >= minimumFloors }
    }

    /// Best lot to work on next: shortest tower first, then nearest to `point`.
    func nextLotToBuild(near point: GridPoint) -> GridPoint? {
        lots.values
            .filter(\.canGrow)
            .min { ($0.floors, $0.position.manhattanDistance(to: point)) < ($1.floors, $1.position.manhattanDistance(to: point)) }?
            .position
    }

    func nearestStandingLot(to point: GridPoint) -> GridPoint? {
        standingLots.min { $0.position.manhattanDistance(to: point) < $1.position.manhattanDistance(to: point) }?.position
    }

    // MARK: Mutations

    @discardableResult
    mutating func developNextBlock() -> BlockID? {
        guard let block = nextBlock else { return nil }
        developedBlocks.append(block)
        roads.formUnion(block.surroundingRoads)
        for (index, position) in block.lots.enumerated() {
            let styleIndex = (index + developedBlocks.count) % BuildingStyle.allCases.count
            lots[position] = Lot(position: position, style: BuildingStyle.allCases[styleIndex])
        }
        return block
    }

    mutating func addFloor(at position: GridPoint) {
        guard var lot = lots[position], lot.canGrow else { return }
        lot.floors += 1
        lot.isRubble = false
        lot.rust = max(0, lot.rust - 0.25)
        lots[position] = lot
    }

    /// Returns true if this knocked the tower down completely.
    @discardableResult
    mutating func removeFloor(at position: GridPoint) -> Bool {
        guard var lot = lots[position], !lot.isEmpty else { return false }
        lot.floors -= 1
        lot.isRubble = lot.isEmpty
        lots[position] = lot
        return lot.isEmpty
    }

    mutating func applyRust(_ amount: Double) {
        for (position, lot) in lots {
            lots[position]?.rust = min(1, lot.rust + amount)
        }
    }
}
