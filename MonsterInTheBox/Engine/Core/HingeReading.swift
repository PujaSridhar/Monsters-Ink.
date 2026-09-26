import SwiftUI

/// A plain-value snapshot of the hinge, so the engine never depends on SwiftUI hinge types
/// and so the State Visualizer can simulate a hinge on any simulator.
struct HingeReading: Equatable {
    /// Exactly as the system reports it. While it's `.closed` the app is on the outer display,
    /// which always shows the builder city (never the eyes).
    var status: HingeStatus
    /// 0 = folded closed, 180 = fully flat.
    var angleDegrees: Double

    static let closed = HingeReading(status: .closed, angleDegrees: 0)

    init(status: HingeStatus, angleDegrees: Double) {
        self.status = status
        self.angleDegrees = angleDegrees
    }

    /// Returns nil on devices without a hinge (every non-Duo iPhone).
    init?(_ context: DeviceHingeContext) {
        guard let hinge = context.hinge else { return nil }
        self.init(status: HingeStatus(hinge.status), angleDegrees: hinge.angle.degrees)
    }

    /// Builds a reading from a raw angle, used by the simulated hinge slider.
    init(simulatedAngle angle: Double) {
        let status: HingeStatus = switch angle {
        case ..<GameTuning.crackAngle: .closed
        case GameTuning.rampageAngle...: .fullyOpen
        default: .partiallyOpen
        }
        self.init(status: status, angleDegrees: angle)
    }
}

enum HingeStatus: String {
    case closed
    case partiallyOpen
    case fullyOpen

    /// `DeviceHinge.Status` is a struct, not an enum, so it can't be switched exhaustively.
    init(_ status: DeviceHinge.Status) {
        if status == .closed {
            self = .closed
        } else if status == .fullyOpen {
            self = .fullyOpen
        } else {
            self = .partiallyOpen
        }
    }
}
