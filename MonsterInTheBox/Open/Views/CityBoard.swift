import SwiftUI

/// DEV B — Primary pane: the shared tile world with the destroyer cats layer and debris effects.
struct CityBoard: View {
    @Environment(KaijuEngine.self) private var engine

    var body: some View {
        WorldStage(map: engine.map) { metrics in
            DestroyerActorsLayer(metrics: metrics)
        }
        .padding(8)
        .overlay {
            EffectsLayer(
                dust: min(1, engine.state.floorsDestroyedPerSecond / 3),
                burstTrigger: engine.floorsDestroyedCount
            )
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: engine.floorsDestroyedCount)
    }
}
