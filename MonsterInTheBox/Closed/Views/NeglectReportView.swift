import SwiftUI

/// DEV A — Shown when the app returns from the background (Act 4: Neglect).
/// The user never saw the monster; they only see the rusted aftermath under acid rain.
struct NeglectReportView: View {
    @Environment(KaijuEngine.self) private var engine
    @Environment(\.dismiss) private var dismiss
    var report: NeglectReport

    var body: some View {
        VStack(spacing: 12) {
            Text("While you were away…")
                .font(.title2.bold())
            Text("Acid rain fell for \(Duration.seconds(report.secondsAway), format: .units(allowed: [.minutes, .seconds], width: .wide)).")
                .foregroundStyle(.white.opacity(0.7))
            Text("City lost \(report.healthLost, format: .number.precision(.fractionLength(0))) health")
                .font(.headline)
                .foregroundStyle(.green)
            CatSprite(look: .hero, animation: .sleep)
                .frame(width: 96, height: 96)
            // Same world, no cats: just the rusted city.
            WorldStage(map: engine.map) { _ in EmptyView() }
            Button {
                dismiss()
            } label: {
                Text("Back to Focus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .foregroundStyle(.white)
        .background {
            ZStack {
                Color(red: 0.12, green: 0.16, blue: 0.1)
                EffectsLayer(acidRain: 1)
            }
            .ignoresSafeArea()
        }
        .presentationDetents([.large])
    }
}
