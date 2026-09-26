import Foundation

/// Bite's sidekicks from "Sprite Pack Monsters A". Each species has three mood sprites.
struct Minion: Equatable {
    var species: Species
    var mood: Mood

    var asset: GameAsset {
        switch (species, mood) {
        case (.slime, .neutral): .slimeNeutral
        case (.slime, .angry): .slimeAngry
        case (.slime, .hurt): .slimeHurt
        case (.bat, .neutral): .batNeutral
        case (.bat, .angry): .batAngry
        case (.bat, .hurt): .batHurt
        case (.rat, .neutral): .ratNeutral
        case (.rat, .angry): .ratAngry
        case (.rat, .hurt): .ratHurt
        }
    }

    enum Species: String, CaseIterable {
        case slime
        case bat
        case rat
    }

    enum Mood: String, CaseIterable {
        case neutral
        case angry
        case hurt
    }
}
