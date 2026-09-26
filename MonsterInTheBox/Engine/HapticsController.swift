import UIKit

/// Wraps UIImpactFeedbackGenerator. Haptics don't play in the simulator; test on device.
final class HapticsController {
    private let pulseGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let slamGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private var lastPulse = Date.distantPast

    /// Spec: haptics start at 15°, scale linearly, and max out at 179°.
    static func intensity(forAngle angle: Double) -> Double {
        guard angle >= GameTuning.hapticStartAngle else { return 0 }
        let range = GameTuning.hapticMaxAngle - GameTuning.hapticStartAngle
        return min(1, (angle - GameTuning.hapticStartAngle) / range)
    }

    /// Call every tick. Pulses faster and harder as the intensity rises.
    func update(intensity: Double, now: Date = .now) {
        guard intensity > 0 else { return }
        let interval = 0.6 - 0.5 * intensity
        guard now.timeIntervalSince(lastPulse) >= interval else { return }
        lastPulse = now
        pulseGenerator.impactOccurred(intensity: 0.3 + 0.7 * intensity)
    }

    /// A single big thump, used when a tower collapses.
    func slam() {
        slamGenerator.impactOccurred(intensity: 1)
    }
}
