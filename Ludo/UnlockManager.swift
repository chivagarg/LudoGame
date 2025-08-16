import Foundation

struct UnlockManager {
    private static let unlockedPawnsKey = "unlockedPawnsKey"
    static let gamesPerUnlock = 10

    static let unlockProgression: [String] = [
        "pawn_mango",
        "pawn_mirchi",
        "pawn_mango_green"
    ]

    static func getUnlockedPawns() -> Set<String> {
        let saved = UserDefaults.standard.stringArray(forKey: unlockedPawnsKey) ?? []
        return Set(saved)
    }

    static func unlockPawn(_ pawnName: String) {
        var unlocked = getUnlockedPawns()
        unlocked.insert(pawnName)
        UserDefaults.standard.set(Array(unlocked), forKey: unlockedPawnsKey)
    }

    static func isPawnLocked(_ pawnName: String) -> Bool {
        let specialPawns = Set(unlockProgression)
        if !specialPawns.contains(pawnName) {
            return false
        }
        return !getUnlockedPawns().contains(pawnName)
    }

    static func getNextUnlockablePawn() -> String? {
        let unlockedCount = getUnlockedPawns().count
        if unlockedCount < unlockProgression.count {
            return unlockProgression[unlockedCount]
        }
        return nil
    }

    static func checkForUnlocks() {
        let totalGamesCompleted = GameStats.getGameCompletionCount()
        let unlockedCount = getUnlockedPawns().count
        let expectedUnlockedCount = totalGamesCompleted / gamesPerUnlock

        if expectedUnlockedCount > unlockedCount {
            for i in unlockedCount..<expectedUnlockedCount {
                if i < unlockProgression.count {
                    unlockPawn(unlockProgression[i])
                }
            }
        }
    }

    static func getCurrentProgress() -> (current: Int, max: Int) {
        let totalGamesCompleted = GameStats.getGameCompletionCount()
        let unlockedCount = getUnlockedPawns().count
        let progressSinceLastUnlock = totalGamesCompleted - (unlockedCount * gamesPerUnlock)
        return (progressSinceLastUnlock, gamesPerUnlock)
    }
}
