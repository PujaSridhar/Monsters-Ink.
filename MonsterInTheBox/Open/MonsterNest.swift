import SwiftUI

/// DEV B — Secondary pane of the ArrangementView: the cat in the box and a minion, reacting to the hinge.
/// Bite himself only appears as the kaiju overlay in `OpenGameView`.
struct MonsterNest: View {
    @Environment(KaijuEngine.self) private var engine

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 90)
            Text(engine.state.subtitle)
                .font(.title2.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            HStack(alignment: .bottom, spacing: 24) {
                if let catMood = engine.state.catMood {
                    // Warning / Agitation: the cat in the box begs you to fold the phone.
                    PeekingCatView(mood: catMood, annoyance: engine.hapticIntensity)
                        .frame(width: 200, height: 200)
                        .transition(.scale.combined(with: .opacity))
                }
                if let minion = engine.state.minion {
                    PixelSprite(asset: minion.asset)
                        .frame(width: 140, height: 110)
                        .id(minion.asset)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.bouncy, value: engine.state.minion)
            .animation(.bouncy, value: engine.state.catMood)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
