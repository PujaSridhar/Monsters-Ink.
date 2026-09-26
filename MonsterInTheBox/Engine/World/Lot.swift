import Foundation

/// A building plot. `floors == 0` is an empty construction site (or rubble if it was destroyed).
struct Lot: Identifiable, Equatable {
    var position: GridPoint
    var style: BuildingStyle
    var floors = 0
    var maxFloors = CityLayout.maxFloors
    /// 0 = pristine, 1 = fully rusted. Set by background neglect decay.
    var rust: Double = 0
    /// True once a tower here has been knocked down to nothing.
    var isRubble = false

    var id: GridPoint { position }
    var isEmpty: Bool { floors == 0 }
    var canGrow: Bool { floors < maxFloors }
}

/// Which facade the tower uses. The tile art for each lives in `Shared/World/TileArt.swift`.
enum BuildingStyle: CaseIterable {
    case purple
    case pink
    case white
    case gray
}
