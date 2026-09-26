import SwiftUI

/// Bite in any of his forms. Size it with `.frame`; the kaiju form fills whatever it gets.
/// `rage` (0...1) makes the eyes glow red and adds shake. Feed it `engine.hapticIntensity`.
struct BiteView: View {
    var form: MonsterForm
    var rage: Double = 0

    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            sprite
                .overlay(alignment: .top) { eyeGlow }
                .scaleEffect(x: facing(time), y: 1)
                .offset(x: shake(time).width, y: shake(time).height + bob(time))
                .rotationEffect(.degrees(form == .erratic ? sin(time * 20) * 6 : 0))
        }
        .accessibilityElement()
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder
    private var sprite: some View {
        switch form {
        case .sleeping:
            PixelSprite(asset: .biteSleeping)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "zzz")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                        .symbolEffect(.pulse)
                }
        case .kaiju:
            PixelSprite(asset: .bite)
                .colorMultiply(Color(red: 1, green: 0.55, blue: 0.5))
                .shadow(color: .red, radius: 20)
        case .peaceful, .peeking, .erratic:
            PixelSprite(asset: .bite)
        }
    }

    /// Two red dots over the sprite's eyes, glowing with rage.
    @ViewBuilder
    private var eyeGlow: some View {
        if form != .peaceful, form != .sleeping {
            let glow = form == .kaiju ? 1 : max(rage, 0.4)
            GeometryReader { proxy in
                let dot = proxy.size.width * 0.14
                HStack(spacing: proxy.size.width * 0.18) {
                    Circle().fill(.red)
                    Circle().fill(.red)
                }
                .frame(width: dot * 2 + proxy.size.width * 0.18, height: dot)
                .shadow(color: .red, radius: dot * glow)
                .opacity(glow)
                .offset(x: proxy.size.width * 0.28, y: proxy.size.height * 0.07)
            }
        }
    }

    private func facing(_ time: TimeInterval) -> CGFloat {
        switch form {
        case .peaceful: sin(time * 0.5) > 0 ? 1 : -1
        case .erratic: sin(time * 3) > 0 ? 1 : -1
        default: 1
        }
    }

    private func bob(_ time: TimeInterval) -> CGFloat {
        switch form {
        case .peaceful: abs(sin(time * 4)) * -6
        case .kaiju: abs(sin(time * 2)) * -20
        default: 0
        }
    }

    private func shake(_ time: TimeInterval) -> CGSize {
        let amount: Double = switch form {
        case .peeking: rage * 3
        case .erratic: 4 + rage * 6
        case .kaiju: 8
        default: 0
        }
        return CGSize(width: sin(time * 60) * amount, height: cos(time * 47) * amount)
    }

    private var accessibilityText: String {
        switch form {
        case .peaceful: "Bite, building peacefully"
        case .peeking: "Bite, peeking with glowing eyes"
        case .erratic: "Bite, pacing erratically"
        case .kaiju: "Bite, transformed into a giant kaiju"
        case .sleeping: "Bite, asleep"
        }
    }
}
