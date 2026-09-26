import Foundation

/// How the cat in the box reacts while the hinge opens (Warning → Agitation).
enum CatMood: String {
    /// Cracked open: polite message bubbles asking you to close the phone.
    case pleading
    /// Around 90°: visibly annoyed, shaking, red, and snapping at you.
    case annoyed

    /// Rotated every few seconds in the bubble over the cat's eyes.
    var lines: [String] {
        switch self {
        case .pleading: [
            "Psst… close the phone?",
            "It's cozy in here. Keep the lid shut.",
            "Bite is building your city. Don't wake him.",
            "Nothing to see here. Fold me back up.",
        ]
        case .annoyed: [
            "I SAID close it.",
            "Don't make me come out there.",
            "Last warning, human.",
            "Fold. The. Phone.",
        ]
        }
    }

    /// Seconds each line stays up before the next one.
    var lineDuration: TimeInterval {
        switch self {
        case .pleading: 2.5
        case .annoyed: 1.2
        }
    }
}
