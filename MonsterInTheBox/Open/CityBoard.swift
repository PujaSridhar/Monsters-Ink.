import SwiftUI

/// DEV B — Primary pane of the ArrangementView: the city under attack.
struct CityBoard: View {
    @Environment(KaijuEngine.self) private var engine

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 8) {
                Spacer()
                CitySkyline(buildings: engine.buildings, tileSize: 30)
                CatCrowd(isFleeing: engine.state.isDestructive, catSize: 40)
            }
            EffectsLayer(
                dust: engine.state.isDestructive ? min(1, engine.state.destructionPerSecond / 10) : 0,
                burstTrigger: engine.floorsDestroyedCount
            )
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: engine.floorsDestroyedCount)
    }
}
