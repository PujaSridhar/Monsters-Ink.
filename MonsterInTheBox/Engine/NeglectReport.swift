import Foundation

/// Produced when the app returns from the background. Dev A presents it (acid rain replay).
struct NeglectReport: Identifiable, Equatable {
    let id = UUID()
    var secondsAway: TimeInterval
    var healthLost: Double
}
