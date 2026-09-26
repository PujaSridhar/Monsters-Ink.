import SwiftUI

/// The tile world, layered bottom to top:
/// 1. `GroundLayer`: grass, roads, yards, lots
/// 2. `BuildingLayer`: towers and rubble
/// 3. `actors`: whatever cats layer the current mode supplies (builder or kaiju)
///
/// The grid is scaled to fit and centered. Each mode passes its own actors layer, so the
/// closed and open experiences share the city but never share cat code.
struct WorldStage<Actors: View>: View {
    var map: CityMap
    @ViewBuilder var actors: (WorldMetrics) -> Actors

    var body: some View {
        GeometryReader { proxy in
            let metrics = WorldMetrics.fitting(proxy.size)
            ZStack(alignment: .topLeading) {
                GroundLayer(map: map, metrics: metrics)
                BuildingLayer(lots: map.sortedLots, metrics: metrics)
                actors(metrics)
            }
            .frame(width: metrics.size.width, height: metrics.size.height, alignment: .topLeading)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
