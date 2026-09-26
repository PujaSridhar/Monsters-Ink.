import SwiftUI

/// Every image in Assets.xcassets. Source files live in /assests.
enum GameAsset: String, CaseIterable {
    /// "Cute Monsters Big Belly Right" — Bite, the chibi architect. Scaled up + tinted = kaiju.
    case bite = "Bite"
    /// "Cute Monsters Blue Drool" — Bite asleep during neglect.
    case biteSleeping = "BiteSleeping"

    case slimeNeutral = "SlimeNeutral"
    case slimeAngry = "SlimeAngry"
    case slimeHurt = "SlimeHurt"
    case batNeutral = "BatNeutral"
    case batAngry = "BatAngry"
    case batHurt = "BatHurt"
    case ratNeutral = "RatNeutral"
    case ratAngry = "RatAngry"
    case ratHurt = "RatHurt"

    /// 32×64 sheet, 2 frames: an empty box, then a cat popping out. The "Monster in the Box" logo.
    case catBox = "CatBox"
    /// Cat animation strips, 32 px wide, 32×32 frames stacked vertically.
    case cat0 = "Cat0"
    case cat1 = "Cat1"
    case cat2 = "Cat2"
    case cat3 = "Cat3"
    case cat4 = "Cat4"
    case cat5 = "Cat5"

    /// Kenney Pico-8 City packed tilemap: 24 × 15 tiles, 8 × 8 px, no spacing.
    case cityTiles = "CityTiles"
    /// Kenney's sample city scene, handy as a title-screen backdrop.
    case citySample = "CitySample"

    static let cats: [GameAsset] = [.cat0, .cat1, .cat2, .cat3, .cat4, .cat5]
}
