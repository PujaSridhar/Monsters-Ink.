import SwiftUI

/// The tile world, layered bottom to top:
/// 1. `GroundLayer`: grass, natural wilderness, roads, yards, lots
/// 2. `WildernessMistLayer`: soft open-world mist over unbuilt districts that clears when developed
/// 3. `BuildingLayer`: towers and rubble
/// 4. `actors`: whatever cats layer the current mode supplies (builder or kaiju)
///
/// The grid is scaled to fit and framed like a floating diorama island (or stretched to fill with `fillsScreen`).
struct WorldStage<Actors: View>: View {
    var map: CityMap
    /// Stretches tiles so the city covers every edge instead of letterboxing a square grid.
    var fillsScreen = false
    @ViewBuilder var actors: (WorldMetrics) -> Actors

    var body: some View {
        GeometryReader { proxy in
            let metrics = fillsScreen ? WorldMetrics.filling(proxy.size) : WorldMetrics.fitting(proxy.size)
            ZStack(alignment: .topLeading) {
                GroundLayer(map: map, metrics: metrics)
                WildernessMistLayer(map: map, metrics: metrics)
                BuildingLayer(lots: map.sortedLots, metrics: metrics)
                actors(metrics)
            }
            .frame(width: metrics.size.width, height: metrics.size.height, alignment: .topLeading)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
            }
            .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// A soft, atmospheric mist hovering over undeveloped wilderness blocks.
/// As each district unlocks, the mist parts smoothly to reveal the new city roads and building lots.
struct WildernessMistLayer: View {
    var map: CityMap
    var metrics: WorldMetrics

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(CityLayout.expansionOrder, id: \.self) { block in
                if !map.developedBlocks.contains(block) {
                    let originRect = metrics.rect(of: block.origin)
                    let blockSpan = CGFloat(CityLayout.blockSize) * metrics.tileSize
                    let centerPoint = CGPoint(
                        x: originRect.origin.x + blockSpan / 2,
                        y: originRect.origin.y + blockSpan / 2
                    )

                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.22),
                                    Color(red: 0.82, green: 0.92, blue: 0.85).opacity(0.12),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 4,
                                endRadius: blockSpan * 0.72
                            )
                        )
                        .frame(width: blockSpan, height: blockSpan)
                        .position(centerPoint)
                        .transition(.opacity.combined(with: .scale(scale: 1.08)))
                }
            }
        }
        .frame(width: metrics.size.width, height: metrics.size.height, alignment: .topLeading)
        .animation(.smooth(duration: 0.9), value: map.developedBlocks)
        .accessibilityHidden(true)
    }
}
