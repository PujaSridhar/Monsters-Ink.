import SwiftUI

/// DEV B — The inner display whenever the phone is open.
/// During an active session, opening the phone triggers the kaiju warning / agitation / rampage,
/// and provides a quick "Give Up" option so the user can abort and save their city at any time.
/// Outside an active session, the city is peaceful and completely safe from destruction.
struct OpenGameView: View {
    @Environment(KaijuEngine.self) private var engine
    @State private var showGiveUpConfirmation = false

    var body: some View {
        ZStack(alignment: .top) {
            CityBoard()
                .overlay { moodTint }

            // Floating Header: Single Countdown Timer + Quick Give Up Option
            VStack(spacing: 8) {
                if engine.isSessionActive {
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Focusing · \(currentDistrictName)")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.white.opacity(0.85))

                            // The single countdown timer
                            Text(Duration.seconds(engine.remainingSessionTime), format: .time(pattern: .minuteSecond))
                                .font(.system(size: 24, weight: .heavy, design: .rounded).monospacedDigit())
                                .foregroundStyle(.yellow)
                        }

                        Spacer()

                        // Quick Give Up button in expanded mode
                        Button(role: .destructive) {
                            showGiveUpConfirmation = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.circle.fill")
                                Text("Give Up")
                            }
                            .font(.subheadline.weight(.bold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.85))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial.opacity(0.85))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                            )
                    )
                    .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 3)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))

                    if !engine.state.showsOnlyEyes {
                        StatusBanner(text: engine.state.subtitle)
                            .transition(.opacity)
                    }
                } else {
                    StatusBanner(text: "City at Peace · Close phone to start a focus session")
                        .transition(.opacity)
                        .padding(.top, 10)
                }
            }
        }
        .animation(.smooth, value: engine.state)
        .animation(.smooth, value: engine.isSessionActive)
        .confirmationDialog(
            "Give Up Focus Session?",
            isPresented: $showGiveUpConfirmation,
            titleVisibility: .visible
        ) {
            Button("Give Up & Revert Progress", role: .destructive) {
                withAnimation(.spring) {
                    engine.stopFocusSession()
                }
            }
            Button("Keep Focusing", role: .cancel) {}
        } message: {
            Text("Stopping now will cancel this focus session and revert the city back to its saved state.")
        }
    }

    private var currentDistrictName: String {
        engine.map.developedBlocks.last?.districtName ?? "Central Plaza"
    }

    /// Reddens the town once smashing starts during an active session.
    private var moodTint: some View {
        let opacity: Double = switch engine.state {
        case .agitation: engine.isSessionActive ? 0.15 : 0
        case .rampage, .multitasking: engine.isSessionActive ? 0.25 : 0
        case .incubation, .warning, .neglect: 0
        }
        return Color.red.opacity(opacity)
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}
