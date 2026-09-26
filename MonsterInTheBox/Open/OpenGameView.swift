import SwiftUI

/// DEV B — The inner display whenever the phone is open (Acts 2, 3, 5: Warning, Agitation,
/// Rampage, Multitasking). Working baseline: ArrangementView splits CityBoard / MonsterNest,
/// the fold glows red, and the kaiju stomps across both halves during a rampage.
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
        .overlay { rampageOverlay }
        .animation(.smooth, value: engine.state)
    }

    private var skyColor: Color {
        switch engine.state {
        case .warning: Color(red: 0.25, green: 0.2, blue: 0.35)
        case .agitation: Color(red: 0.4, green: 0.15, blue: 0.2)
        case .rampage, .multitasking: Color(red: 0.35, green: 0.05, blue: 0.05)
        default: .indigo
        }
    }

    /// The giant kaiju stomping across both screens.
    @ViewBuilder
    private var rampageOverlay: some View {
        if engine.state.monsterForm == .kaiju {
            GeometryReader { proxy in
                TimelineView(.animation) { context in
                    let time = context.date.timeIntervalSinceReferenceDate
                    let travel = proxy.size.width * 0.6
                    BiteView(form: .kaiju)
                        .frame(height: proxy.size.height * 0.7)
                        .position(
                            x: proxy.size.width / 2 + sin(time * 0.8) * travel / 2,
                            y: proxy.size.height * 0.55
                        )
                }
            }
            .allowsHitTesting(false)
            .transition(.scale(scale: 0.1).combined(with: .opacity))
        }
    }
}
