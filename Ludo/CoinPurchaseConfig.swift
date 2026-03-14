import Foundation

// MARK: - Coin purchase pricing config

enum CoinPurchaseConfig {
    /// Number of coins in one purchasable unit.
    static let coinsPerUnit: Int = 1000

    /// USD price for one unit of coins.
    static let pricePerUnit: Double = 0.99

    /// Cost (in coins) to unlock each specific pawn via purchase.
    /// All unspecified pawns in the progression default to `defaultUnlockCost`.
    private static let perPawnCost: [String: Int] = [
        PawnAssets.redTomato:       2500,
        PawnAssets.yellowMango:     2500,
        PawnAssets.greenCapsicum:   2500,
        PawnAssets.blueAubergine:   2500,
        PawnAssets.redAnar:         2500,
        PawnAssets.yellowPineapple: 2500,
        PawnAssets.greenWatermelon: 2500,
        PawnAssets.blueJamun:       2500,
    ]

    static let defaultUnlockCost: Int = 2500

    /// Coin cost to unlock the given pawn via purchase.
    static func unlockCost(for pawnName: String) -> Int {
        perPawnCost[pawnName] ?? defaultUnlockCost
    }

    // MARK: - Purchase calculation helpers

    /// How many coins the user still needs beyond their current balance to unlock `pawnName`.
    static func coinsNeeded(currentBalance: Int, pawnName: String) -> Int {
        max(0, unlockCost(for: pawnName) - currentBalance)
    }

    /// Number of purchasable units required to cover the deficit.
    static func unitsToBuy(currentBalance: Int, pawnName: String) -> Int {
        let needed = coinsNeeded(currentBalance: currentBalance, pawnName: pawnName)
        // Round up to the nearest whole unit.
        return (needed + coinsPerUnit - 1) / coinsPerUnit
    }

    /// Total coins that will be purchased (always a multiple of `coinsPerUnit`).
    static func coinsToBuy(currentBalance: Int, pawnName: String) -> Int {
        unitsToBuy(currentBalance: currentBalance, pawnName: pawnName) * coinsPerUnit
    }

    /// Total USD price for the required purchase.
    static func totalPrice(currentBalance: Int, pawnName: String) -> Double {
        Double(unitsToBuy(currentBalance: currentBalance, pawnName: pawnName)) * pricePerUnit
    }

    /// Formatted price string, e.g. "$2.97".
    static func formattedPrice(currentBalance: Int, pawnName: String) -> String {
        let price = totalPrice(currentBalance: currentBalance, pawnName: pawnName)
        return String(format: "$%.2f", price)
    }

    // MARK: - Direct unlock pricing (no coin top-up flow)

    /// Number of purchasable units implied by a pawn's unlock cost.
    /// Example: 2500 coin-equivalent cost => 3 units.
    static func unitsForDirectUnlock(pawnName: String) -> Int {
        let cost = unlockCost(for: pawnName)
        return max(1, (cost + coinsPerUnit - 1) / coinsPerUnit)
    }

    /// Direct purchase price for unlocking a pawn now.
    static func directUnlockPrice(pawnName: String) -> Double {
        Double(unitsForDirectUnlock(pawnName: pawnName)) * pricePerUnit
    }

    /// Formatted direct unlock price string, e.g. "$2.97".
    static func formattedDirectUnlockPrice(pawnName: String) -> String {
        String(format: "$%.2f", directUnlockPrice(pawnName: pawnName))
    }
}
