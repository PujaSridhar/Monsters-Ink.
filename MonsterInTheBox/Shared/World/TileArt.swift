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
    static let asphaltIntersection = 290
    static let bush = 310
    static let palm = 263
    static let cars = [275, 299, 323]
    static let water = 204

    /// Base tile for a ground cell, plus an optional decoration drawn on top.
    static func tiles(for ground: Ground, at point: GridPoint, isEmptyLot: Bool) -> (base: Int, decoration: Int?) {
        let noise = abs(point.x * 73 + point.y * 151) % 19

        switch ground {
        case .wild:
            // Natural open-world wilderness: ponds, lush groves, wildflower patches
            // Scenic natural ponds in the wilderness corners
            let inNorthwestPond = (point.x >= 2 && point.x <= 4 && point.y >= 2 && point.y <= 4)
            let inSoutheastPond = (point.x >= 14 && point.x <= 16 && point.y >= 14 && point.y <= 16)
            if inNorthwestPond || inSoutheastPond {
                return (water, nil)
            }

            // Outer perimeter forest border
            let isBorder = point.x == 0 || point.x == CityLayout.columns - 1 || point.y == 0 || point.y == CityLayout.rows - 1
            if isBorder {
                let tree = (noise % 3 == 0) ? palm : bush
                return (grass, tree)
            }

            // Varied open-world meadow
            let base: Int
            if noise < 5 {
                base = grassFlowers
            } else if noise < 10 {
                base = grassDots
            } else {
                base = grass
            }
            let decoration: Int? = (noise == 13) ? bush : (noise == 17 ? palm : nil)
            return (base, decoration)

        case .road:
            // Intersections get crosswalk lines
            let isIntersection = (point.x % CityLayout.period == 0) && (point.y % CityLayout.period == 0)
            return (isIntersection ? asphaltIntersection : asphalt, nil)

        case .yard:
            // Developed courtyards with decorative planter bushes in corners
            let isCorner = (point.x % CityLayout.period == 1 && point.y % CityLayout.period == 1)
            let decoration = isCorner ? bush : nil
            return (noise % 3 == 0 ? pavementDots : pavement, decoration)

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
