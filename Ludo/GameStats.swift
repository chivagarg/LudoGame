import Foundation

struct GameStats {
    private static let gameCompletionCountKey = "gameCompletionCount"

    static func incrementGameCompletionCount() {
        let currentCount = getGameCompletionCount()
        UserDefaults.standard.set(currentCount + 1, forKey: gameCompletionCountKey)
    }

    static func getGameCompletionCount() -> Int {
        return UserDefaults.standard.integer(forKey: gameCompletionCountKey)
    }

    static func setGameCompletionCount(_ count: Int) {
        UserDefaults.standard.set(count, forKey: gameCompletionCountKey)
    }
}
