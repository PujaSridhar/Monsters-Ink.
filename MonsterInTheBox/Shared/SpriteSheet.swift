import SwiftUI
import UIKit

/// Slices a sprite sheet asset into frames. Results are cached, so calling this from `body` is cheap.
struct SpriteSheet {
    var asset: GameAsset
    var frameSize: CGSize
    var columns: Int

    static let cityTiles = SpriteSheet(asset: .cityTiles, frameSize: CGSize(width: 8, height: 8), columns: 24)

    /// Cat strips are one column of 32×32 frames.
    static func cat(_ asset: GameAsset) -> SpriteSheet {
        SpriteSheet(asset: asset, frameSize: CGSize(width: 32, height: 32), columns: 1)
    }

    static let catBox = SpriteSheet(asset: .catBox, frameSize: CGSize(width: 32, height: 32), columns: 1)

    var frameCount: Int {
        guard let image = SpriteCache.shared.cgImage(for: asset) else { return 0 }
        let rows = image.height / Int(frameSize.height)
        return rows * columns
    }

    /// A single frame as a `CGImage`, for SpriteKit (`SKTexture(cgImage:)`) or custom drawing.
    func cgFrame(_ index: Int) -> CGImage? {
        SpriteCache.shared.frame(of: self, index: index)
    }

    /// A single frame as a pixel-perfect SwiftUI `Image`. Add `.resizable()` to scale it.
    func frame(_ index: Int) -> Image {
        guard let frame = cgFrame(index) else { return Image(systemName: "questionmark.square.dashed") }
        return Image(decorative: frame, scale: 1).interpolation(.none)
    }

    var frames: [Image] {
        (0..<frameCount).map(frame)
    }
}

private final class SpriteCache {
    static let shared = SpriteCache()

    private var sheets: [GameAsset: CGImage] = [:]
    private var frames: [String: CGImage] = [:]

    func cgImage(for asset: GameAsset) -> CGImage? {
        if let cached = sheets[asset] { return cached }
        let image = UIImage(named: asset.rawValue)?.cgImage
        sheets[asset] = image
        return image
    }

    func frame(of sheet: SpriteSheet, index: Int) -> CGImage? {
        let key = "\(sheet.asset.rawValue)#\(index)"
        if let cached = frames[key] { return cached }
        guard let image = cgImage(for: sheet.asset) else { return nil }
        let rect = CGRect(
            x: CGFloat(index % sheet.columns) * sheet.frameSize.width,
            y: CGFloat(index / sheet.columns) * sheet.frameSize.height,
            width: sheet.frameSize.width,
            height: sheet.frameSize.height
        )
        let frame = image.cropping(to: rect)
        frames[key] = frame
        return frame
    }
}
