import Foundation

/// The six game states from the spec's Global State Logic table.
/// The engine derives this from the hinge, screen mode, and scene phase. Views only read it.
enum GameState: String, CaseIterable, Identifiable {
    case incubation
    case warning
    case agitation
    case rampage
    case neglect
    case multitasking

    var id: Self { self }

    var title: String {
        switch self {
        case .incubation: "Incubation"
        case .warning: "Warning"
        case .agitation: "Agitation"
        case .rampage: "Rampage"
        case .neglect: "Neglect"
        case .multitasking: "Multitasking Trap"
        }
    }

    var subtitle: String {
        switch self {
        case .incubation: "Bite is building your city"
        case .warning: "Something is peeking out of the box…"
        case .agitation: "The cat is NOT happy"
        case .rampage: "KAIJU UNLEASHED"
        case .neglect: "Acid rain falls on the city"
        case .multitasking: "Split screen woke the kaiju"
        }
    }

    var monsterForm: MonsterForm {
        switch self {
        case .incubation: .peaceful
        case .warning: .peeking
        case .agitation: .erratic
        case .rampage, .multitasking: .kaiju
        case .neglect: .sleeping
        }
    }

    /// City health points removed per second while in this state.
    var destructionPerSecond: Double {
        switch self {
        case .incubation, .neglect: 0
        case .warning: GameTuning.warningDamagePerSecond
        case .agitation: GameTuning.agitationDamagePerSecond
        case .rampage, .multitasking: GameTuning.rampageDamagePerSecond
        }
    }

    var isDestructive: Bool { destructionPerSecond > 0 }

    /// The cat in the box that begs you not to open the phone. Nil once the kaiju is out.
    var catMood: CatMood? {
        switch self {
        case .warning: .pleading
        case .agitation: .annoyed
        default: nil
        }
    }

    /// Which minion from "Sprite Pack Monsters A" shows up alongside Bite.
    var minion: Minion? {
        switch self {
        case .incubation: nil
        case .warning: Minion(species: .bat, mood: .neutral)
        case .agitation: Minion(species: .rat, mood: .angry)
        case .rampage, .multitasking: Minion(species: .slime, mood: .angry)
        case .neglect: Minion(species: .slime, mood: .hurt)
        }
    }

    var symbolName: String {
        switch self {
        case .incubation: "hammer.fill"
        case .warning: "eye.fill"
        case .agitation: "exclamationmark.triangle.fill"
        case .rampage: "flame.fill"
        case .neglect: "cloud.rain.fill"
        case .multitasking: "rectangle.split.2x1.fill"
        }
    }
}

enum MonsterForm: String {
    case peaceful
    case peeking
    case erratic
    case kaiju
    case sleeping
}
