import Foundation

/// The six game states from the spec's Global State Logic table.
/// The engine derives this from the hinge, screen mode, and scene phase. Views only read it.
/// Mode-specific extras live next to each mode (e.g. `GameState.catMood` in Open/Logic).
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
        case .incubation: "The cat is building your city"
        case .warning: "Every cat is watching you. Close the phone."
        case .agitation: "The cat is growing… and smashing"
        case .rampage: "KAIJU CAT UNLEASHED"
        case .neglect: "Acid rain falls on the city"
        case .multitasking: "Split screen woke the kaiju cat"
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

    /// Which brain runs this state.
    var mode: GameMode {
        switch self {
        case .incubation: .building
        case .warning, .agitation, .rampage, .multitasking: .destroying
        case .neglect: .paused
        }
    }

    /// Floors knocked down per second.
    var floorsDestroyedPerSecond: Double {
        switch self {
        case .incubation, .neglect: 0
        case .warning: GameTuning.warningFloorsPerSecond
        case .agitation: GameTuning.agitationFloorsPerSecond
        case .rampage, .multitasking: GameTuning.rampageFloorsPerSecond
        }
    }

    var isDestructive: Bool { floorsDestroyedPerSecond > 0 }

    /// Warning: every cat stops and stares at the user.
    var freezesCitizens: Bool { self == .warning }

    /// The hero cat is drawn giant in these states.
    var isKaiju: Bool { self == .rampage || self == .multitasking }
}

enum GameMode {
    case building
    case destroying
    case paused
}
