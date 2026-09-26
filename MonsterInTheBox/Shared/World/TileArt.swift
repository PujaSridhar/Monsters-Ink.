import Foundation

/// Which Kenney Pico-8 City tile draws what. Index = row * 24 + column in tilemap_packed.png.
/// Check indices against `assests/Pico-8 City Kenney/Preview.png`.
enum TileArt {
    static let grass = 0
    static let grassDots = 24
    static let grassFlowers = 48
    static let pavement = 3
    static let pavementDots = 27
    static let asphalt = 291
    static let bush = 310
    static let palm = 263
    static let cars = [275, 299, 323]

    /// Base tile for a ground cell, plus an optional decoration drawn on top.
    static func tiles(for ground: Ground, at point: GridPoint, isEmptyLot: Bool) -> (base: Int, decoration: Int?) {
        let noise = (point.x * 73 + point.y * 151) % 11
        switch ground {
        case .wild:
            let base = noise < 2 ? grassFlowers : noise < 5 ? grassDots : grass
            let decoration = noise == 7 ? bush : noise == 9 ? palm : nil
            return (base, decoration)
        case .road:
            return (asphalt, nil)
        case .yard:
            return (pavement, nil)
        case .lot:
            return (isEmptyLot ? pavementDots : pavement, nil)
        }
    }
}

extension BuildingStyle {
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

    /// Cross-hatched tile for a destroyed tower.
    var rubbleTile: Int {
        switch self {
        case .pink: 190
        case .purple, .gray: 189
        case .white: 191
        }
    }
}
