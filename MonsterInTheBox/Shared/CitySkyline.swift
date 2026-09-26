import SwiftUI

/// The whole city: towers standing on a street, with trees and cars from the Kenney tiles.
/// Pass a subset of buildings to draw half the city on each side of the fold.
struct CitySkyline: View {
    var buildings: [Building]
    var tileSize: CGFloat = 28

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: tileSize * 0.25) {
                ForEach(buildings) { building in
                    BuildingView(building: building, tileSize: tileSize)
                }
            }
            .animation(.bouncy, value: buildings)
            street
        }
        .frame(maxWidth: .infinity)
    }

    private var street: some View {
        HStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { column in
                CityTile(index: Self.streetTiles[column % Self.streetTiles.count], size: tileSize)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
    }

    /// Gray pavement tile. Swap in road tiles from the tilemap if you like.
    static let streetTiles = [3]
    /// Decorative props (verify indices against Preview.png before relying on them).
    static let carTiles = [275, 299]
    static let treeTiles = [263, 310]
}
