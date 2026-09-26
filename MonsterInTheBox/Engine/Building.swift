import Foundation

/// One tower in the pixel city. Rendered by `BuildingView` from the Kenney city tiles.
struct Building: Identifiable, Equatable {
    let id: Int
    var style: BuildingStyle
    var floors: Int
    var maxFloors: Int
    /// 0 = pristine, 1 = fully rusted. Set by background neglect decay.
    var rust: Double = 0

    var isRubble: Bool { floors == 0 }
    var canGrow: Bool { floors < maxFloors }
}

/// Each style maps to a column of the Kenney Pico-8 City tilemap (24 × 15 tiles, 8 px each).
enum BuildingStyle: CaseIterable {
    case purple
    case pink
    case white
    case gray

    var roofTile: Int {
        switch self {
        case .purple: 169
        case .pink: 174
        case .white: 179
        case .gray: 184
        }
    }

    var middleTile: Int {
        switch self {
        case .purple: 217
        case .pink: 222
        case .white: 227
        case .gray: 232
        }
    }

    var baseTile: Int {
        switch self {
        case .purple: 241
        case .pink: 246
        case .white: 251
        case .gray: 256
        }
    }

    /// Cross-hatched tile used for a collapsed lot.
    var rubbleTile: Int {
        switch self {
        case .pink: 190
        case .purple, .gray: 189
        case .white: 191
        }
    }
}
