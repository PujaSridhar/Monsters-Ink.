import SwiftUI

/// DEV B — Cats on the open-phone map. Citizens flee along the roads; the hero cat stares
/// (warning), paces (agitation), or becomes the kaiju: the same cat, scaled up.
struct DestroyerActorsLayer: View {
    @Environment(KaijuEngine.self) private var engine
    var metrics: WorldMetrics

    /// How much bigger the kaiju cat is than a normal cat.
    static let kaijuScale: CGFloat = 4

    var body: some View {
        let actors = engine.actors
        let state = engine.state
        ZStack(alignment: .topLeading) {
            ForEach(actors.citizens) { citizen in
                ActorView(actor: citizen, metrics: metrics)
            }
            ActorView(actor: actors.hero, metrics: metrics, scale: state.isKaiju ? Self.kaijuScale : 1)
                .shadow(color: .red, radius: state == .agitation ? 6 : 0)
        }
        .frame(width: metrics.size.width, height: metrics.size.height, alignment: .topLeading)
        .allowsHitTesting(false)
    }
}
