import Foundation

/// Saved snapshot of the city diorama, so progress persists between app sessions.
struct SavedCityState: Codable, Equatable {
    var developedBlocks: [BlockID]
    var lots: [Lot]
    var roads: [GridPoint]
    var cityHealth: Double
    var floorsBuiltCount: Int
    var floorsDestroyedCount: Int
    var blocksDevelopedCount: Int
    var totalFocusSeconds: TimeInterval
    var savedAt: Date
}

enum CityPersistence {
    private static let storageKey = "com.monstersink.city_state_v1"

    static func save(_ state: SavedCityState) {
        do {
            let data = try JSONEncoder().encode(state)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save city state: \(error)")
        }
    }

    static func load() -> SavedCityState? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        do {
            return try JSONDecoder().decode(SavedCityState.self, from: data)
        } catch {
            print("Failed to load city state: \(error)")
            return nil
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
