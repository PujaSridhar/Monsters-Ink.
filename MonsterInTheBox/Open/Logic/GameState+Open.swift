import CoreGraphics

/// Open-phone extras on `GameState`. Kept in Open/ so Dev B can change them freely.
extension GameState {
    /// Drives the message bubble over the kaiju. Warning has none: only the eyes show.
    var catMood: CatMood? {
        self == .agitation ? .annoyed : nil
    }

    /// Warning: the cat hides in the dark and only its eyes show.
    var showsOnlyEyes: Bool { self == .warning }

    /// The one hero cat becomes a 1.5× kaiju once the hinge passes 90°.
    var heroScale: CGFloat {
        switch self {
        case .agitation, .rampage, .multitasking: 1.5
        case .incubation, .warning, .neglect: 1
        }
    }
}
