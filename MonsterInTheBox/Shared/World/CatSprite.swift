import SwiftUI

/// Which cat sheet plays for what.
enum CatAnimation {
    case idle
    case walk
    case pounce
    case sleep
    case groom

    var sheet: SpriteSheet {
        switch self {
        case .idle: .cat(.cat0)
        case .walk: .cat(.cat2)
        case .pounce: .cat(.cat3)
        case .sleep: .cat(.cat1)
        case .groom: .cat(.cat4)
        }
    }

    var framesPerSecond: Double {
        switch self {
        case .idle: 4
        case .walk: 12
        case .pounce: 10
        case .sleep: 3
        case .groom: 6
        }
    }

    /// Picks the animation for an actor's current state.
    init(_ actor: CatActor) {
        if actor.isMoving {
            self = .walk
            return
        }
        self = switch actor.activity {
        case .idle: .idle
        case .building, .stomping: .pounce
        case .sleeping: .sleep
        case .grooming: .groom
        }
    }
}

/// A single animated cat, tinted by its look and flipped to face left or right.
/// `hasRedEyes` makes the eyes glow red; it's only drawn on the idle animation, where the
/// eye pixels are at a known spot.
struct CatSprite: View {
    var look: CatLook
    var animation: CatAnimation
    var facesLeft = false
    var hasRedEyes = false

    var body: some View {
        AnimatedSprite(sheet: animation.sheet, framesPerSecond: animation.framesPerSecond)
            .colorMultiply(look.tint)
            .overlay {
                if hasRedEyes, animation == .idle {
                    RedEyes()
                }
            }
            .scaleEffect(x: facesLeft ? -1 : 1, y: 1)
    }
}

/// Two glowing red pixels over the eyes of the idle cat (Cat0), which sit at about
/// (17, 16) and (20, 16) in its 32×32 frame. Pulses so it reads as a warning.
private struct RedEyes: View {
    private static let eyes = [CGPoint(x: 17.5 / 32, y: 16 / 32), CGPoint(x: 20.5 / 32, y: 16 / 32)]

    var body: some View {
        GeometryReader { proxy in
            let pixel = proxy.size.width / 32
            ForEach(Self.eyes.indices, id: \.self) { index in
                let eye = Self.eyes[index]
                Circle()
                    .fill(.red)
                    .frame(width: pixel * 1.6, height: pixel * 1.6)
                    .position(x: eye.x * proxy.size.width, y: eye.y * proxy.size.height)
            }
            .shadow(color: .red, radius: pixel * 1.5)
            .phaseAnimator([1.0, 0.45]) { content, opacity in
                content.opacity(opacity)
            } animation: { _ in .easeInOut(duration: 0.6) }
        }
        .allowsHitTesting(false)
    }
}

extension CatLook {
    var tint: Color {
        switch self {
        case .hero: .white
        case .ginger: Color(red: 1, green: 0.7, blue: 0.4)
        case .gray: Color(white: 0.7)
        case .black: Color(white: 0.35)
        }
    }
}

/// Places a `CatActor` on the grid and glides it between tiles at its walking speed.
/// `scale` makes it bigger (the kaiju is just the hero cat scaled up).
struct ActorView: View {
    var actor: CatActor
    var metrics: WorldMetrics
    var scale: CGFloat = 1
    var hasRedEyes = false

    /// The cat only fills the middle of its 32×32 frame, so draw the frame larger than a tile.
    static let frameToTile: CGFloat = 2.5

    var body: some View {
        let size = metrics.tileSize * Self.frameToTile * scale
        let cell = metrics.rect(of: actor.position)
        CatSprite(look: actor.look, animation: CatAnimation(actor), facesLeft: actor.facing == .left, hasRedEyes: hasRedEyes)
            .frame(width: size, height: size)
            // Feet on the cell's lower edge; big cats grow upward.
            .position(x: cell.midX, y: cell.maxY - size * 0.3)
            .animation(.linear(duration: actor.stepDuration), value: actor.position)
            .animation(.bouncy, value: scale)
    }
}
