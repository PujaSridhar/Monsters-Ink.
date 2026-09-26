import SwiftUI

/// DEV B — Places the hiding cat's eyes on the inner display while the phone is opening.
///
/// Motion Specs:
/// - As the user begins slowly opening the phone, the red eyes pop in from the far right end
///   of the screen (the power button side of the device, as shown in the user's screenshot).
/// - It NEVER appears from the bottom.
/// - The eyes have vertical slit pupils and almond contours.
/// - Around 90° hinge angle, the eyes smoothly transition and align exactly at the
///   center of the screen.
/// - From 90° up until fully open (178°), the eyes stay firmly locked at the center of the display,
///   pulsing and glowing with increasing menace.
/// - When the phone opens fully (178°–180°), the eyes vanish and the 2× kaiju emerges to destroy the city.
struct HidingEyesStage: View {
    /// Hinge angle in degrees (0 = closed, 180 = flat).
    var angle: Double
    var intensity: Double
    var eyesWidth: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let pos = position(in: size)

            ZStack {
                // Eerie red aura radiating from behind the eyes into the dark void
                RadialGradient(
                    colors: [
                        Color.red.opacity(0.35 * max(0.4, intensity)),
                        Color.red.opacity(0.12 * max(0.4, intensity)),
                        Color.clear
                    ],
                    center: .init(x: pos.x / max(1, size.width), y: pos.y / max(1, size.height)),
                    startRadius: 20,
                    endRadius: eyesWidth * 1.8
                )
                .ignoresSafeArea()

                HidingEyes(width: eyesWidth, intensity: intensity)
                    .scaleEffect(currentScale)
                    .position(pos)
                    .animation(.interpolatingSpring(stiffness: 100, damping: 16), value: angle)
            }
        }
    }

    /// Progress from the right edge (0.0) to center (1.0).
    /// Reaches full 1.0 (exact center of the screen) right at 90°.
    private var transitionProgress: CGFloat {
        let minAngle: Double = 5
        let centerAngle: Double = 90
        guard angle > minAngle else { return 0 }
        if angle >= centerAngle { return 1.0 }
        let t = (angle - minAngle) / (centerAngle - minAngle)
        // Smooth cubic ease (smoothstep)
        return CGFloat(t * t * (3.0 - 2.0 * t))
    }

    /// Looming scale boost as the eyes move to the center and the hinge opens wider.
    private var currentScale: CGFloat {
        let base: CGFloat = 0.9 + 0.25 * transitionProgress
        return base * CGFloat(1.0 + 0.18 * intensity)
    }

    private func position(in size: CGSize) -> CGPoint {
        // ALWAYS appear from the right end of the screen (power button side), NEVER from the bottom!
        let progress = transitionProgress
        let startX = size.width - (eyesWidth * 0.45)
        let targetCenterX = size.width / 2
        let currentX = startX + (targetCenterX - startX) * progress
        let currentY = size.height / 2
        return CGPoint(x: currentX, y: currentY)
    }
}
