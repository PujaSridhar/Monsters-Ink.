import SwiftUI

/// DEV A — The outer display while the phone is folded closed (Act 1: Incubation).
/// Working baseline: Bite paces the street, towers grow, cats wander, focus timer counts up.
/// See docs/DEV_A_CLOSED.md for the task list.
struct ClosedGameView: View {
    @Environment(KaijuEngine.self) private var engine

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [.indigo, .cyan.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Spacer(minLength: 90)
                FocusTimer(seconds: engine.focusSeconds, buildProgress: engine.buildProgress)
                Spacer()
                ZStack(alignment: .bottomLeading) {
                    CitySkyline(buildings: engine.buildings, tileSize: 24)
                    BiteView(form: engine.state.monsterForm)
                        .frame(width: 60, height: 93)
                        .padding(.leading, 24)
                        .padding(.bottom, 24)
                }
                CatCrowd(isFleeing: false, catSize: 36)
            }
        }
        .sensoryFeedback(.increase, trigger: engine.floorsBuiltCount)
    }
}

private struct FocusTimer: View {
    var seconds: TimeInterval
    var buildProgress: Double

    var body: some View {
        VStack(spacing: 8) {
            Text("Focus")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))
            Text(Duration.seconds(seconds), format: .time(pattern: .minuteSecond))
                .font(.system(size: 56, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
                .contentTransition(.numericText())
            ProgressView(value: buildProgress) {
                Label("Next floor", systemImage: "hammer.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .tint(.yellow)
            .frame(maxWidth: 220)
        }
    }
}
