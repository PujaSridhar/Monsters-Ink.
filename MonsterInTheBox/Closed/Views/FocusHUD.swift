import SwiftUI

/// DEV A — Displays focus metrics, countdown, next-floor progress, and city stats.
/// Styled with a sleek, translucent frosted container without developer jargon or ugly gauges.
struct FocusHUD: View {
    @Environment(KaijuEngine.self) private var engine

    var body: some View {
        VStack(spacing: 8) {
            if engine.isSessionActive {
                // Focus countdown timer
                Text(Duration.seconds(engine.remainingSessionTime), format: .time(pattern: .minuteSecond))
                    .font(.system(size: 42, weight: .heavy, design: .rounded).monospacedDigit())
                    .contentTransition(.numericText())
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

                // Current district badge
                HStack(spacing: 5) {
                    Image(systemName: "map.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                    Text(currentDistrictName)
                        .font(.caption.weight(.semibold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(Color.black.opacity(0.25), in: Capsule())

                // Next floor progress bar
                ProgressView(value: engine.buildProgress) {
                    Label("Building next floor", systemImage: "hammer.fill")
                        .font(.caption2.weight(.medium))
                }
                .tint(.yellow)
                .frame(maxWidth: 210)
            } else {
                // Idle status
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.yellow)
                    Text("Central City")
                        .font(.headline.weight(.bold))
                }

                Text("Start a focus session to expand the city")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
            }

            // Floors & district counter
            Text("\(engine.map.totalFloors) floors · \(engine.map.developedBlocks.count) of \(CityLayout.expansionOrder.count) Districts")
                .font(.caption2.monospacedDigit().weight(.medium))
                .foregroundStyle(.white.opacity(0.85))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }

    private var currentDistrictName: String {
        engine.map.developedBlocks.last?.districtName ?? "Central Plaza"
    }
}
