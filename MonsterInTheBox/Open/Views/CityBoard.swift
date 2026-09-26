import SwiftUI

/// DEV B — The city stretched across the entire inner display, edge to edge and across both
/// halves of the fold.
/// If an active session is in an infraction state (warning, agitation, rampage, multitasking):
/// the destroyer layer shows the hiding red eyes (at warning) or kaiju destruction (at rampage).
/// If outside an active session or during incubation, the peaceful builder layer shows.
struct CityBoard: View {
    @Environment(KaijuEngine.self) private var engine

    var body: some View {
        WorldStage(map: engine.map, fillsScreen: true) { metrics in
            if engine.isSessionActive && engine.state != .incubation {
                DestroyerActorsLayer(metrics: metrics)
            } else {
                BuilderActorsLayer(metrics: metrics)
            }
        }
        .overlay {
            if engine.isSessionActive && engine.state.isDestructive {
                EffectsLayer(
                    dust: min(1, engine.state.floorsDestroyedPerSecond / 3),
                    burstTrigger: engine.floorsDestroyedCount
                )
            }
        }
        .ignoresSafeArea()
        .sensoryFeedback(.impact(weight: .heavy), trigger: engine.floorsDestroyedCount)
        .sensoryFeedback(.impact(weight: .heavy, intensity: 1), trigger: engine.catsEatenCount)
    }
}
