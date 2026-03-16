import Foundation

struct UnlockManager {
    private static let unlockedPawnsKey = "unlockedPawnsKey"
    private static let coinBalanceKey = "coinBalanceKey"

    // Level 0 variants first, then Level 1 (R, Y, G, B), then Level 2 in same sequence.
    static let unlockProgression: [String] = [
        PawnAssets.redStrawberry,
        PawnAssets.yellowBanana,
        PawnAssets.greenKiwi,
        PawnAssets.blueGrape,
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

    static func resetAllPawnUnlocks() {
        UserDefaults.standard.set([], forKey: unlockedPawnsKey)
    }

    static func isPawnLocked(_ pawnName: String) -> Bool {
        // Only pawns present in progression are lockable; default marbles remain always available.
        guard unlockProgression.contains(pawnName) else { return false }
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

    /// Coin cost to earn (free) unlock for a specific pawn.
    static func unlockCost(for pawnName: String) -> Int {
        guard unlockProgression.contains(pawnName) else { return 0 }
        return CoinPurchaseConfig.unlockCost(for: pawnName)
    }

    static func progressTowardNextClaim(for coinBalance: Int? = nil) -> (current: Int, target: Int) {
        let coins = max(0, coinBalance ?? getCoinBalance())
        guard let nextPawn = getNextUnlockablePawn() else {
            return (coins, max(1, coins))
        }
        let target = unlockCost(for: nextPawn)
        return (coins, max(1, target))
    }

    static func canClaimNextPawn(for coinBalance: Int? = nil) -> Bool {
        let coins = max(0, coinBalance ?? getCoinBalance())
        guard let nextPawn = getNextUnlockablePawn() else { return false }
        return coins >= unlockCost(for: nextPawn)
    }

    @discardableResult
    static func claimNextUnlockablePawn() -> String? {
        guard let pawn = getNextUnlockablePawn() else { return nil }
        guard canClaimNextPawn() else { return nil }
        unlockPawn(pawn)
        setCoinBalance(getCoinBalance() - unlockCost(for: pawn))
        return pawn
    }

    // MARK: - Purchase unlock (independent, any pawn, uses CoinPurchaseConfig cost)

    /// Unlocks `pawnName` directly and deducts its purchase cost from the coin balance.
    /// Does NOT require sequential order — any locked pawn can be purchased independently.
    @discardableResult
    static func purchaseUnlockPawn(_ pawnName: String) -> Bool {
        let cost = CoinPurchaseConfig.unlockCost(for: pawnName)
        guard getCoinBalance() >= cost else { return false }
        unlockPawn(pawnName)
        setCoinBalance(getCoinBalance() - cost)
        return true
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
