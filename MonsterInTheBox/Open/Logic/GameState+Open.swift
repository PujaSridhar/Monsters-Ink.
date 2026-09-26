import Foundation

/// Open-phone extras on `GameState`. Kept in Open/ so Dev B can change them freely.
extension GameState {
    /// The cat in the box that begs you not to open the phone. Nil once the kaiju is out.
    var catMood: CatMood? {
        switch self {
        case .warning: .pleading
        case .agitation: .annoyed
        default: nil
        }
    }

    /// Which minion from "Sprite Pack Monsters A" shows up in the Monster Nest.
    var minion: Minion? {
        switch self {
        case .warning: Minion(species: .bat, mood: .neutral)
        case .agitation: Minion(species: .rat, mood: .angry)
        case .rampage, .multitasking: Minion(species: .slime, mood: .angry)
        case .incubation, .neglect: nil
        }
    }
}
