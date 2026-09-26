import SwiftUI

/// Reads the fold's `ReservedRegion(.division)` and paints it as a glowing red crack.
/// Put it as an overlay on the full-screen arrangement view. Invisible when the device is flat.
struct HingeGapGlow: View {
    var intensity: Double

    @State private var divisionFrames: [CGRect] = []

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            ForEach(Array(divisionFrames.enumerated()), id: \.offset) { _, frame in
                Rectangle()
                    .fill(.red.gradient)
                    .frame(width: max(frame.width, 4), height: max(frame.height, 4))
                    .shadow(color: .red, radius: 12 + 24 * intensity)
                    .opacity(0.4 + 0.6 * intensity)
                    .position(x: frame.midX, y: frame.midY)
            }
        }
        .onGeometryChange(for: [CGRect].self) { proxy in
            proxy.reservedRegions(kind: .division).map(\.frame)
        } action: { frames in
            divisionFrames = frames
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
