import SwiftUI

/// DEV A — Closed phone experience. The hero cat starts building from the center of the world
/// and gradually expands outward into the open world.
/// Users choose their focus duration; stopping early reverts to initial state, while timer expiration
/// permanently locks in the final state (rewarded with new buildings or penalized with damage).
struct ClosedGameView: View {
    @Environment(KaijuEngine.self) private var engine
    @State private var latestUnlockedDistrict: String?
    @State private var bannerDismissTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            // The world fills the whole outer display, edge to edge.
            WorldStage(map: engine.map, fillsScreen: true) { metrics in
                BuilderActorsLayer(metrics: metrics)
            }
            .ignoresSafeArea()

            VStack(spacing: 12) {
                // Focus HUD with countdown or city status
                FocusHUD()
                    .padding(.top, 16)

                // Optional celebration banner when a new district unlocks
                if let district = latestUnlockedDistrict {
                    DistrictUnlockedBanner(name: district)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()

                // Focus duration picker & session controls, floating over the map
                FocusSessionControlsView()
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sensoryFeedback(.increase, trigger: engine.floorsBuiltCount)
        .sensoryFeedback(.success, trigger: engine.blocksDevelopedCount)
        .onChange(of: engine.blocksDevelopedCount) { _, newCount in
            guard newCount > 1, let district = engine.map.developedBlocks.last?.districtName else { return }
            bannerDismissTask?.cancel()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                latestUnlockedDistrict = district
            }
            bannerDismissTask = Task {
                try? await Task.sleep(for: .seconds(3.5))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.4)) {
                    latestUnlockedDistrict = nil
                }
            }
        }
    }
}

/// A retro celebratory banner displayed when the city expands into a new wilderness district.
private struct DistrictUnlockedBanner: View {
    var name: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundStyle(.yellow)
            Text("District Unlocked: \(name)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.yellow.opacity(0.6), lineWidth: 1.5))
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}
