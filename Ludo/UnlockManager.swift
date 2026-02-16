import Foundation

struct UnlockManager {
    private static let unlockedPawnsKey = "unlockedPawnsKey"
    private static let coinBalanceKey = "coinBalanceKey"
    static let unlockStepCost = 2500

    // Level 1 first (R, Y, G, B), then Level 2 in same sequence.
    static let unlockProgression: [String] = [
        PawnAssets.redTomato,
        PawnAssets.yellowMango,
        PawnAssets.greenCapsicum,
        PawnAssets.blueAubergine,
        PawnAssets.redAnar,
        PawnAssets.yellowPineapple,
        PawnAssets.greenWatermelon,
        PawnAssets.blueJamun
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
        // Level 0 pawns are always available.
        guard PawnAssets.hasBoost(for: pawnName) else { return false }
        return !getUnlockedPawns().contains(pawnName)
    }

    static func getNextUnlockablePawn() -> String? {
        let unlocked = getUnlockedPawns()
        return unlockProgression.first(where: { !unlocked.contains($0) })
    }

    static func getUpcomingUnlockablePawns(limit: Int) -> [String] {
        guard limit > 0 else { return [] }
        let unlocked = getUnlockedPawns()
        return unlockProgression
            .filter { !unlocked.contains($0) }
            .prefix(limit)
            .map { $0 }
    }

    static func unlockCost(for pawnName: String) -> Int {
        unlockProgression.contains(pawnName) ? unlockStepCost : 0
    }

    static func progressTowardNextClaim(for coinBalance: Int? = nil) -> (current: Int, target: Int) {
        let coins = max(0, coinBalance ?? getCoinBalance())
        let target = ((coins / unlockStepCost) + 1) * unlockStepCost
        return (coins, max(unlockStepCost, target))
    }

    static func canClaimNextPawn(for coinBalance: Int? = nil) -> Bool {
        let coins = max(0, coinBalance ?? getCoinBalance())
        return getNextUnlockablePawn() != nil && coins >= unlockStepCost
    }

    @discardableResult
    static func claimNextUnlockablePawn() -> String? {
        guard let pawn = getNextUnlockablePawn() else { return nil }
        guard canClaimNextPawn() else { return nil }
        unlockPawn(pawn)
        setCoinBalance(getCoinBalance() - unlockStepCost)
        return pawn
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
