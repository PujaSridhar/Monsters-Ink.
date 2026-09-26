import SwiftUI

/// "The State Visualizer" from the spec: a HUD showing the live state, plus a debug drawer that
/// simulates the hinge and split screen so you can build on any simulator.
struct StateVisualizer: View {
    @Environment(KaijuEngine.self) private var engine
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.snappy) { isExpanded.toggle() }
            } label: {
                hud
            }
            .buttonStyle(.plain)
            .accessibilityHint(isExpanded ? "Hides debug controls" : "Shows debug controls")

            if isExpanded {
                DebugControls()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(10)
        .background(.black.opacity(0.6), in: .rect(cornerRadius: 16))
        .foregroundStyle(.white)
        .frame(maxWidth: 340)
    }

    private var hud: some View {
        HStack(spacing: 10) {
            Image(systemName: engine.state.symbolName)
                .font(.title2)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(engine.state.title)
                    .font(.headline)
                Text("\(engine.hinge.angleDegrees, format: .number.precision(.fractionLength(0)))° · \(engine.hinge.status.rawValue)\(engine.isMultitasking ? " · split" : "")")
                    .font(.caption.monospaced())
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer(minLength: 8)
            Gauge(value: engine.cityHealth, in: 0...100) {
                Text("City")
            } currentValueLabel: {
                Text(engine.cityHealth, format: .number.precision(.fractionLength(0)))
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(engine.cityHealth > 50 ? .green : engine.cityHealth > 20 ? .orange : .red)
            .scaleEffect(0.7)
            .frame(width: 44, height: 44)
        }
        .contentShape(.rect)
    }
}

private struct DebugControls: View {
    @Environment(KaijuEngine.self) private var engine

    var body: some View {
        @Bindable var engine = engine
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Simulate hinge", isOn: simulateHinge)
            if engine.simulatedHinge != nil {
                Slider(value: simulatedAngle, in: 0...180) {
                    Text("Hinge angle")
                } minimumValueLabel: {
                    Image(systemName: "iphone")
                } maximumValueLabel: {
                    Image(systemName: "rectangle.split.2x1")
                }
            }
            Toggle("Simulate split screen", isOn: simulateSplit)
            Toggle("Demo speed (seconds, not minutes)", isOn: $engine.isDemoMode)
            Button("Reset City", systemImage: "arrow.counterclockwise") {
                engine.resetCity()
            }
        }
        .font(.subheadline)
        .tint(.orange)
    }

    private var simulateHinge: Binding<Bool> {
        Binding {
            engine.simulatedHinge != nil
        } set: { isOn in
            engine.simulate(hinge: isOn ? engine.realHinge ?? .closed : nil)
        }
    }

    private var simulatedAngle: Binding<Double> {
        Binding {
            engine.simulatedHinge?.angleDegrees ?? 0
        } set: { angle in
            engine.simulate(hinge: HingeReading(simulatedAngle: angle))
        }
    }

    private var simulateSplit: Binding<Bool> {
        Binding {
            engine.simulatedMultitasking ?? false
        } set: { isOn in
            engine.simulate(multitasking: isOn ? true : nil)
        }
    }
}
