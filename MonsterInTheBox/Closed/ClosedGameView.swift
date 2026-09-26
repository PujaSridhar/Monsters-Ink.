import SwiftUI

/// DEV A — The outer display while the phone is folded closed (Act 1: Incubation).
/// Composes: the shared tile world + the builder cats layer + the focus HUD.
/// See docs/DEV_A_CLOSED.md for the task list.
struct ClosedGameView: View {
    @Environment(KaijuEngine.self) private var engine

    var body: some View {
        VStack(spacing: 8) {
            FocusHUD()
                .padding(.top, 80)
            WorldStage(map: engine.map) { metrics in
                BuilderActorsLayer(metrics: metrics)
            }
            .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.13, green: 0.35, blue: 0.2).ignoresSafeArea())
        .sensoryFeedback(.increase, trigger: engine.floorsBuiltCount)
        .sensoryFeedback(.success, trigger: engine.blocksDevelopedCount)
    }
}
