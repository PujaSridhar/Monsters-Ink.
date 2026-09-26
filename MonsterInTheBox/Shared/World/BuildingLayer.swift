import SwiftUI

/// Draws every tower standing on its lot and rising up into the yard behind it.
struct BuildingLayer: View {
    var lots: [Lot]
    var metrics: WorldMetrics

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(lots) { lot in
                TowerSprite(lot: lot, tileWidth: metrics.tileWidth, tileHeight: metrics.tileHeight)
                    .position(towerCenter(for: lot))
            }
        }
        .frame(width: metrics.size.width, height: metrics.size.height, alignment: .topLeading)
        .animation(.bouncy, value: lots)
    }

    /// The tower's bottom edge sits on the bottom of its lot cell.
    private func towerCenter(for lot: Lot) -> CGPoint {
        let cell = metrics.rect(of: lot.position)
        let height = CGFloat(TowerSprite.tileCount(for: lot)) * metrics.tileHeight
        return CGPoint(x: cell.midX, y: cell.maxY - height / 2)
    }
}

/// One tower: roof on top, middle floors, base with a door. Rust tints it brown.
struct TowerSprite: View {
    var lot: Lot
    var tileWidth: CGFloat
    var tileHeight: CGFloat

    static func tileCount(for lot: Lot) -> Int {
        if lot.isEmpty { return lot.isRubble ? 1 : 0 }
        return lot.floors + 1
    }

    var body: some View {
        VStack(spacing: 0) {
            if lot.isRubble {
                CityTile(index: lot.style.rubbleTile, width: tileWidth, height: tileHeight)
            } else if !lot.isEmpty {
                CityTile(index: lot.style.roofTile, width: tileWidth, height: tileHeight)
                ForEach(0..<(lot.floors - 1), id: \.self) { _ in
                    CityTile(index: lot.style.middleTile, width: tileWidth, height: tileHeight)
                }
                CityTile(index: lot.style.baseTile, width: tileWidth, height: tileHeight)
            }
        }
        .overlay {
            Rectangle()
                .fill(.brown)
                .blendMode(.multiply)
                .opacity(lot.rust * 0.8)
        }
        .saturation(1 - lot.rust * 0.7)
        .accessibilityElement()
        .accessibilityLabel(lot.isRubble ? "Rubble" : lot.isEmpty ? "Empty lot" : "Tower, \(lot.floors) floors")
    }
}
