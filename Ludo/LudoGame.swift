import Foundation

enum GameMode: String, CaseIterable, Identifiable {
    case classic = "Classic"
    case mirchi = "Mirchi"
    var id: String { rawValue }
}

struct Position: Equatable, Hashable {
    var row: Int
    var col: Int
}

class LudoGame: ObservableObject {
    
    @Published var currentPlayer: PlayerColor = .red
    @Published var diceValue: Int = 1
    @Published var rollID: Int = 0 // A counter that increments on each roll to trigger animations
    @Published var gameStarted: Bool = false
    @Published var eligiblePawns: Set<Int> = []  // Track which pawns are eligible to move
    @Published var currentRollPlayer: PlayerColor? = nil  // Track whose roll is currently active
    @Published var scores: [PlayerColor: Int] = [.red: 0, .green: 0, .yellow: 0, .blue: 0]  // Track scores
    @Published var homeCompletionOrder: [PlayerColor] = []  // Track order of pawns reaching home
    @Published var totalPawnsAtFinishingHome: Int = 0  // Track total number of pawns that have reached home
    @Published var isAdminMode: Bool = false  // Whether admin mode is enabled
    @Published var isGameOver: Bool = false  // Whether the game is over
    @Published var finalRankings: [PlayerColor] = []  // Track final player rankings
    @Published var selectedPlayers: Set<PlayerColor> = []
    @Published var aiControlledPlayers: Set<PlayerColor> = []
    @Published var gameMode: GameMode = .classic
    @Published var mirchiArrowActivated: [PlayerColor: Bool] = [:]
    
    // Error state for UI feedback
    @Published var errorMessage: String? = nil
    @Published var showError: Bool = false
    
    // Custom safe zones created by players via boosts.
    // Stores positions that are now considered safe for all players.
    @Published var customSafeZones: Set<Position> = []
    
    // Trapped zones created by the Blue Aubergine boost
    @Published var trappedZones: Set<Position> = []
    
    // MARK: - Boost (pawn abilities)
    // State machine per player: available ↔ armed, and used when no charges remain.
    @Published var boostState: [PlayerColor: BoostState] = [:]
    @Published var boostUsesRemaining: [PlayerColor: Int] = [:]

    // Remaining Mirchi (backward) moves per player
    @Published var mirchiMovesRemaining: [PlayerColor: Int] = [.red: 5, .green: 5, .yellow: 5, .blue: 5]

    // Track number of pawns each player has captured
    @Published var killCounts: [PlayerColor: Int] = [.red: 0, .green: 0, .yellow: 0, .blue: 0]

    // Track if first blood has happened
    private var firstKillDone: Bool = false
    @Published var firstKillPlayer: PlayerColor? = nil

    // History of dice rolls per player (in order). Can be used for stats like killing spree/unluckiest player.
    @Published var diceRollHistory: [PlayerColor: [Int]] = [.red: [], .green: [], .yellow: [], .blue: []]

    // AI Player Configuration
    private var aiStrategies: [PlayerColor: AILogicStrategy] = [:]

    // Busy state for blocking moves/rolls during animation
    // E.g. when a pawn is being captured, we don't want to allow the player to roll the dice or move the pawn
    @Published var isBusy: Bool = false
    @Published var coins: Int = UnlockManager.getCoinBalance()
    @Published var coinBalanceBeforeLastAward: Int = UnlockManager.getCoinBalance()
    @Published var lastCoinAward: Int = 0

    // Award coins exactly once per completed game.
    private var didAwardCoinsForCurrentGame: Bool = false

    // Safe zones and home for each color
    static let redSafeZone: [Position] = [
        Position(row: 7, col: 1), Position(row: 7, col: 2), Position(row: 7, col: 3), Position(row: 7, col: 4), Position(row: 7, col: 5)
    ]
    static let redHome = Position(row: 7, col: 6)

    static let greenSafeZone: [Position] = [
        Position(row: 1, col: 7), Position(row: 2, col: 7), Position(row: 3, col: 7), Position(row: 4, col: 7), Position(row: 5, col: 7)
    ]
    static let greenHome = Position(row: 6, col: 7)

    static let yellowSafeZone: [Position] = [
        Position(row: 7, col: 13), Position(row: 7, col: 12), Position(row: 7, col: 11), Position(row: 7, col: 10), Position(row: 7, col: 9)
    ]
    static let yellowHome = Position(row: 7, col: 8)

    static let blueSafeZone: [Position] = [
        Position(row: 13, col: 7), Position(row: 12, col: 7), Position(row: 11, col: 7), Position(row: 10, col: 7), Position(row: 9, col: 7)
    ]
    static let blueHome = Position(row: 8, col: 7)

    // For each color, define their complete path from entry to home
    static let redPath: [Position] = [
        Position(row: 6, col: 1), Position(row: 6, col: 2), Position(row: 6, col: 3), Position(row: 6, col: 4), Position(row: 6, col: 5),
        Position(row: 5, col: 6), Position(row: 4, col: 6), Position(row: 3, col: 6), Position(row: 2, col: 6), Position(row: 1, col: 6), Position(row: 0, col: 6),
        Position(row: 0, col: 7), Position(row: 0, col: 8),
        Position(row: 1, col: 8), Position(row: 2, col: 8), Position(row: 3, col: 8), Position(row: 4, col: 8), Position(row: 5, col: 8),
        Position(row: 6, col: 9), Position(row: 6, col: 10), Position(row: 6, col: 11), Position(row: 6, col: 12), Position(row: 6, col: 13), Position(row: 6, col: 14),
        Position(row: 7, col: 14), Position(row: 8, col: 14),
        Position(row: 8, col: 13), Position(row: 8, col: 12), Position(row: 8, col: 11), Position(row: 8, col: 10), Position(row: 8, col: 9),
        Position(row: 9, col: 8), Position(row: 10, col: 8), Position(row: 11, col: 8), Position(row: 12, col: 8), Position(row: 13, col: 8), Position(row: 14, col: 8),
        Position(row: 14, col: 7), Position(row: 14, col: 6),
        Position(row: 13, col: 6), Position(row: 12, col: 6), Position(row: 11, col: 6), Position(row: 10, col: 6), Position(row: 9, col: 6),
        Position(row: 8, col: 5), Position(row: 8, col: 4), Position(row: 8, col: 3), Position(row: 8, col: 2), Position(row: 8, col: 1), Position(row: 8, col: 0),
        Position(row: 7, col: 0), // End of main path loop for Red
        Position(row: 7, col: 1), Position(row: 7, col: 2), Position(row: 7, col: 3), Position(row: 7, col: 4), Position(row: 7, col: 5), // Red Safe Zone
        Position(row: 7, col: 6) // Red Home
    ]

    static let greenPath: [Position] = [
        // Start at entry point
        Position(row: 1, col: 8), Position(row: 2, col: 8), Position(row: 3, col: 8), Position(row: 4, col: 8), Position(row: 5, col: 8),
        // Right
        Position(row: 6, col: 9), Position(row: 6, col: 10), Position(row: 6, col: 11), Position(row: 6, col: 12), Position(row: 6, col: 13), Position(row: 6, col: 14),
        // Down
        Position(row: 7, col: 14), Position(row: 8, col: 14),
        // Left
        Position(row: 8, col: 13), Position(row: 8, col: 12), Position(row: 8, col: 11), Position(row: 8, col: 10), Position(row: 8, col: 9),
        // Down
        Position(row: 9, col: 8), Position(row: 10, col: 8), Position(row: 11, col: 8), Position(row: 12, col: 8), Position(row: 13, col: 8), Position(row: 14, col: 8),
        // Left
        Position(row: 14, col: 7), Position(row: 14, col: 6),
        // Up
        Position(row: 13, col: 6), Position(row: 12, col: 6), Position(row: 11, col: 6), Position(row: 10, col: 6), Position(row: 9, col: 6),
        // Left
        Position(row: 8, col: 5), Position(row: 8, col: 4), Position(row: 8, col: 3), Position(row: 8, col: 2), Position(row: 8, col: 1), Position(row: 8, col: 0),
        // Up
        Position(row: 7, col: 0), Position(row: 6, col: 0),
        // Right
        Position(row: 6, col: 1), Position(row: 6, col: 2), Position(row: 6, col: 3), Position(row: 6, col: 4), Position(row: 6, col: 5),
        // Up
        Position(row: 5, col: 6), Position(row: 4, col: 6), Position(row: 3, col: 6), Position(row: 2, col: 6), Position(row: 1, col: 6), Position(row: 0, col: 6),
        // Right
        Position(row: 0, col: 7), // End of main path loop for Green
        Position(row: 1, col: 7), Position(row: 2, col: 7), Position(row: 3, col: 7), Position(row: 4, col: 7), Position(row: 5, col: 7), // Green Safe Zone
        Position(row: 6, col: 7) // Green Home
    ]

    static let yellowPath: [Position] = [
        // Left
        Position(row: 8, col: 13), Position(row: 8, col: 12), Position(row: 8, col: 11), Position(row: 8, col: 10), Position(row: 8, col: 9),
        // Down
        Position(row: 9, col: 8), Position(row: 10, col: 8), Position(row: 11, col: 8), Position(row: 12, col: 8), Position(row: 13, col: 8), Position(row: 14, col: 8),
        // Left
        Position(row: 14, col: 7), Position(row: 14, col: 6),
        // Up
        Position(row: 13, col: 6), Position(row: 12, col: 6), Position(row: 11, col: 6), Position(row: 10, col: 6), Position(row: 9, col: 6),
        // Left
        Position(row: 8, col: 5), Position(row: 8, col: 4), Position(row: 8, col: 3), Position(row: 8, col: 2), Position(row: 8, col: 1), Position(row: 8, col: 0),
        // Up
        Position(row: 7, col: 0), Position(row: 6, col: 0),
        // Right
        Position(row: 6, col: 1), Position(row: 6, col: 2), Position(row: 6, col: 3), Position(row: 6, col: 4), Position(row: 6, col: 5),
        // Up
        Position(row: 5, col: 6), Position(row: 4, col: 6), Position(row: 3, col: 6), Position(row: 2, col: 6), Position(row: 1, col: 6), Position(row: 0, col: 6),
        // Right
        Position(row: 0, col: 7), Position(row: 0, col: 8),
        // Down
        Position(row: 1, col: 8), Position(row: 2, col: 8), Position(row: 3, col: 8), Position(row: 4, col: 8), Position(row: 5, col: 8),
        // Right
        Position(row: 6, col: 9), Position(row: 6, col: 10), Position(row: 6, col: 11), Position(row: 6, col: 12), Position(row: 6, col: 13), Position(row: 6, col: 14),
        // Down
        Position(row: 7, col: 14),  // End of main path loop for Yellow
        Position(row: 7, col: 13), Position(row: 7, col: 12), Position(row: 7, col: 11), Position(row: 7, col: 10), Position(row: 7, col: 9), // Yellow Safe Zone
        Position(row: 7, col: 8) // Yellow Home
    ]

    static let bluePath: [Position] = [
        // Up
        Position(row: 13, col: 6), Position(row: 12, col: 6), Position(row: 11, col: 6), Position(row: 10, col: 6), Position(row: 9, col: 6),
        // Left
        Position(row: 8, col: 5), Position(row: 8, col: 4), Position(row: 8, col: 3), Position(row: 8, col: 2), Position(row: 8, col: 1), Position(row: 8, col: 0),
        // Up
        Position(row: 7, col: 0), Position(row: 6, col: 0),
        // Right
        Position(row: 6, col: 1), Position(row: 6, col: 2), Position(row: 6, col: 3), Position(row: 6, col: 4), Position(row: 6, col: 5),
        // Up
        Position(row: 5, col: 6), Position(row: 4, col: 6), Position(row: 3, col: 6), Position(row: 2, col: 6), Position(row: 1, col: 6), Position(row: 0, col: 6),
        // right
        Position(row: 0, col: 7), Position(row: 0, col: 8),
        // Down
        Position(row: 1, col: 8), Position(row: 2, col: 8), Position(row: 3, col: 8), Position(row: 4, col: 8), Position(row: 5, col: 8),
        // Right
        Position(row: 6, col: 9), Position(row: 6, col: 10), Position(row: 6, col: 11), Position(row: 6, col: 12), Position(row: 6, col: 13), Position(row: 6, col: 14),
        // Down
        Position(row: 7, col: 14), Position(row: 8, col: 14),
        // Left
        Position(row: 8, col: 13), Position(row: 8, col: 12), Position(row: 8, col: 11), Position(row: 8, col: 10), Position(row: 8, col: 9),
        // Down
        Position(row: 9, col: 8), Position(row: 10, col: 8), Position(row: 11, col: 8), Position(row: 12, col: 8), Position(row: 13, col: 8), Position(row: 14, col: 8),
        // Left
        Position(row: 14, col: 7), // End of main path loop for Blue
        Position(row: 13, col: 7), Position(row: 12, col: 7), Position(row: 11, col: 7), Position(row: 10, col: 7), Position(row: 9, col: 7), // Blue Safe Zone
        Position(row: 8, col: 7) // Blue Home
    ]

    @Published var pawns: [PlayerColor: [PawnState]] = [:]
    
    @Published var selectedAvatars: [PlayerColor: String] = [
        .red: PawnAssets.redMarble,
        .green: PawnAssets.greenMarble,
        .blue: PawnAssets.blueMarble,
        .yellow: PawnAssets.yellowMarble
    ]

    func selectedAvatar(for color: PlayerColor) -> String {
        return selectedAvatars[color] ?? PawnAssets.defaultMarble(for: color)
    }
    
    private func getDiceRoll() -> Int {
        // Only consider pawns that are not finished
        let unfinishedPawns = pawns[currentPlayer]?.filter { $0.positionIndex != GameConstants.finishedPawnIndex } ?? []
        let allUnfinishedAtHome = unfinishedPawns.allSatisfy { $0.positionIndex == nil }
        if allUnfinishedAtHome && !unfinishedPawns.isEmpty {
            GameLogger.shared.log("🎲 [INFO] All unfinished pawns are at home. Doubling the chance of rolling a 6.")
            // Weighted roll: ~33.3% chance of 6
            let randomValue = Double.random(in: 0.0..<1.0)
            if randomValue < GameConstants.weightedSixProbability {
                return GameConstants.sixDiceRoll
            } else {
                return Int.random(in: 1...(GameConstants.standardDiceSides - 1))
            }
        } else {
            // Standard roll
            return Int.random(in: 1...GameConstants.standardDiceSides)
        }
    }
    
    func rollDice() {
        GameLogger.shared.log("🎲 [ACTION] Attempting to roll dice for \(self.currentPlayer.rawValue)...")

        // Reset Mirchi arrows at the start of each turn
        if gameMode == .mirchi {
            mirchiArrowActivated = Dictionary(uniqueKeysWithValues: PlayerColor.allCases.map { ($0, false) })
            GameLogger.shared.log("🌶️ [MIRCHI] Arrows reset for new turn.", level: .debug)
        }

        // Don't allow rolling if the player has completed their game
        guard !hasCompletedGame(color: currentPlayer) else {
            GameLogger.shared.log("🎲 [GUARD FAILED] Player \(currentPlayer.rawValue) has already completed the game.")
            nextTurn(clearRoll: true)
            return
        }
        
        // Only allow rolling if there are no eligible pawns and no current roll
        guard eligiblePawns.isEmpty && currentRollPlayer == nil else {
            GameLogger.shared.log("🎲 [GUARD FAILED] Roll prevented. Pawns: \(eligiblePawns.count), Roll Player: \(currentRollPlayer?.rawValue ?? "nil")")
            return
        }
        
        diceValue = getDiceRoll()
        // Track roll history
        var rolls = diceRollHistory[currentPlayer] ?? []
        rolls.append(diceValue)
        diceRollHistory[currentPlayer] = rolls

        GameLogger.shared.log("🎲 ROLL HISTORY for \(currentPlayer.rawValue): \(rolls)", level: .debug)

        rollID += 1 // Increment the roll ID to ensure UI updates
        GameLogger.shared.log("🎲 [RESULT] \(self.currentPlayer.rawValue) rolled a \(self.diceValue) (Roll ID: \(self.rollID))")
        currentRollPlayer = currentPlayer  // Set the current player as the roll owner
        
        // Post-roll handling: compute eligible pawns + AI/human auto-move + no-move auto-advance.
        if let currentPawns = pawns[currentPlayer] {
            handlePostRoll(currentPawns: currentPawns, player: currentPlayer)
        }
    }

    private func handlePostRoll(currentPawns: [PawnState], player: PlayerColor) {
            eligiblePawns = getEligiblePawns()
            
            // If it's an AI's turn, let it make a move
        if aiControlledPlayers.contains(player) {
            if let strategy = aiStrategies[player],
               let pawnAndDirection = strategy.selectPawnMovementStrategy(from: eligiblePawns, for: player, in: self) {
                    let pawnId = pawnAndDirection.pawnId
                    let moveBackwards = pawnAndDirection.moveBackwards

                    // If the AI chose a backward move, update the UI to show the arrow selected
                    if moveBackwards {
                        self.mirchiArrowActivated[self.currentPlayer] = true
                        GameLogger.shared.log("🌶️ [AI] AI \(self.currentPlayer.rawValue) selected backward move.", level: .debug)
                    }

                    // Add a delay to make the AI's move feel more natural
                    DispatchQueue.main.asyncAfter(deadline: .now() + GameConstants.turnAdvanceDelay) {
                        // Find the selected pawn to check its state
                        if let pawn = self.pawns[self.currentPlayer]?.first(where: { $0.id == pawnId }) {
                            // CASE 1: Pawn is at home and needs to move out (requires a 6)
                            if pawn.positionIndex == nil {
                                // Backward moves from home are not possible, so this logic is safe.
                                self.movePawn(color: self.currentPlayer, pawnId: pawnId, steps: self.diceValue)
                            }
                            // CASE 2: Pawn is already on the path
                            else {
                                let currentPos = pawn.positionIndex ?? -1
                                let steps = self.diceValue
                                let moveDirection = moveBackwards ? "backward" : "forward"
                                if let destinationIndex = self.getDestinationIndex(color: self.currentPlayer, pawnId: pawnId, isBackward: moveBackwards) {
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("AnimatePawnMovement"),
                                        object: nil,
                                        userInfo: [
                                            "color": self.currentPlayer,
                                            "pawnId": pawnId,
                                            "from": currentPos,
                                            "to": destinationIndex,
                                            "steps": steps,
                                            "moveDirection": moveDirection
                                        ]
                                    )
                                }
                            }
                        }
                    }
                }
            }
            // If there's exactly one eligible pawn (for a human player), simulate tapping it
            // If we are in Mirchi mode, we don't want to auto-move the pawn as the player may want to move backward
            else if eligiblePawns.count == 1 && gameMode != .mirchi {
                if let pawnId = eligiblePawns.first,
                   let pawn = currentPawns.first(where: { $0.id == pawnId }) {
                    // Add a small delay to show the dice roll before moving
                    DispatchQueue.main.asyncAfter(deadline: .now() + GameConstants.turnAdvanceDelay) {
                        // Only auto-move if the pawn is on the path (not in home)
                        if pawn.positionIndex != nil {
                            let currentPos = pawn.positionIndex ?? -1
                            let steps = self.diceValue
                            
                            if let destinationIndex = self.getDestinationIndex(color: self.currentPlayer, pawnId: pawnId) {
                                // Notify the view to animate the movement
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("AnimatePawnMovement"),
                                    object: nil,
                                    userInfo: [
                                        "color": self.currentPlayer,
                                        "pawnId": pawnId,
                                        "from": currentPos,
                                        "to": destinationIndex,
                                        "steps": steps
                                    ]
                                )
                        }
                    }
                }
            }
        }
        
        // If no pawns can move, advance to next turn after a delay
        if eligiblePawns.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + GameConstants.turnAdvanceDelay) {
                self.nextTurn(clearRoll: true)
            }
        }
    }
    
    // Function to set a specific dice value for testing
    func testRollDice(value: Int) {
        // Reset Mirchi arrows at the start of each turn
        if gameMode == .mirchi {
            mirchiArrowActivated = Dictionary(uniqueKeysWithValues: PlayerColor.allCases.map { ($0, false) })
            GameLogger.shared.log("🌶️ [MIRCHI] Arrows reset for new turn.", level: .debug)
        }
        
        // Only allow rolling if there are no eligible pawns
        guard eligiblePawns.isEmpty else { return }
        
        // Set the specified dice value
        diceValue = value

        // Record in history for stats
        var rolls = diceRollHistory[currentPlayer] ?? []
        rolls.append(value)
        diceRollHistory[currentPlayer] = rolls

        rollID += 1 // Increment the roll ID to ensure UI updates
        GameLogger.shared.log("🎲 [RESULT] Admin set dice to \(self.diceValue) (Roll ID: \(self.rollID)). History: \(rolls)")
        currentRollPlayer = currentPlayer  // Set the current player as the roll owner
        
        // Mark eligible pawns based on the roll
        if let currentPawns = pawns[currentPlayer] {
            eligiblePawns = getEligiblePawns()
            
            // If there's exactly one eligible pawn, simulate tapping it
            if eligiblePawns.count == 1 && gameMode != .mirchi {
                if let pawnId = eligiblePawns.first,
                   let pawn = currentPawns.first(where: { $0.id == pawnId }) {
                    // Add a small delay to show the dice roll before moving
                    DispatchQueue.main.asyncAfter(deadline: .now() + GameConstants.turnAdvanceDelay) {
                        // Only auto-move if the pawn is on the path (not in home)
                        if pawn.positionIndex != nil {
                            let currentPos = pawn.positionIndex ?? -1
                            let steps = self.diceValue
                            
                            if let destinationIndex = self.getDestinationIndex(color: self.currentPlayer, pawnId: pawnId) {
                                // Notify the view to animate the movement
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("AnimatePawnMovement"),
                                    object: nil,
                                    userInfo: [
                                        "color": self.currentPlayer,
                                        "pawnId": pawnId,
                                        "from": currentPos,
                                        "to": destinationIndex,
                                        "steps": steps
                                    ]
                                )
                            }
                        }
                    }
                }
            }
        }
        // If no pawns can move, advance to next turn after a delay
        if eligiblePawns.isEmpty {
            // Keep the current player's roll visible for a short duration before moving to next turn
            DispatchQueue.main.asyncAfter(deadline: .now() + GameConstants.turnAdvanceDelay) {
                self.nextTurn(clearRoll: true)
            }
        }
    }
    
    func nextTurn(clearRoll: Bool = true) {
        GameLogger.shared.log("🔄 [TURN] Advancing turn from \(currentPlayer.rawValue)...")

        // Get all selected players in the order of PlayerColor.allCases
        let orderedPlayers = PlayerColor.allCases.filter { selectedPlayers.contains($0) }

        // Find the index of the current player within the ordered selected players
        guard let currentIndex = orderedPlayers.firstIndex(of: currentPlayer) else {
             // If the current player is not in the selected players (shouldn't happen in normal flow),
             // there's nothing to do or it indicates an error state.
             GameLogger.shared.log("Error: Current player \(currentPlayer) not found in selected players.", level: .error)
             return // Early return if currentIndex is nil
        }

        // Find the next player's index among the ordered selected players, wrapping around
        var nextIndex = (currentIndex + 1) % orderedPlayers.count
        var nextPlayer = orderedPlayers[nextIndex]

        // Keep looking for the next player among the ordered selected players who hasn't completed their game.
        // Stop if we cycle back to the starting player within the *selected* list (implies all remaining selected players have completed).
        while hasCompletedGame(color: nextPlayer) && nextPlayer != orderedPlayers[currentIndex] {
            nextIndex = (nextIndex + 1) % orderedPlayers.count
            nextPlayer = orderedPlayers[nextIndex]
        }

        // Set the current player to the determined next player.
        // Note: If the loop completed because all selected players are done, currentPlayer will be the same.
        currentPlayer = nextPlayer
        GameLogger.shared.log("🔄 [TURN] New current player is \(currentPlayer.rawValue)")

        // State clearing logic (kept consistent with original placement)
        if clearRoll {
            currentRollPlayer = nil
        }
        eligiblePawns.removeAll()
        // Clear any armed boost at turn change (boost is only usable on the current player's turn).
        for c in PlayerColor.allCases {
            if boostState[c] == .armed {
                let remaining = boostUsesRemaining[c, default: maxBoostUses(for: c)]
                boostState[c] = remaining > 0 ? .available : .used
            }
        }

        // Recursive call if the newly set currentPlayer has completed their game.
        // This is to immediately skip over a completed player's turn.
        if hasCompletedGame(color: currentPlayer) {
            // Before recursing, check if ALL *selected* players have completed.
            // If so, the game is over.
            if haveAllOtherPlayersCompleted() {
                isGameOver = true
                finalRankings = getFinalRankings() // Finalize rankings on game over
                awardCoinsForWinningScoreIfNeeded()
                return // Exit if game is truly over
            } else {
                // If not all players are done, skip this completed player's turn by calling nextTurn again.
                nextTurn(clearRoll: clearRoll)
            }
        } else {
            handleAITurn()
        }
    }
    
    // Check if a player has all their pawns in the finishing home
    func hasCompletedGame(color: PlayerColor) -> Bool {
        guard let playerPawns = pawns[color] else { return false }
        return playerPawns.allSatisfy { $0.positionIndex == GameConstants.finishedPawnIndex }
    }
    
    func startGame(selectedPlayers: Set<PlayerColor>, aiPlayers: Set<PlayerColor> = [], mode: GameMode) {
        GameLogger.shared.log("[SETUP] New Game. Players: \(selectedPlayers.count), AI: \(aiPlayers.count), Mode: \(mode.rawValue)")
        self.gameMode = mode
        self.selectedPlayers = selectedPlayers
        self.aiControlledPlayers = aiPlayers
        
        // Ensure selected avatars are initialized correctly
        self.selectedAvatars = selectedAvatars

        // Randomly assign a strategy to each AI player
        self.aiStrategies = [:]
        var isFirstAI = false
        for aiPlayer in aiPlayers {
            // For testing, assign the new BackwardOnlyMoveStrategy to the first AI player.
            if isFirstAI {
                aiStrategies[aiPlayer] = BackwardOnlyMoveStrategy()
                GameLogger.shared.log("🤖 [AI SETUP] AI for \(aiPlayer.rawValue) is BackwardOnly (for testing).")
                //isFirstAI = false
                continue
            }

            let possibleStrategies: [AILogicStrategy] = [RationalMoveStrategy(), AggressiveMoveStrategy()]
            if let chosenStrategy = possibleStrategies.randomElement() {
                aiStrategies[aiPlayer] = chosenStrategy
                
                let strategyName = (chosenStrategy is RationalMoveStrategy) ? "Rational" : "Aggressive"
                GameLogger.shared.log("🤖 [AI SETUP] AI for \(aiPlayer.rawValue) is \(strategyName).")
            }
        }
        
        gameStarted = true
        currentPlayer = selectedPlayers.first! // Set current player to the first selected player (assuming at least one selected)
        eligiblePawns.removeAll()
        currentRollPlayer = nil
        isGameOver = false
        didAwardCoinsForCurrentGame = false
        coinBalanceBeforeLastAward = coins
        lastCoinAward = 0
        finalRankings = []
        // Reset scores, kill counts, and home completion order
        scores = [.red: 0, .green: 0, .yellow: 0, .blue: 0]
        killCounts = [.red: 0, .green: 0, .yellow: 0, .blue: 0]
        homeCompletionOrder = []
        totalPawnsAtFinishingHome = 0
        customSafeZones.removeAll() // Clear custom safe zones on new game
        trappedZones.removeAll() // Clear trapped zones
        self.mirchiArrowActivated = Dictionary(uniqueKeysWithValues: PlayerColor.allCases.map { ($0, false) })
        // Reset boost state
        self.boostState = Dictionary(uniqueKeysWithValues: PlayerColor.allCases.map { ($0, .available) })
        self.boostUsesRemaining = Dictionary(uniqueKeysWithValues: PlayerColor.allCases.map { color in
            (color, maxBoostUses(for: color))
        })
        // Reset Mirchi move counts for selected players
        mirchiMovesRemaining = Dictionary(uniqueKeysWithValues: selectedPlayers.map { ($0, 5) })

        // Reset first blood tracking and dice history
        firstKillDone = false
        firstKillPlayer = nil
        diceRollHistory = Dictionary(uniqueKeysWithValues: PlayerColor.allCases.map { ($0, []) })

        // Initialize pawns for all players, but only selected ones will be visible/used
        var allPawns: [PlayerColor: [PawnState]] = [:]
        for color in selectedPlayers {
            allPawns[color] = (0..<GameConstants.pawnsPerPlayer).map { PawnState(id: $0, color: color, positionIndex: GameConstants.homePawnIndex) }
        }
        self.pawns = allPawns
        
        handleAITurn()
    }
    
    // Helper to get the path for a color
    func path(for color: PlayerColor) -> [Position] {
        guard selectedPlayers.contains(color) else { return [] }
        
        switch color {
        case .red: return Self.redPath
        case .green: return Self.greenPath
        case .yellow: return Self.yellowPath
        case .blue: return Self.bluePath
        }
    }

    // MARK: - Game Logic

    // Function to move a pawn (handles both forward and backward movement)
    func movePawn(color: PlayerColor, pawnId: Int, steps: Int, backward: Bool = false) {
        logPawnPositionsBeforeAndAfterMove(color: color, pawnId: pawnId, steps: steps)
        
        // Reset Mirchi arrows at the start of each turn
        if gameMode == .mirchi {
            mirchiArrowActivated = Dictionary(uniqueKeysWithValues: PlayerColor.allCases.map { ($0, false) })
            GameLogger.shared.log("🌶️ [MIRCHI] Arrows reset for new turn.", level: .debug)
        }
        
        guard let pawnIndex = getValidatedPawnIndex(color: color, pawnId: pawnId, backward: backward) else { return }
        
        var shouldGetAnotherRoll = false
        
        let isPawnOnPath = pawns[color]?[pawnIndex].positionIndex != nil

        if isPawnOnPath {
            let currentPath = path(for: color)
            let positionIndex = pawns[color]?[pawnIndex].positionIndex ?? 0
            let newIndex = backward ? positionIndex - steps : positionIndex + steps

            // This is a programmer error. The view logic should prevent this.
            guard !backward || newIndex >= 0 else {
                GameLogger.shared.log("❌ [FATAL] Invalid backward move: resulted in negative pawn position index. Color: \(color.rawValue), PawnIndex: \(pawnIndex), PositionIndex: \(positionIndex), Steps: \(steps), NewIndex: \(newIndex)", level: .error)
                fatalError("Invalid backward move: resulted in a negative pawn position index.")
            }
            
            let isPawnMovingToAnotherSpotOnPath = newIndex >= GameConstants.startingPathIndex && newIndex < currentPath.count - 1
            let isPawnReachingHome = newIndex == currentPath.count - 1

            if isPawnMovingToAnotherSpotOnPath {
                shouldGetAnotherRoll = movePawnToAnotherSpotOnPath(color: color, pawnIndex: pawnIndex, currentPath: currentPath, newIndex: newIndex, backward: backward)

                // Decrement Mirchi moves if this was a backward move
                if backward {
                    mirchiMovesRemaining[color] = max(0, mirchiMovesRemaining[color, default: 0] - 1)
                }
            } else if isPawnReachingHome {
                shouldGetAnotherRoll = movePawnToHome(color: color, pawnIndex: pawnIndex)
            }
        } else {
            // Pawn is at home
            if steps == GameConstants.sixDiceRoll {
                NotificationCenter.default.post(name: .animatePawnFromHome, object: nil, userInfo: ["color": color, "pawnId": pawnId])
                return
            }
        }
        
        if shouldGetAnotherRoll || diceValue == GameConstants.sixDiceRoll {
            // Player gets another roll - clear the roll but keep the same player
            GameLogger.shared.log("🔄 [TURN] Player \(currentPlayer.rawValue) gets another turn.")
            currentRollPlayer = nil
            eligiblePawns.removeAll()
            // If the current player is an AI, trigger its next turn.
            handleAITurn()
        } else {
            nextTurn(clearRoll: true)
        }
    }
    
    // MARK: - Safe Zone Logic
    
    // Helper to create a custom safe zone or trap via boost
    func handleCellTap(row: Int, col: Int) {
        // Ensure boost is armed
        guard getBoostState(for: currentPlayer) == .armed else { return }
        guard let ability = boostAbility(for: currentPlayer) else { return }
        
        let position = Position(row: row, col: col)

        // Constraint: Cannot deploy on any safe position (Start, Finish, Home, Stars, or existing Shield)
        // reusing isSafePosition automatically factors in all these cases.
        if isSafePosition(position) {
            errorMessage = "This spot is ineligible to deploy (Safe Zone)"
            showError = true
            return
        }
        
        // Constraint: Cannot deploy in starting home areas (colored corners)
        if isStartingHomeArea(position) {
            errorMessage = "This spot is ineligible to deploy (Starting Home)"
            showError = true
            return
        }
        
        // Constraint: Cannot deploy on a Trap
        if trappedZones.contains(position) {
            errorMessage = "This spot is ineligible to deploy (Trap is present)"
            showError = true
            return
        }
        
        // Constraint: Cannot deploy if a pawn is present
        for (color, playerPawns) in pawns {
            let playerPath = path(for: color)
            for pawn in playerPawns {
                if let index = pawn.positionIndex, index >= 0, index < playerPath.count {
                    if playerPath[index] == position {
                        errorMessage = "This spot is ineligible to deploy (Occupied by Pawn)"
                        showError = true
                        return
                    }
                }
            }
        }

        if ability.kind == .safeZone {
            // Mark as safe zone
            customSafeZones.insert(position)
            consumeBoostUse(for: currentPlayer)
            SoundManager.shared.playPawnHopSound() 
            GameLogger.shared.log("🛡️ [BOOST] Safe zone created at \(row),\(col)", level: .info)
        } else if ability.kind == .trap {
            // Mark as trap
            trappedZones.insert(position)
            consumeBoostUse(for: currentPlayer)
            SoundManager.shared.playPawnHopSound()
            GameLogger.shared.log("🔥 [BOOST] Trap deployed at \(row),\(col)", level: .info)
        }
    }
    
    // Helper to check if a position is a safe spot
    func isSafePosition(_ position: Position) -> Bool {
        // Check if position is a custom safe zone
        if customSafeZones.contains(position) {
            return true
        }

        // Check if position is in any safe zone
        if Self.redSafeZone.contains(position) || 
           Self.greenSafeZone.contains(position) ||
           Self.yellowSafeZone.contains(position) ||
           Self.blueSafeZone.contains(position) {
            return true
        }
        
        // Check if position is any home spot
        if position == Self.redHome ||
           position == Self.greenHome ||
           position == Self.yellowHome ||
           position == Self.blueHome {
            return true
        }
        
        // Check if position is a starting position (where pawns first enter the path)
        let startingPositions = [
            Position(row: 6, col: 1),  // Red start
            Position(row: 1, col: 8),  // Green start
            Position(row: 8, col: 13), // Yellow start
            Position(row: 13, col: 6)  // Blue start
        ]
        
        if startingPositions.contains(position) {
            return true
        }
        
        // Check if position is a star space
        let additionalStarSpaces = [
            Position(row: 8, col: 2),
            Position(row: 12, col: 8),
            Position(row: 6, col: 12),
            Position(row: 2, col: 6)
        ]
        
        return additionalStarSpaces.contains(position)
    }

    // Helper to check if a position is within the starting home areas (colored corners)
    func isStartingHomeArea(_ position: Position) -> Bool {
        let row = position.row
        let col = position.col
        
        // Red: Top-left corner (0-5, 0-5)
        if row <= 5 && col <= 5 { return true }
        
        // Green: Top-right corner (0-5, 9-14)
        if row <= 5 && col >= 9 && col <= 14 { return true }
        
        // Blue: Bottom-left corner (9-14, 0-5)
        if row >= 9 && row <= 14 && col <= 5 { return true }
        
        // Yellow: Bottom-right corner (9-14, 9-14)
        if row >= 9 && row <= 14 && col >= 9 && col <= 14 { return true }
        
        return false
    }

    // Function to validate if a move is legal
    func isValidMove(color: PlayerColor, pawnId: Int) -> Bool {
        // Check if it's the current player's turn
        guard color == currentPlayer else { return false }
        
        // Check if it's the current player's roll
        guard color == currentRollPlayer else { return false }
        
        // Check if the pawn is eligible to move
        guard eligiblePawns.contains(pawnId) else { return false }
        
        // Additional check for overshooting home
        if let pawn = pawns[color]?.first(where: { $0.id == pawnId }),
           let positionIndex = pawn.positionIndex,
           positionIndex >= 0 {
            let currentPath = path(for: color)
            let newIndex = positionIndex + diceValue
            return newIndex <= currentPath.count - 1
        }
        
        return true
    }
    
    // Function to validate if a backward move is legal in Mirchi Mode
    func isValidBackwardMove(color: PlayerColor, pawnId: Int, isBoost: Bool = false) -> Bool {
        // Standard move validation
        guard color == currentPlayer,
              color == currentRollPlayer,
              eligiblePawns.contains(pawnId) else {
            return false
        }

        // Ensure the player has remaining Mirchi moves OR it's a boost move
        guard isBoost || mirchiMovesRemaining[color, default: 0] > 0 else {
            return false
        }
        
        // Backward-specific validation
        guard let pawn = pawns[color]?.first(where: { $0.id == pawnId }),
              let positionIndex = pawn.positionIndex,
              positionIndex >= GameConstants.startingPathIndex else {
            // Pawn must be on the path (not at home or finished)
            return false
        }

        // Backward move is not allowed from any safe zone
        let currentPath = path(for: color)
        let currentPosition = currentPath[positionIndex]
        let inSafeZone = Self.redSafeZone.contains(currentPosition) ||
                         Self.greenSafeZone.contains(currentPosition) ||
                         Self.yellowSafeZone.contains(currentPosition) ||
                         Self.blueSafeZone.contains(currentPosition)
        if inSafeZone {
            return false
        }
        
        // Ensure the move does not go past the start of the path
        return positionIndex - diceValue >= GameConstants.startingPathIndex
    }
    
    // Function to get the destination index for a move
    func getDestinationIndex(color: PlayerColor, pawnId: Int, isBackward: Bool = false) -> Int? {
        guard let pawn = pawns[color]?.first(where: { $0.id == pawnId }),
              let positionIndex = pawn.positionIndex else { return nil }
        let currentPath = path(for: color)
        let newIndex = isBackward ? positionIndex - diceValue : positionIndex + diceValue
        if isBackward {
            return newIndex >= GameConstants.startingPathIndex ? newIndex : nil
        } else {
            return newIndex >= currentPath.count - 1 ? GameConstants.finishedPawnIndex : newIndex
        }
    }

    func haveAllOtherPlayersCompleted() -> Bool {
        // Count how many of the selected players have finished the game.
        let finishedPlayersCount = selectedPlayers.filter { hasCompletedGame(color: $0) }.count
        
        // The game is over if the number of players who have NOT finished is 1 or less.
        let activePlayerCount = selectedPlayers.count - finishedPlayersCount
        return activePlayerCount <= 1
    }

    func getFinalRankings() -> [PlayerColor] {
        return PlayerColor.allCases.sorted { (scores[$0] ?? 0) > (scores[$1] ?? 0) }
    }

    func handleAITurn() {
        // Block AI from acting if the game is busy (e.g., animation in progress)
        if isBusy { return }
        if aiControlledPlayers.contains(currentPlayer) {
            GameLogger.shared.log("🤖 [AI] Handling AI turn for \(currentPlayer.rawValue)...")
            // Add a delay to simulate the AI "thinking" before rolling
            DispatchQueue.main.asyncAfter(deadline: .now() + GameConstants.aiThinkingDelay) {
                GameLogger.shared.log("🤖 [AI] AI \(self.currentPlayer.rawValue) is now attempting to roll the dice.")
                // Ensure it's still the AI's turn before rolling.
                if self.aiControlledPlayers.contains(self.currentPlayer) {
                    self.rollDice()
                }
            }
        } else {
            GameLogger.shared.log("👤 [HUMAN] Waiting for human player \(currentPlayer.rawValue) to roll the dice.")
        }
    }

    private func generatePawnPositionLogString() -> String {
        var logParts: [String] = []

        // Iterate through all colors in a consistent order to make logs comparable
        for color in PlayerColor.allCases {
            // Only log players who are in the game
            guard let playerPawns = pawns[color], selectedPlayers.contains(color) else { continue }
            
            var pawnStrings: [String] = []
            // Sort pawns by ID for consistent ordering
            for pawn in playerPawns.sorted(by: { $0.id < $1.id }) {
                var positionDescription: String
                if let positionIndex = pawn.positionIndex {
                    if positionIndex == GameConstants.finishedPawnIndex {
                        positionDescription = "Finished"
                    } else {
                        let path = self.path(for: pawn.color)
                        if positionIndex < path.count {
                            let pos = path[positionIndex]
                            positionDescription = "row:\(pos.row), col:\(pos.col)"
                        } else {
                            // This indicates a bug state, which is important to log
                            positionDescription = "InvalidIndex(\(positionIndex))"
                        }
                    }
                } else {
                    positionDescription = "Home"
                }
                pawnStrings.append("(id:\(pawn.id), \(positionDescription))")
            }
            
            logParts.append("\(color.rawValue.capitalized) pawns: \(pawnStrings.joined(separator: ", "))")
        }
        
        return logParts.joined(separator: " | ")
    }

    // This function will be called by the view after the "move from home" animation is complete.
    func completeMoveFromHome(color: PlayerColor, pawnId: Int) {
        // Now, officially update the pawn's state.
        if let pawnIndex = pawns[color]?.firstIndex(where: { $0.id == pawnId }) {
            pawns[color]?[pawnIndex].positionIndex = GameConstants.startingPathIndex
            SoundManager.shared.playPawnLeaveHomeSound()
        }
        
        // A roll of 6 always grants another turn.
        GameLogger.shared.log("🔄 [TURN] Player \(currentPlayer.rawValue) gets another turn for rolling a 6.")
        currentRollPlayer = nil
        eligiblePawns.removeAll()
        handleAITurn()
    }

    // This function is called by the view after a pawn capture animation is complete.
    func completePawnCapture(color: PlayerColor, pawnId: Int) {
        if let pawnIndex = pawns[color]?.firstIndex(where: { $0.id == pawnId }) {
            pawns[color]?[pawnIndex].positionIndex = GameConstants.homePawnIndex
        }
    }

    private func logPawnPositionsBeforeAndAfterMove(color: PlayerColor, pawnId: Int, steps: Int) {
        GameLogger.shared.log("[PAWN POSITIONS BEFORE MOVE] \(generatePawnPositionLogString())", level: .debug)
        GameLogger.shared.log("♟️ [ACTION] Attempting to move pawn \(pawnId) for \(color.rawValue) with dice \(steps)")
        defer {
            GameLogger.shared.log("[PAWN POSITIONS AFTER MOVE] \(generatePawnPositionLogString())", level: .debug)
        }
    }

    private func getValidatedPawnIndex(color: PlayerColor, pawnId: Int, backward: Bool) -> Int? {
        // Only allow moving if:
        // 1. It's your turn
        // 2. It's your roll (and currentRollPlayer is not nil)
        // 3. The pawn is eligible to move
        guard color == currentPlayer,
              let rollPlayer = currentRollPlayer,
              color == rollPlayer,
              eligiblePawns.contains(pawnId),
              let pawnIndex = pawns[color]?.firstIndex(where: { $0.id == pawnId }) else { return nil }
        
        // Precondition check for backward moves
        if backward {
            guard let positionIndex = pawns[color]?[pawnIndex].positionIndex, positionIndex >= GameConstants.startingPathIndex else {
                GameLogger.shared.log("❌ [FATAL] Invalid backward move: Pawn \(pawnId) for \(color.rawValue) must be on the path (not at home or finished). Current position: \(String(describing: pawns[color]?[pawnIndex].positionIndex))", level: .error)
                fatalError("Invalid backward move: Pawn must be on the path (not at home or finished).")
            }
        }
        
        return pawnIndex
    }

    private func movePawnToAnotherSpotOnPath(color: PlayerColor, pawnIndex: Int, currentPath: [Position], newIndex: Int, backward: Bool) -> Bool {
        var shouldGetAnotherRoll = false
        
        // First check if the new position would result in a capture
        let newPosition = currentPath[newIndex]
        
        // Check for TRAP
        if trappedZones.contains(newPosition) {
            GameLogger.shared.log("⚠️ [TRAP] Pawn landed on trap at \(newPosition.row),\(newPosition.col)", level: .info)
            // Trigger capture on self (the pawn gets "cut")
            if let pawn = pawns[color]?[pawnIndex] {
                // Post notification to animate the pawn being captured (sent home)
                NotificationCenter.default.post(name: .animatePawnCapture,
                                               object: nil,
                                               userInfo: ["color": color, "pawnId": pawn.id])
            }
            
            // Update position to trap cell temporarily. 
            // The completePawnCapture callback (triggered by UI after animation) will reset it to home.
            pawns[color]?[pawnIndex].positionIndex = newIndex
            
            // Landing on a trap ends turn immediately, no bonus roll.
            return false
        }
        
        // Check if the position is a safe spot
        let isSafeSpot = isSafePosition(newPosition)
        
        if !isSafeSpot {
            // Check for captures at the new position
            for (otherColor, otherPawns) in pawns {
                if otherColor == color { continue }
                
                for (otherIndex, otherPawn) in otherPawns.enumerated() {
                    guard let otherPositionIndex = otherPawn.positionIndex,
                          otherPositionIndex >= GameConstants.startingPathIndex else { continue }
                    
                    let otherPosition = path(for: otherColor)[otherPositionIndex]
                    
                    if otherPosition == newPosition {
                        // Capture the pawn - Post notification to animate it
                        NotificationCenter.default.post(name: .animatePawnCapture,
                                                        object: nil,
                                                        userInfo: ["color": otherColor, "pawnId": otherPawn.id])
                        if backward {
                            GameLogger.shared.log("🌶️ DEBUG: Posting mirchiBackwardCapture notification", level: .debug)
                            NotificationCenter.default.post(name: .mirchiBackwardCapture,
                                                            object: nil,
                                                            userInfo: nil)
                        }
                        shouldGetAnotherRoll = true
                        // Add points for capture
                        scores[color] = (scores[color] ?? 0) + GameConstants.capturePoints
                        // Increment kill count for capturing player
                        killCounts[color] = (killCounts[color] ?? 0) + 1

                        // First blood bonus
                        if !firstKillDone {
                            firstKillDone = true
                            firstKillPlayer = color
                            scores[color] = (scores[color] ?? 0) + 3
                            GameLogger.shared.log("💀 FIRST BLOOD! +3", level: .info)
                            NotificationCenter.default.post(name: .firstBlood,
                                                            object: nil,
                                                            userInfo: ["color": color.rawValue])
                        }
                    }
                }
            }
        }
        
        // Now move the pawn
        pawns[color]?[pawnIndex].positionIndex = newIndex
        return shouldGetAnotherRoll
    }

    private func movePawnToHome(color: PlayerColor, pawnIndex: Int) -> Bool {
        // Pawn reaches home
        pawns[color]?[pawnIndex].positionIndex = GameConstants.finishedPawnIndex
        
        // Add fixed points for reaching home
        scores[color] = (scores[color] ?? 0) + 10

        // Check if this move completes the player's game
        let completedNow = hasCompletedGame(color: color)

        // Notify UI for confetti / +10 animation (include completion flag)
        NotificationCenter.default.post(name: .pawnReachedHome,
                                        object: nil,
                                        userInfo: ["color": color, "completed": completedNow])

        // Track total pawns reaching home (maintained for potential external uses)
        totalPawnsAtFinishingHome += 1

        // If this was the last pawn for this player, check for game over
        if hasCompletedGame(color: color) {
            // Award completion bonus based on order of finishing
            if !homeCompletionOrder.contains(color) {
                homeCompletionOrder.append(color)
                let bonus: Int
                switch homeCompletionOrder.count {
                case 1: bonus = 35   // First player to finish
                case 2: bonus = 20   // Second player
                case 3: bonus = 10   // Third player
                default: bonus = 0   // Fourth or later
                }
                scores[color] = (scores[color] ?? 0) + bonus
                // Notify UI overlay of bonus points for completing the game
                NotificationCenter.default.post(name: .playerFinished, object: nil, userInfo: ["color": color, "bonus": bonus])
            }

            if haveAllOtherPlayersCompleted() {
                isGameOver = true
                finalRankings = getFinalRankings()
                awardCoinsForWinningScoreIfNeeded()
                return true  // Exit early if game is over
            }
            nextTurn(clearRoll: true)
        }
        
        return true // Get another roll for reaching home
    }

    // Returns the set of eligible pawn IDs for the current player and dice value
    private func getEligiblePawns() -> Set<Int> {
        guard let currentPawns = pawns[currentPlayer] else { return [] }
        return Set(currentPawns.filter { pawn in
            if let positionIndex = pawn.positionIndex {
                let currentPath = path(for: currentPlayer)
                let newIndex = positionIndex + diceValue
                return positionIndex >= GameConstants.startingPathIndex && newIndex <= currentPath.count - 1
            } else {
                return diceValue == GameConstants.sixDiceRoll
            }
        }.map { $0.id })
    }
    
    func resetGame() {
        gameStarted = false
        isGameOver = false
        didAwardCoinsForCurrentGame = false
        coinBalanceBeforeLastAward = coins
        lastCoinAward = 0
        boostState = Dictionary(uniqueKeysWithValues: PlayerColor.allCases.map { ($0, .available) })
        boostUsesRemaining = Dictionary(uniqueKeysWithValues: PlayerColor.allCases.map { ($0, 0) })
        customSafeZones.removeAll() // Reset custom safe zones
        trappedZones.removeAll() // Clear trapped zones
    }
    
    // MARK: - Boost API (centralized)
    func boostAbility(for color: PlayerColor) -> (any BoostAbility)? {
        BoostRegistry.ability(for: selectedAvatar(for: color))
    }

    private func maxBoostUses(for color: PlayerColor) -> Int {
        PawnAssets.boostUses(for: selectedAvatar(for: color))
    }

    private func consumeBoostUse(for color: PlayerColor) {
        let currentRemaining = boostUsesRemaining[color] ?? maxBoostUses(for: color)
        guard currentRemaining > 0 else {
            boostUsesRemaining[color] = 0
            boostState[color] = .used
            return
        }

        let nextRemaining = currentRemaining - 1
        boostUsesRemaining[color] = nextRemaining
        boostState[color] = nextRemaining > 0 ? .available : .used
    }
    
    func getBoostState(for color: PlayerColor) -> BoostState {
        guard boostAbility(for: color) != nil else { return .used }
        let remaining = boostUsesRemaining[color] ?? maxBoostUses(for: color)
        if remaining <= 0 { return .used }
        return boostState[color] == .armed ? .armed : .available
    }
    
    func tapBoost(color: PlayerColor) {
        guard let ability = boostAbility(for: color) else { return }
        guard currentPlayer == color else { return }
        let context = BoostContext(
            currentPlayer: currentPlayer,
            isBusy: isBusy,
            isAIControlled: aiControlledPlayers.contains(color),
            isBackwardMove: false
        )
        guard ability.canArm(context: context) else { return }
        let remaining = boostUsesRemaining[color] ?? maxBoostUses(for: color)
        guard remaining > 0 else {
            boostState[color] = .used
            return
        }

        let current = getBoostState(for: color)
        let nextState = ability.onTap(currentState: current)
        if nextState == .used {
            ability.performOnTap(game: self, color: color, context: context)
            consumeBoostUse(for: color)
        } else {
            boostState[color] = nextState
            ability.performOnTap(game: self, color: color, context: context)
        }
    }
    
    func consumeBoostOnPawnTapIfNeeded(color: PlayerColor, isBackward: Bool = false) {
        guard let ability = boostAbility(for: color) else { return }
        let context = BoostContext(
            currentPlayer: currentPlayer,
            isBusy: isBusy,
            isAIControlled: aiControlledPlayers.contains(color),
            isBackwardMove: isBackward
        )
        let current = getBoostState(for: color)
        guard ability.shouldConsumeOnPawnTap(context: context, currentState: current) else { return }
        
        GameLogger.shared.log("⚡️ [BOOST] Consuming boost for \(color.rawValue).", level: .debug)
        consumeBoostUse(for: color)
    }

    // MARK: - Mango boost effect
    /// Force a dice-roll animation that ends in a 6.
    /// This is designed for the Mango boost and can be used before OR after a normal roll.
    func forceDiceRollToSixForCurrentTurn() {
        guard !isBusy else { return }
        guard !hasCompletedGame(color: currentPlayer) else { return }

        diceValue = GameConstants.sixDiceRoll

        // Track roll history
        var rolls = diceRollHistory[currentPlayer] ?? []
        rolls.append(diceValue)
        diceRollHistory[currentPlayer] = rolls

        rollID += 1 // triggers dice animation in the UI
        currentRollPlayer = currentPlayer
        if let currentPawns = pawns[currentPlayer] {
            handlePostRoll(currentPawns: currentPawns, player: currentPlayer)
        } else {
            eligiblePawns = getEligiblePawns()
            if eligiblePawns.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + GameConstants.turnAdvanceDelay) {
                    self.nextTurn(clearRoll: true)
                }
            }
        }

        GameLogger.shared.log("🥭⚡️ [BOOST] Forced dice roll to 6 for \(currentPlayer.rawValue) (Roll ID: \(rollID))", level: .debug)
    }

    // MARK: - Admin test helpers
    /// Admin-only test utility to instantly finish the game with caller-provided scores.
    /// This bypasses gameplay animations and teleports pawns to finished home.
    func adminEndGame(finalScores: [PlayerColor: Int]) {
        guard isAdminMode, gameStarted else { return }

        // Apply requested final scores only to active players.
        for color in selectedPlayers {
            scores[color] = max(0, finalScores[color] ?? 0)
        }

        // Clear bonus-driving stats so admin-entered final scores remain stable on GameOver.
        killCounts = Dictionary(uniqueKeysWithValues: selectedPlayers.map { ($0, 0) })
        firstKillPlayer = nil
        firstKillDone = false
        diceRollHistory = Dictionary(uniqueKeysWithValues: PlayerColor.allCases.map { ($0, []) })

        // Force-finish all pawns instantly:
        // 1) bring out from home to start index, 2) teleport to finished home index.
        for color in selectedPlayers {
            guard var playerPawns = pawns[color] else { continue }
            for idx in playerPawns.indices {
                if playerPawns[idx].positionIndex == GameConstants.homePawnIndex {
                    playerPawns[idx].positionIndex = GameConstants.startingPathIndex
                }
                playerPawns[idx].positionIndex = GameConstants.finishedPawnIndex
            }
            pawns[color] = playerPawns
        }

        totalPawnsAtFinishingHome = selectedPlayers.count * GameConstants.pawnsPerPlayer
        homeCompletionOrder = []
        eligiblePawns.removeAll()
        currentRollPlayer = nil
        isBusy = false

        finalRankings = selectedPlayers.sorted { (scores[$0] ?? 0) > (scores[$1] ?? 0) }
        isGameOver = true
        awardCoinsForWinningScoreIfNeeded()
    }

    /// Admin-only test utility to force coin balance.
    func adminSetCoins(_ amount: Int) {
        guard isAdminMode else { return }
        let clamped = max(0, amount)
        coins = clamped
        coinBalanceBeforeLastAward = clamped
        lastCoinAward = 0
        UnlockManager.setCoinBalance(clamped)
    }

    /// Admin-only test utility to lock all non-classic pawns again.
    func adminResetUnlocks() {
        guard isAdminMode else { return }
        UnlockManager.resetAllPawnUnlocks()
    }

    // MARK: - Coin rewards
    private func awardCoinsForWinningScoreIfNeeded() {
        guard !didAwardCoinsForCurrentGame else { return }
        let rankings: [PlayerColor]
        if !selectedPlayers.isEmpty {
            rankings = selectedPlayers.sorted { (scores[$0] ?? 0) > (scores[$1] ?? 0) }
        } else {
            rankings = finalRankings.isEmpty ? getFinalRankings() : finalRankings
        }
        guard let winner = rankings.first else { return }
        let winningScore = max(0, scores[winner] ?? 0)
        coinBalanceBeforeLastAward = coins
        lastCoinAward = winningScore
        guard winningScore > 0 else {
            didAwardCoinsForCurrentGame = true
            return
        }

        UnlockManager.addCoins(winningScore)
        coins = UnlockManager.getCoinBalance()
        didAwardCoinsForCurrentGame = true
    }
}

extension Notification.Name {
    static let animatePawnFromHome = Notification.Name("AnimatePawnFromHome")
    static let animatePawnCapture = Notification.Name("AnimatePawnCapture")
    static let pawnReachedHome = Notification.Name("PawnReachedHome")
    static let playerFinished = Notification.Name("PlayerFinished")
    static let mirchiBackwardCapture = Notification.Name("MirchiBackwardCapture")
    static let firstBlood = Notification.Name("FirstBlood")
} 
