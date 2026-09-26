import SwiftUI

/// DEV B — Places the hiding cat's eyes on the inner display while the phone is opening.
/// - Opened sideways (book pose, vertical fold): the eyes stay on the **right screen**. They
///   start at its right edge and creep left toward the fold as the hinge opens.
/// - Opened upward (laptop pose, horizontal fold): the eyes stay on the **bottom screen**. They
///   start at its bottom edge and rise toward the fold.
/// They never cross the fold. At 180° the game switches to the city and kaiju.
///
/// The fold comes from `ReservedRegion(.division)`. If none is reported (e.g. the debug
/// slider), the screen's shape decides the direction and its midline stands in for the fold.
struct HidingEyesStage: View {
    /// Hinge angle in degrees (0 = closed, 180 = flat).
    var angle: Double
    var intensity: Double
    var eyesWidth: CGFloat

    @State private var fold: CGRect?

    var body: some View {
        GeometryReader { proxy in
            HidingEyes(width: eyesWidth, intensity: intensity)
                .position(position(in: proxy.size))
                .animation(.smooth, value: angle)
        }
        .onGeometryChange(for: CGRect?.self) { proxy in
            proxy.reservedRegions(kind: .division).first?.frame
        } action: { frame in
            // Keep the last known fold if the region briefly disappears.
            if let frame { fold = frame }
        }
    }

    /// 0 while barely cracked, 1 just before flat.
    private var progress: CGFloat {
        CGFloat(min(max(angle / GameTuning.rampageAngle, 0), 1))
    }

    private func axis(in size: CGSize) -> FoldAxis {
        if let fold { return fold.height > fold.width ? .vertical : .horizontal }
        return size.width > size.height ? .horizontal : .vertical
    }

    private func position(in size: CGSize) -> CGPoint {
        let eyesHeight = eyesWidth * 0.38 / 1.6
        let gap: CGFloat = 16
        switch axis(in: size) {
        case .vertical:
            // Right screen: right edge → just right of the fold.
            let foldEdge = fold?.maxX ?? size.width / 2
            let start = size.width - eyesWidth / 2 - gap
            let end = min(start, foldEdge + eyesWidth / 2 + gap)
            return CGPoint(x: start + (end - start) * progress, y: size.height / 2)
        case .horizontal:
            // Bottom screen: bottom edge → just below the fold.
            let foldEdge = fold?.maxY ?? size.height / 2
            let start = size.height - eyesHeight - gap * 3
            let end = min(start, foldEdge + eyesHeight + gap)
            return CGPoint(x: size.width / 2, y: start + (end - start) * progress)
        }
    }
}

/// Which way the crease runs across the inner display.
nonisolated enum FoldAxis: Equatable, Sendable {
    /// A vertical crease: the phone opens sideways, like a book.
    case vertical
    /// A horizontal crease: the phone opens upward, like a laptop.
    case horizontal
}
