import SwiftUI

/// DEV B — A pair of big glowing red cat eyes staring out of the dark, like an animal in hiding.
/// Slit pupils, a slow pulse, and a blink every few seconds. `intensity` (0...1, the hinge
/// curve) makes them bigger and brighter the wider the phone opens.
struct HidingEyes: View {
    /// Width of the pair of eyes, in points.
    var width: CGFloat
    var intensity: Double

    private static let blinkPeriod: TimeInterval = 3.4
    private static let blinkDuration: TimeInterval = 0.18

    var body: some View {
        TimelineView(.animation) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let phase = time.truncatingRemainder(dividingBy: Self.blinkPeriod)
            let isBlinking = phase < Self.blinkDuration
            let pulse = 0.85 + 0.15 * sin(time * 3)
            let eyeWidth = width * 0.38
            HStack(spacing: width - eyeWidth * 2) {
                Eye()
                    .frame(width: eyeWidth, height: eyeWidth / 1.6)
                Eye()
                    .frame(width: eyeWidth, height: eyeWidth / 1.6)
            }
            .scaleEffect(x: 1, y: isBlinking ? 0.08 : 1)
            .scaleEffect(1 + 0.4 * intensity)
            // A slow sideways glance, so it feels alive.
            .offset(x: sin(time * 0.7) * 6)
            .shadow(color: .red.opacity(pulse), radius: 18 + 22 * intensity)
            .shadow(color: .red.opacity(0.6 * pulse), radius: 6)
        }
        .accessibilityElement()
        .accessibilityLabel("Glowing red cat eyes watching from the dark")
    }
}

/// One almond-shaped red eye with a vertical slit pupil.
private struct Eye: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack {
                Ellipse()
                    .fill(RadialGradient(colors: [.orange, .red, Color(red: 0.5, green: 0, blue: 0)], center: .center, startRadius: 0, endRadius: width * 0.55))
                Capsule()
                    .fill(.black)
                    .frame(width: width * 0.16, height: proxy.size.height * 0.85)
                Circle()
                    .fill(.white.opacity(0.8))
                    .frame(width: width * 0.12)
                    .offset(x: -width * 0.18, y: -proxy.size.height * 0.18)
            }
        }
    }
}
