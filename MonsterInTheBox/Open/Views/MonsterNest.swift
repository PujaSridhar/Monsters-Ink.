import SwiftUI

/// DEV B — Secondary pane: the cat in the box pleading (warning) and annoyed (agitation),
/// plus a minion that matches the mood. During a rampage it shows the city's health draining.
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
                    PeekingCatView(mood: catMood, annoyance: engine.hapticIntensity)
                        .frame(width: 200, height: 200)
                        .transition(.scale.combined(with: .opacity))
                }
                if let minion = engine.state.minion {
                    PixelSprite(asset: minion.asset)
                        .frame(width: 120, height: 95)
                        .id(minion.asset)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.bouncy, value: engine.state.minion)
            .animation(.bouncy, value: engine.state.catMood)
            if engine.state.isKaiju {
                Gauge(value: engine.cityHealth, in: 0...100) {
                    Text("City health")
                }
                .tint(.red)
                .foregroundStyle(.white)
                .frame(maxWidth: 260)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
