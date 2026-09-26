import SwiftUI

/// The cat peeking out of the box (frame 1 of the CatBox sheet) with a text-message bubble
/// sitting over its eyes. `annoyance` (0...1, feed it `engine.hapticIntensity`) adds shake and red.
struct PeekingCatView: View {
    var mood: CatMood
    var annoyance: Double = 0

    /// Where the cat's eyes are inside the 32×32 frame, as a fraction of its height.
    private static let eyeAnchor = UnitPoint(x: 0.5, y: 0.45)

    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let line = currentLine(at: time)
            GeometryReader { proxy in
                SpriteSheet.catBox.frame(1)
                    .resizable()
                    .scaledToFit()
                    .colorMultiply(mood == .annoyed ? Color(red: 1, green: 0.6, blue: 0.6) : .white)
                    .overlay(alignment: .topTrailing) { angerMark(time: time) }
                    .offset(shake(time))
                    .overlay {
                        MessageBubble(text: line, mood: mood)
                            .fixedSize()
                            .id(line)
                            .transition(.scale(scale: 0.3, anchor: .bottom).combined(with: .opacity))
                            // Tail tip sits on the eye line; the bubble rises above it.
                            .frame(width: proxy.size.width, height: proxy.size.height * Self.eyeAnchor.y, alignment: .bottom)
                            .frame(maxHeight: .infinity, alignment: .top)
                    }
                    .animation(.bouncy, value: line)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(mood == .annoyed ? "Annoyed cat in a box" : "Cat peeking out of a box")
    }

    private func currentLine(at time: TimeInterval) -> String {
        let lines = mood.lines
        let index = Int(time / mood.lineDuration) % lines.count
        return lines[index]
    }

    @ViewBuilder
    private func angerMark(time: TimeInterval) -> some View {
        if mood == .annoyed {
            Image(systemName: "bolt.fill")
                .font(.largeTitle)
                .foregroundStyle(.red)
                .scaleEffect(1 + 0.25 * abs(sin(time * 8)))
                .padding(.top, 20)
        }
    }

    private func shake(_ time: TimeInterval) -> CGSize {
        let amount = mood == .annoyed ? 3 + annoyance * 8 : annoyance * 2
        return CGSize(width: sin(time * 55) * amount, height: cos(time * 43) * amount * 0.5)
    }
}

/// An iMessage-style bubble with a tail pointing down at the cat's eyes.
struct MessageBubble: View {
    var text: String
    var mood: CatMood

    var body: some View {
        VStack(spacing: 0) {
            Text(text)
                .font(mood == .annoyed ? .headline.weight(.black) : .headline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 220)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(color, in: .rect(cornerRadius: 18))
            BubbleTail()
                .fill(color)
                .frame(width: 18, height: 10)
        }
        .shadow(radius: 6)
    }

    private var color: Color {
        mood == .annoyed ? .red : .blue
    }
}

private nonisolated struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}
