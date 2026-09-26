import SwiftUI

/// DEV A — Shown when the app returns from the background (Act 4: Neglect).
/// The user never saw the monster; they only see the rusted aftermath under acid rain.
struct NeglectReportView: View {
    @Environment(KaijuEngine.self) private var engine
    @Environment(\.dismiss) private var dismiss
    var report: NeglectReport

    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.16, blue: 0.1)
                .ignoresSafeArea()
            EffectsLayer(acidRain: 1)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("While you were away…")
                    .font(.title2.bold())
                Text("Acid rain fell for \(Duration.seconds(report.secondsAway), format: .units(allowed: [.minutes, .seconds], width: .wide)).")
                    .foregroundStyle(.secondary)
                Text("City lost \(report.healthLost, format: .number.precision(.fractionLength(0))) health")
                    .font(.headline)
                    .foregroundStyle(.green)
                BiteView(form: .sleeping)
                    .frame(width: 100, height: 155)
                CitySkyline(buildings: engine.buildings, tileSize: 20)
                Button {
                    dismiss()
                } label: {
                    Text("Back to Focus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
            }
            .padding()
            .foregroundStyle(.white)
        }
        .presentationDetents([.large])
    }
}
