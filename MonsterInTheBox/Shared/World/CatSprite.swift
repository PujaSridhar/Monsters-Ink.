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
struct CatSprite: View {
    var look: CatLook
    var animation: CatAnimation
    var facesLeft = false

    var body: some View {
        AnimatedSprite(sheet: animation.sheet, framesPerSecond: animation.framesPerSecond)
            .colorMultiply(look.tint)
            .scaleEffect(x: facesLeft ? -1 : 1, y: 1)
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

    /// The cat only fills the middle of its 32×32 frame, so draw the frame larger than a tile.
    static let frameToTile: CGFloat = 2.5

    var body: some View {
        let size = metrics.tileSize * Self.frameToTile * scale
        let cell = metrics.rect(of: actor.position)
        CatSprite(look: actor.look, animation: CatAnimation(actor), facesLeft: actor.facing == .left)
            .frame(width: size, height: size)
            // Feet on the cell's lower edge; big cats grow upward.
            .position(x: cell.midX, y: cell.maxY - size * 0.3)
            .animation(.linear(duration: actor.stepDuration), value: actor.position)
            .animation(.bouncy, value: scale)
    }
}
