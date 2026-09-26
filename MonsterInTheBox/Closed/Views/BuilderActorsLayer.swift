import SwiftUI

/// DEV A — Cats on the closed-phone map: citizens roaming the roads, and the hero cat walking
/// to lots and hammering. Reads only `engine.actors` and `engine.builder`, so it redraws
/// independently of the map.
struct BuilderActorsLayer: View {
    @Environment(KaijuEngine.self) private var engine
    var metrics: WorldMetrics

    var body: some View {
        let actors = engine.actors
        ZStack(alignment: .topLeading) {
            ForEach(actors.citizens) { citizen in
                ActorView(actor: citizen, metrics: metrics)
            }
            if let lot = engine.builder.targetLot {
                TargetMarker(metrics: metrics, lot: lot)
            }
            ActorView(actor: actors.hero, metrics: metrics)
            if actors.hero.activity == .building {
                HammerPop(metrics: metrics, position: actors.hero.position)
            }
        }
        .frame(width: metrics.size.width, height: metrics.size.height, alignment: .topLeading)
        .allowsHitTesting(false)
    }
}

/// A bouncing paw print over the lot the cat is heading to.
private struct TargetMarker: View {
    var metrics: WorldMetrics
    var lot: GridPoint

    var body: some View {
        SpriteSheet.cat(.cat5).frame(2)
            .resizable()
            .frame(width: metrics.tileSize * 1.5, height: metrics.tileSize * 1.5)
            .colorMultiply(.yellow)
            .phaseAnimator([0.0, -6.0]) { content, offset in
                content.offset(y: offset)
            } animation: { _ in .bouncy }
            .position(metrics.center(of: lot))
            .accessibilityHidden(true)
    }
}

/// A hammer bouncing above the cat while it builds.
private struct HammerPop: View {
    var metrics: WorldMetrics
    var position: GridPoint

    var body: some View {
        let cell = metrics.rect(of: position)
        Image(systemName: "hammer.fill")
            .font(.system(size: metrics.tileSize * 0.8))
            .foregroundStyle(.yellow)
            .shadow(radius: 2)
            .symbolEffect(.bounce, options: .repeating)
            .position(x: cell.midX, y: cell.minY - metrics.tileSize * 0.8)
            .accessibilityHidden(true)
    }
}
