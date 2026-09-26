import SwiftUI

/// Stacks Kenney tiles into a tower: roof on top, `floors - 1` middles, base at the bottom.
/// Rust from neglect tints it brown. A collapsed lot shows rubble.
struct BuildingView: View {
    var building: Building
    var tileSize: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            if building.isRubble {
                CityTile(index: building.style.rubbleTile, size: tileSize)
            } else {
                CityTile(index: building.style.roofTile, size: tileSize)
                ForEach(0..<max(building.floors - 1, 0), id: \.self) { _ in
                    CityTile(index: building.style.middleTile, size: tileSize)
                }
                CityTile(index: building.style.baseTile, size: tileSize)
            }
        }
        .overlay {
            Rectangle()
                .fill(.brown)
                .blendMode(.multiply)
                .opacity(building.rust * 0.8)
        }
        .saturation(1 - building.rust * 0.7)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .accessibilityElement()
        .accessibilityLabel("Tower, \(building.floors) floors")
    }
}
