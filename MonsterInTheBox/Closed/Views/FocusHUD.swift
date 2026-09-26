import SwiftUI

/// DEV A — Focus timer, next-floor progress, and city size, above the map.
struct FocusHUD: View {
    @Environment(KaijuEngine.self) private var engine

    var body: some View {
        VStack(spacing: 6) {
            Text(Duration.seconds(engine.focusSeconds), format: .time(pattern: .minuteSecond))
                .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                .contentTransition(.numericText())
            ProgressView(value: engine.buildProgress) {
                Label("Next floor", systemImage: "hammer.fill")
                    .font(.caption)
            }
            .tint(.yellow)
            .frame(maxWidth: 220)
            Text("\(engine.map.totalFloors) floors · \(engine.map.developedBlocks.count) of \(CityLayout.expansionOrder.count) blocks")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white.opacity(0.8))
        }
        .foregroundStyle(.white)
    }
}
