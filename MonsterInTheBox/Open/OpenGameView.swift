import SwiftUI

/// DEV B — The inner display whenever the phone is open (Acts 2, 3, 5: Warning, Agitation,
/// Rampage, Multitasking). ArrangementView splits the city map (primary) from the Monster Nest
/// (secondary), and the fold glows red.
/// See docs/DEV_B_OPEN.md for the task list.
struct OpenGameView: View {
    @Environment(KaijuEngine.self) private var engine

    var body: some View {
        ArrangementView {
            CityBoard()
        } secondary: {
            MonsterNest()
        }
        .arrangementViewStyle(.split)
        .background(skyColor.ignoresSafeArea())
        .overlay { HingeGapGlow(intensity: engine.hapticIntensity) }
        .animation(.smooth, value: engine.state)
    }

    private var skyColor: Color {
        switch engine.state {
        case .warning: Color(red: 0.25, green: 0.2, blue: 0.35)
        case .agitation: Color(red: 0.4, green: 0.15, blue: 0.2)
        case .rampage, .multitasking: Color(red: 0.35, green: 0.05, blue: 0.05)
        case .incubation, .neglect: .indigo
        }
    }
}
