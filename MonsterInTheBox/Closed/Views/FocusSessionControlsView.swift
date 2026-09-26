import SwiftUI

/// Allows the user to select how long they wish to focus and manage session lifecycle.
/// Enforces the two-state rule:
/// - Stopping early reverts all progress to the initial snapshot.
/// - Letting the timer finish permanently saves the final state (rewarded with new buildings or penalized with damage).
struct FocusSessionControlsView: View {
    @Environment(KaijuEngine.self) private var engine
    @State private var selectedMinutes: Int = 25
    @State private var showStopConfirmation = false

    private let presets: [Int] = [1, 15, 25, 45, 60, 120]

    var body: some View {
        VStack(spacing: 10) {
            switch engine.sessionStatus {
            case .notStarted, .cancelled:
                setupView

            case .active:
                activeControlsView

            case .completed:
                completedBannerView

            case .penaltyEnded:
                penaltyBannerView
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 4)
        .confirmationDialog(
            "Give Up Focus Session?",
            isPresented: $showStopConfirmation,
            titleVisibility: .visible
        ) {
            Button("Give Up & Lose Progress", role: .destructive) {
                withAnimation(.spring) {
                    engine.stopFocusSession()
                }
            }
            Button("Keep Focusing", role: .cancel) {}
        } message: {
            Text("If you stop now, you will lose all progress and the city will revert to its initial state.")
        }
    }

    // MARK: - Setup View

    private var setupView: some View {
        VStack(spacing: 8) {
            HStack {
                Label("Focus Duration", systemImage: "timer")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                Text(formattedSelectedTime)
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(.yellow)
            }

            // Quick preset pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(presets, id: \.self) { min in
                        let isSelected = selectedMinutes == min
                        Button {
                            selectedMinutes = min
                        } label: {
                            Text(label(for: min))
                                .font(.caption2.weight(isSelected ? .bold : .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(isSelected ? Color.yellow : Color.white.opacity(0.15))
                                .foregroundStyle(isSelected ? Color.black : Color.white)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // Custom stepper
            HStack {
                Button {
                    if selectedMinutes > 5 { selectedMinutes -= 5 }
                    else if selectedMinutes > 1 { selectedMinutes -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                Text("\(selectedMinutes) min")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    if selectedMinutes < 480 { selectedMinutes += (selectedMinutes < 60 ? 5 : 15) }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))

            // Start Focus Button
            Button {
                withAnimation(.spring) {
                    engine.startFocusSession(duration: TimeInterval(selectedMinutes * 60))
                }
            } label: {
                HStack {
                    Image(systemName: "hammer.fill")
                    Text("Start Focus (\(formattedSelectedTime))")
                        .fontWeight(.bold)
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [Color.green.opacity(0.9), Color(red: 0.15, green: 0.65, blue: 0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .green.opacity(0.4), radius: 6, x: 0, y: 3)
            }
        }
    }

    // MARK: - Active View (Single timer is already shown above in FocusHUD)

    private var activeControlsView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Focusing · \(engine.map.developedBlocks.last?.districtName ?? "Central Plaza")")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Text("Keep phone closed to build towers")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.65))
            }

            Spacer()

            Button(role: .destructive) {
                showStopConfirmation = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "xmark.circle.fill")
                    Text("Stop")
                }
                .font(.caption.weight(.bold))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color.red.opacity(0.85))
                .foregroundStyle(.white)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
        }
    }

    // MARK: - Completed View

    private var completedBannerView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundStyle(.yellow)
                Text("Focus Complete!")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
            }
            Text("Your patience paid off! City construction was permanently saved.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                withAnimation(.spring) {
                    engine.dismissSessionSummary()
                }
            } label: {
                Text("Start Next Session")
                    .font(.caption.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.yellow)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Penalty View

    private var penaltyBannerView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Time Expired with Phone Use")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
            }
            Text("The city suffered destruction while you used your phone. The damaged state has been permanently saved.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                withAnimation(.spring) {
                    engine.dismissSessionSummary()
                }
            } label: {
                Text("Acknowledge & Rebuild")
                    .font(.caption.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Helpers

    private var formattedSelectedTime: String {
        if selectedMinutes < 60 {
            return "\(selectedMinutes)m"
        } else {
            let h = selectedMinutes / 60
            let m = selectedMinutes % 60
            return m == 0 ? "\(h)h" : "\(h)h \(m)m"
        }
    }

    private func label(for minutes: Int) -> String {
        if minutes == 1 { return "1m (Demo)" }
        if minutes < 60 { return "\(minutes)m" }
        let h = minutes / 60
        let m = minutes % 60
        return m == 0 ? "\(h)h" : "\(h)h\(m)m"
    }
}
