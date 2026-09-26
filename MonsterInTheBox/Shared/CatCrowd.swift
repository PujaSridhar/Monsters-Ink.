import SwiftUI

/// Pixel cats wandering the street. When `isFleeing`, they sprint off-screen in a panic.
struct CatCrowd: View {
    var isFleeing: Bool
    var catSize: CGFloat = 40

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                ZStack(alignment: .bottomLeading) {
                    ForEach(Array(GameAsset.cats.enumerated()), id: \.offset) { index, asset in
                        let speed = isFleeing ? 220.0 : 25.0 + Double(index) * 6
                        let span = proxy.size.width + catSize * 2
                        let x = (time * speed + Double(index) * 97).truncatingRemainder(dividingBy: span) - catSize
                        AnimatedSprite(sheet: .cat(asset), framesPerSecond: isFleeing ? 16 : 6)
                            .frame(width: catSize, height: catSize)
                            .offset(x: x, y: isFleeing ? -abs(sin(time * 12 + Double(index))) * 12 : 0)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
        .frame(height: catSize + 12)
        .accessibilityHidden(true)
    }
}
