import Foundation

struct UnlockManager {
    private static let unlockedPawnsKey = "unlockedPawnsKey"
    private static let coinBalanceKey = "coinBalanceKey"
    static let gamesPerUnlock = 10

    static let unlockProgression: [String] = [
        PawnAssets.yellowMango,
        PawnAssets.redTomato,
        PawnAssets.greenMango
    ]

    static func getUnlockedPawns() -> Set<String> {
        let saved = UserDefaults.standard.stringArray(forKey: unlockedPawnsKey) ?? []
        var unlocked = Set(saved)
        
        // Migration: Treat deprecated redMirchi as redTomato
        if unlocked.contains(PawnAssets.redMirchi) {
            unlocked.remove(PawnAssets.redMirchi)
            unlocked.insert(PawnAssets.redTomato)
        }
        
        return unlocked
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

    static func checkForUnlocks() -> [String] {
        let totalGamesCompleted = GameStats.getGameCompletionCount()
        let unlockedCount = getUnlockedPawns().count
        let expectedUnlockedCount = totalGamesCompleted / gamesPerUnlock
        var newlyUnlocked: [String] = []

        if expectedUnlockedCount > unlockedCount {
            for i in unlockedCount..<expectedUnlockedCount {
                if i < unlockProgression.count {
                    let pawnToUnlock = unlockProgression[i]
                    unlockPawn(pawnToUnlock)
                    newlyUnlocked.append(pawnToUnlock)
                }
            }
        }
        return newlyUnlocked
    }

    static func getCurrentProgress() -> (current: Int, max: Int) {
        let totalGamesCompleted = GameStats.getGameCompletionCount()
        let unlockedCount = getUnlockedPawns().count
        let progressSinceLastUnlock = totalGamesCompleted - (unlockedCount * gamesPerUnlock)
        return (progressSinceLastUnlock, gamesPerUnlock)
    }

    // MARK: - Coin system
    static func getCoinBalance() -> Int {
        max(0, UserDefaults.standard.integer(forKey: coinBalanceKey))
    }

    static func setCoinBalance(_ newValue: Int) {
        UserDefaults.standard.set(max(0, newValue), forKey: coinBalanceKey)
    }

    static func addCoins(_ amount: Int) {
        guard amount > 0 else { return }
        setCoinBalance(getCoinBalance() + amount)
    }
}
