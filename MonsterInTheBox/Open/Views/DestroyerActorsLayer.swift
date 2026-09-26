import SwiftUI

/// DEV B — What moves on the open-phone map.
/// - Warning: the city goes dark and the cat hides; only its big red eyes stare out.
/// - Agitation / Rampage / Multitasking: the one hero cat is a 1.5× kaiju that hunts and eats
///   the citizen cats and smashes towers. Citizens flee along the roads.
struct DestroyerActorsLayer: View {
    @Environment(KaijuEngine.self) private var engine
    var metrics: WorldMetrics

    var body: some View {
        let actors = engine.actors
        let state = engine.state
        ZStack(alignment: .topLeading) {
            if state.showsOnlyEyes {
                Color.black.opacity(0.88)
                    .frame(width: metrics.size.width, height: metrics.size.height)
                HidingEyes(width: metrics.tileSize * 5, intensity: engine.hapticIntensity)
                    .position(metrics.center(of: actors.hero.position))
                    .transition(.opacity)
            } else {
                ForEach(actors.citizens) { citizen in
                    ActorView(actor: citizen, metrics: metrics)
                        .transition(.scale(scale: 0.1).combined(with: .opacity))
                }
                ActorView(actor: actors.hero, metrics: metrics, scale: state.heroScale, hasRedEyes: true)
                    .shadow(color: .red, radius: state.isDestructive ? 8 : 0)
                if let mood = state.catMood {
                    HeroBubble(mood: mood, hero: actors.hero, scale: state.heroScale, metrics: metrics)
                }
                if let position = engine.lastEatenPosition {
                    ChompPop(trigger: engine.catsEatenCount)
                        .position(metrics.center(of: position))
                }
            }
        }
        .frame(width: metrics.size.width, height: metrics.size.height, alignment: .topLeading)
        .animation(.smooth(duration: 0.6), value: state.showsOnlyEyes)
        .animation(.snappy, value: actors.citizens.count)
        .allowsHitTesting(false)
    }
}

/// "CHOMP!" bursting out where a cat was eaten. Invisible until `trigger` changes.
private struct ChompPop: View {
    var trigger: Int

    var body: some View {
        Text("CHOMP!")
            .font(.system(size: 28, weight: .black, design: .rounded))
            .foregroundStyle(.yellow)
            .shadow(color: .red, radius: 4)
            .keyframeAnimator(initialValue: 0.0, trigger: trigger) { content, value in
                content
                    .scaleEffect(0.5 + value)
                    .opacity(value > 0 ? min(1, value * 2) : 0)
                    .offset(y: -value * 30)
            } keyframes: { _ in
                SpringKeyframe(1, duration: 0.3, spring: .bouncy)
                LinearKeyframe(1, duration: 0.4)
                LinearKeyframe(0, duration: 0.3)
            }
            .accessibilityHidden(true)
    }
}

/// A message bubble whose tail points at the hero cat's head. Lines rotate from `CatMood.lines`.
private struct HeroBubble: View {
    var mood: CatMood
    var hero: CatActor
    var scale: CGFloat
    var metrics: WorldMetrics

    var body: some View {
        TimelineView(.periodic(from: .now, by: mood.lineDuration)) { context in
            let lines = mood.lines
            let line = lines[Int(context.date.timeIntervalSinceReferenceDate / mood.lineDuration) % lines.count]
            // Zero-size anchor at the cat's head; the bubble sits on top of it.
            Color.clear
                .frame(width: 1, height: 1)
                .overlay(alignment: .bottom) {
                    MessageBubble(text: line, mood: mood)
                        .fixedSize()
                        .id(line)
                        .transition(.scale(scale: 0.3, anchor: .bottom).combined(with: .opacity))
                }
                .animation(.bouncy, value: line)
        }
        .position(headPoint)
        .animation(.linear(duration: hero.stepDuration), value: hero.position)
        .accessibilityHidden(true)
    }

    /// Matches `ActorView`: the sprite's frame is centered at `maxY - size * 0.3`, and the
    /// cat's head starts about a third of the way down the frame.
    private var headPoint: CGPoint {
        let size = metrics.tileSize * ActorView.frameToTile * scale
        let cell = metrics.rect(of: hero.position)
        let center = cell.maxY - size * 0.3
        return CGPoint(x: cell.midX, y: center - size * 0.16)
    }
}
