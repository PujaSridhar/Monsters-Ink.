import CoreGraphics

/// Converts grid cells to points. Every layer in a `WorldStage` shares one of these.
/// Tiles can be non-square (`filling`) so the city covers the whole screen; sprites use the
/// square `tileSize` so cats are never stretched.
struct WorldMetrics: Equatable {
    var tileWidth: CGFloat
    var tileHeight: CGFloat

    init(tileWidth: CGFloat, tileHeight: CGFloat) {
        self.tileWidth = tileWidth
        self.tileHeight = tileHeight
    }

    init(tileSize: CGFloat) {
        self.init(tileWidth: tileSize, tileHeight: tileSize)
    }

    /// Square tiles: the largest whole-point size that fits the whole grid (letterboxed).
    static func fitting(_ size: CGSize) -> WorldMetrics {
        let tile = min(size.width / CGFloat(CityLayout.columns), size.height / CGFloat(CityLayout.rows))
        return WorldMetrics(tileSize: max(1, tile.rounded(.down)))
    }

    /// Tiles stretched so the grid covers `size` exactly, edge to edge.
    static func filling(_ size: CGSize) -> WorldMetrics {
        WorldMetrics(
            tileWidth: max(1, size.width / CGFloat(CityLayout.columns)),
            tileHeight: max(1, size.height / CGFloat(CityLayout.rows))
        )
    }

    /// Square size for sprites and overlays (cats, markers, eyes).
    var tileSize: CGFloat { min(tileWidth, tileHeight) }

    var size: CGSize {
        CGSize(width: CGFloat(CityLayout.columns) * tileWidth, height: CGFloat(CityLayout.rows) * tileHeight)
    }

    func rect(of point: GridPoint) -> CGRect {
        CGRect(x: CGFloat(point.x) * tileWidth, y: CGFloat(point.y) * tileHeight, width: tileWidth, height: tileHeight)
    }

    func center(of point: GridPoint) -> CGPoint {
        CGPoint(x: (CGFloat(point.x) + 0.5) * tileWidth, y: (CGFloat(point.y) + 0.5) * tileHeight)
    }
}
