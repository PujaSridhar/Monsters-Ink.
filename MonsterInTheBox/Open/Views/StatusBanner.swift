import SwiftUI

/// DEV B — The state's subtitle in a capsule. While the device is partially folded it moves
/// to the trailing side of the fold (`ReservedRegion(.division)`) so the text never breaks
/// across the crease.
struct StatusBanner: View {
    var text: String

    @State private var fold: CGRect?

    var body: some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.black.opacity(0.6), in: .capsule)
            .contentTransition(.opacity)
            .frame(maxWidth: .infinity)
            .padding(.leading, leadingInset)
            .padding(.horizontal)
            .padding(.top, 100)
            .onGeometryChange(for: CGRect?.self) { proxy in
                proxy.reservedRegions(kind: .division).first?.frame
            } action: { frame in
                fold = frame
            }
    }

    /// Only a vertical fold (book pose) needs displacing; a horizontal one sits below the banner.
    private var leadingInset: CGFloat {
        guard let fold, fold.height > fold.width else { return 0 }
        return fold.maxX
    }
}
