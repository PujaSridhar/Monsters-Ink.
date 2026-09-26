import SwiftUI

/// Draws every ground tile in one Canvas pass. Undeveloped land is grass and trees, so the
/// city visibly spreads across it as blocks unlock.
struct GroundLayer: View {
    var map: CityMap
    var metrics: WorldMetrics

    var body: some View {
        Canvas { context, _ in
            for point in CityLayout.allPoints {
                let ground = map.ground(at: point)
                let isEmptyLot = map.lots[point]?.isEmpty ?? false
                let tiles = TileArt.tiles(for: ground, at: point, isEmptyLot: isEmptyLot)
                let rect = metrics.rect(of: point)
                context.draw(SpriteSheet.cityTiles.frame(tiles.base), in: rect)
                if let decoration = tiles.decoration {
                    context.draw(SpriteSheet.cityTiles.frame(decoration), in: rect)
                }
            }
        }
        .frame(width: metrics.size.width, height: metrics.size.height)
        .accessibilityHidden(true)
    }
}
