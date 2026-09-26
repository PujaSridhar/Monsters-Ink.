import SwiftUI

/// DEV B — The city stretched across the entire inner display, edge to edge and across both
/// halves of the fold, with the destroyer layer and debris effects on top.
struct CityBoard: View {
    @Environment(KaijuEngine.self) private var engine

    var body: some View {
        WorldStage(map: engine.map, fillsScreen: true) { metrics in
            DestroyerActorsLayer(metrics: metrics)
        }
        .overlay {
            EffectsLayer(
                dust: min(1, engine.state.floorsDestroyedPerSecond / 3),
                burstTrigger: engine.floorsDestroyedCount
            )
        }
        .ignoresSafeArea()
        .sensoryFeedback(.impact(weight: .heavy), trigger: engine.floorsDestroyedCount)
        .sensoryFeedback(.impact(weight: .heavy, intensity: 1), trigger: engine.catsEatenCount)
    }
}
