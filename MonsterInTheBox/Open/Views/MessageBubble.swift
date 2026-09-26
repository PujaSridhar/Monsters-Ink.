import SwiftUI

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
