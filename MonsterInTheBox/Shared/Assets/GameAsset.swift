import SwiftUI

/// Every image in Assets.xcassets. Source files live in /assests.
enum GameAsset: String, CaseIterable {
    case slimeNeutral = "SlimeNeutral"
    case slimeAngry = "SlimeAngry"
    case slimeHurt = "SlimeHurt"
    case batNeutral = "BatNeutral"
    case batAngry = "BatAngry"
    case batHurt = "BatHurt"
    case ratNeutral = "RatNeutral"
    case ratAngry = "RatAngry"
    case ratHurt = "RatHurt"

    /// 32×64 sheet, 2 frames: an empty box, then a cat popping out. The app logo.
    case catBox = "CatBox"
    /// Cat animation strips, 32 px wide, 32×32 frames stacked vertically. See `CatAnimation`.
    case cat0 = "Cat0" // idle, tail swish (4 frames)
    case cat1 = "Cat1" // sit → lie down to sleep (7 frames)
    case cat2 = "Cat2" // stepping, used as the walk cycle (6 frames)
    case cat3 = "Cat3" // pounce, used for hammering and stomping (6 frames)
    case cat4 = "Cat4" // grooming / stretching (26 frames)
    case cat5 = "Cat5" // icons: arrow, small paw, big paw (3 frames)

    /// Kenney Pico-8 City packed tilemap: 24 × 15 tiles, 8 × 8 px, no spacing.
    case cityTiles = "CityTiles"
    /// Kenney's sample city scene, handy as a title-screen backdrop.
    case citySample = "CitySample"
}
