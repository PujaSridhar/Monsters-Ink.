import SwiftUI

/// DEV B — The inner display whenever the phone is open (Acts 2, 3, 5: Warning, Agitation,
/// Rampage, Multitasking). The city fills the entire display, spanning both sides of the fold.
/// At warning, everything goes dark except the hiding cat's eyes, so the banner is hidden too.
/// See docs/DEV_B_OPEN.md for the task list.
struct OpenGameView: View {
    @Environment(KaijuEngine.self) private var engine

    var body: some View {
        CityBoard()
            .overlay { moodTint }
            .overlay(alignment: .top) {
                if !engine.state.showsOnlyEyes {
                    StatusBanner(text: engine.state.subtitle)
                        .transition(.opacity)
                }
            }
            .animation(.smooth, value: engine.state)
    }

    /// Reddens the town once smashing starts. (Warning's darkness lives in the actors layer,
    /// under the eyes.)
    private var moodTint: some View {
        let opacity: Double = switch engine.state {
        case .agitation: 0.15
        case .rampage, .multitasking: 0.25
        case .incubation, .warning, .neglect: 0
        }
        return Color.red.opacity(opacity)
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}
