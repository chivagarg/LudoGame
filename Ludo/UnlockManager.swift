import Foundation

// MARK: - Pawn packs (four pawns each; coin OR mock IAP per pack)

enum PawnPack: String, CaseIterable, Codable, Identifiable, Hashable {
    case fruitBasket
    case fruitPunch
    case fruitChaat

    var id: String { rawValue }

    static let ordered: [PawnPack] = [.fruitBasket, .fruitPunch, .fruitChaat]

    var displayName: String {
        switch self {
        case .fruitBasket: return "Fruit Basket Pack"
        case .fruitPunch: return "Fruit Punch Pack"
        case .fruitChaat: return "Fruit Chaat Pack"
        }
    }

    var pawnAssetNames: [String] {
        switch self {
        case .fruitBasket:
            return [PawnAssets.redStrawberry, PawnAssets.yellowBanana, PawnAssets.greenKiwi, PawnAssets.blueGrape]
        case .fruitPunch:
            return [PawnAssets.redTomato, PawnAssets.yellowMango, PawnAssets.greenCapsicum, PawnAssets.blueAubergine]
        case .fruitChaat:
            return [PawnAssets.redAnar, PawnAssets.yellowPineapple, PawnAssets.greenWatermelon, PawnAssets.blueJamun]
        }
    }

    var coinCost: Int {
        switch self {
        case .fruitBasket: return 2000
        case .fruitPunch: return 6000
        case .fruitChaat: return 9000
        }
    }

    var mockIAPPrice: Double {
        switch self {
        case .fruitBasket: return 2.99
        case .fruitPunch: return 6.99
        case .fruitChaat: return 9.99
        }
    }

    var formattedMockIAPPrice: String {
        String(format: "$%.2f", mockIAPPrice)
    }

    static func pack(containing pawnName: String) -> PawnPack? {
        for p in ordered where p.pawnAssetNames.contains(pawnName) {
            return p
        }
        return nil
    }
}

struct UnlockManager {
    private static let unlockedPawnsKey = "unlockedPawnsKey"
    private static let coinBalanceKey = "coinBalanceKey"
    private static let completedPacksKey = "completedPawnPacksKey"
    private static let unlockSchemaVersionKey = "pawnUnlockSchemaVersion"
    private static let unlockSchemaVersion = 2

    /// Flattened progression order (used for lock eligibility).
    static let unlockProgression: [String] = PawnPack.ordered.flatMap(\.pawnAssetNames)

    private static func ensurePackSchemaMigrated() {
        let v = UserDefaults.standard.integer(forKey: unlockSchemaVersionKey)
        guard v < unlockSchemaVersion else { return }
        UserDefaults.standard.set([], forKey: unlockedPawnsKey)
        UserDefaults.standard.set([], forKey: completedPacksKey)
        UserDefaults.standard.set(unlockSchemaVersion, forKey: unlockSchemaVersionKey)
    }

    private static func completedPackRawValues() -> Set<String> {
        ensurePackSchemaMigrated()
        return Set(UserDefaults.standard.stringArray(forKey: completedPacksKey) ?? [])
    }

    private static func markPackCompleted(_ pack: PawnPack) {
        var s = completedPackRawValues()
        s.insert(pack.rawValue)
        UserDefaults.standard.set(s.sorted(), forKey: completedPacksKey)
    }

    static func isPackUnlocked(_ pack: PawnPack) -> Bool {
        completedPackRawValues().contains(pack.rawValue)
    }

    /// Next pack in order that is not yet completed (coin path is sequential on this pack only).
    static func nextIncompletePack() -> PawnPack? {
        PawnPack.ordered.first { !isPackUnlocked($0) }
    }

    /// Incomplete packs in order (skips any pack already completed, e.g. via IAP out of order).
    static func getUpcomingIncompletePacks(limit: Int) -> [PawnPack] {
        guard limit > 0 else { return [] }
        ensurePackSchemaMigrated()
        let incomplete = PawnPack.ordered.filter { !isPackUnlocked($0) }
        return Array(incomplete.prefix(limit))
    }

    static func getUnlockedPawns() -> Set<String> {
        ensurePackSchemaMigrated()
        let saved = UserDefaults.standard.stringArray(forKey: unlockedPawnsKey) ?? []
        var unlocked = Set(saved)

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
        UserDefaults.standard.set([], forKey: completedPacksKey)
        UserDefaults.standard.set(unlockSchemaVersion, forKey: unlockSchemaVersionKey)
    }

    static func isPawnLocked(_ pawnName: String) -> Bool {
        guard unlockProgression.contains(pawnName) else { return false }
        guard let pack = PawnPack.pack(containing: pawnName) else { return false }
        return !isPackUnlocked(pack)
    }

    /// Coin cost shown on a locked pawn tile (full pack price; same for any pawn in that pack).
    static func packCoinCost(forLockedPawn pawnName: String) -> Int {
        guard isPawnLocked(pawnName) else { return 0 }
        return PawnPack.pack(containing: pawnName)?.coinCost ?? 0
    }

    static func progressTowardNextClaim(for coinBalance: Int? = nil) -> (current: Int, target: Int) {
        let coins = max(0, coinBalance ?? getCoinBalance())
        guard let pack = nextIncompletePack() else {
            return (coins, max(1, coins))
        }
        return (coins, max(1, pack.coinCost))
    }

    static func canClaimNextPack(for coinBalance: Int? = nil) -> Bool {
        let coins = max(0, coinBalance ?? getCoinBalance())
        guard let pack = nextIncompletePack() else { return false }
        return coins >= pack.coinCost
    }

    @discardableResult
    static func claimNextUnlockablePack() -> PawnPack? {
        guard let pack = nextIncompletePack() else { return nil }
        guard getCoinBalance() >= pack.coinCost else { return nil }
        unlockPackCore(pack, deductCoins: pack.coinCost)
        return pack
    }

    /// Mock IAP: unlocks the whole pack without spending coins. Any pack, any time (no ordering).
    @discardableResult
    static func unlockPackViaIAPMock(_ pack: PawnPack) -> Bool {
        ensurePackSchemaMigrated()
        guard !isPackUnlocked(pack) else { return false }
        unlockPackCore(pack, deductCoins: nil)
        return true
    }

    private static func unlockPackCore(_ pack: PawnPack, deductCoins: Int?) {
        if let c = deductCoins {
            setCoinBalance(getCoinBalance() - c)
        }
        for name in pack.pawnAssetNames {
            unlockPawn(name)
        }
        markPackCompleted(pack)
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
