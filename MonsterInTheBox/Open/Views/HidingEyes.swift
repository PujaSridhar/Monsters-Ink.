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
            .scaleEffect(1 + 0.35 * intensity)
            // A slow sideways glance, so it feels alive and watchful
            .offset(x: sin(time * 0.7) * 6)
            .shadow(color: .red.opacity(pulse), radius: 20 + 26 * intensity)
            .shadow(color: Color(red: 1.0, green: 0.2, blue: 0.1).opacity(0.8 * pulse), radius: 8)
        }
        .accessibilityElement()
        .accessibilityLabel("Glowing red cat eyes watching from the dark")
    }
}

/// One almond-shaped glowing red eye with an inner amber glow, a vertical slit pupil, and specular shine.
private struct Eye: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            ZStack {
                // Sclera gradient with molten amber-to-crimson glow
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1.0, green: 0.75, blue: 0.1), // Bright amber center
                                Color(red: 1.0, green: 0.15, blue: 0.0), // Vivid crimson
                                Color(red: 0.6, green: 0.0, blue: 0.0),  // Deep red border
                                Color(red: 0.2, green: 0.0, blue: 0.0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: width * 0.55
                        )
                    )
                // Dark limbal ring
                Ellipse()
                    .stroke(Color.black.opacity(0.6), lineWidth: 2)

                // Vertical slit pupil
                Capsule()
                    .fill(.black)
                    .frame(width: width * 0.15, height: height * 0.86)

                // Specular highlight dot
                Circle()
                    .fill(.white.opacity(0.9))
                    .frame(width: width * 0.12)
                    .offset(x: -width * 0.16, y: -height * 0.18)
            }
        }
    }
}
