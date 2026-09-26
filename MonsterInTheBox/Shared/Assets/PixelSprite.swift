import SwiftUI

/// A whole-image asset drawn crisply at any size (no blur on pixel art).
struct PixelSprite: View {
    var asset: GameAsset

    var body: some View {
        Image(asset.rawValue)
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .accessibilityHidden(true)
    }
}

/// One 8×8 tile from the Kenney city tilemap, drawn at `width` × `height` points.
struct CityTile: View {
    var index: Int
    var width: CGFloat
    var height: CGFloat

    init(index: Int, width: CGFloat, height: CGFloat) {
        self.index = index
        self.width = width
        self.height = height
    }

    init(index: Int, size: CGFloat) {
        self.init(index: index, width: size, height: size)
    }

    var body: some View {
        SpriteSheet.cityTiles.frame(index)
            .resizable()
            .frame(width: width, height: height)
    }
}

/// Loops through a sprite sheet's frames.
struct AnimatedSprite: View {
    var sheet: SpriteSheet
    var framesPerSecond: Double = 8

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / framesPerSecond)) { context in
            let count = max(sheet.frameCount, 1)
            let index = Int(context.date.timeIntervalSinceReferenceDate * framesPerSecond) % count
            sheet.frame(index)
                .resizable()
                .scaledToFit()
        }
        .accessibilityHidden(true)
    }
}
