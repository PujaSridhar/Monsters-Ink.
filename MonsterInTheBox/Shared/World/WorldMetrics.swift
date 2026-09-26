import CoreGraphics

/// Converts grid cells to points. Every layer in a `WorldStage` shares one of these.
struct WorldMetrics: Equatable {
    var tileSize: CGFloat

    /// The largest whole-point tile size that fits the whole grid in `size`.
    static func fitting(_ size: CGSize) -> WorldMetrics {
        let tile = min(size.width / CGFloat(CityLayout.columns), size.height / CGFloat(CityLayout.rows))
        return WorldMetrics(tileSize: max(1, tile.rounded(.down)))
    }

    var size: CGSize {
        CGSize(width: CGFloat(CityLayout.columns) * tileSize, height: CGFloat(CityLayout.rows) * tileSize)
    }

    func rect(of point: GridPoint) -> CGRect {
        CGRect(x: CGFloat(point.x) * tileSize, y: CGFloat(point.y) * tileSize, width: tileSize, height: tileSize)
    }

    func center(of point: GridPoint) -> CGPoint {
        CGPoint(x: (CGFloat(point.x) + 0.5) * tileSize, y: (CGFloat(point.y) + 0.5) * tileSize)
    }
}
