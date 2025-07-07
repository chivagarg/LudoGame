import Foundation

enum GameMode: String, CaseIterable, Identifiable {
    case classic = "Classic"
    case mirchi = "Mirchi"
    var id: String { rawValue }
}

struct Position: Equatable {
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

    // Track number of pawns each player has captured
    @Published var killCounts: [PlayerColor: Int] = [.red: 0, .green: 0, .yellow: 0, .blue: 0]

    // AI Player Configuration
    private var aiStrategies: [PlayerColor: AILogicStrategy] = [:]

    // Busy state for blocking moves/rolls during animation
    // E.g. when a pawn is being captured, we don't want to allow the player to roll the dice or move the pawn
    @Published var isBusy: Bool = false

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

        rollID += 1 // Increment the roll ID to ensure UI updates
        GameLogger.shared.log("🎲 [RESULT] \(self.currentPlayer.rawValue) rolled a \(self.diceValue) (Roll ID: \(self.rollID))")
        currentRollPlayer = currentPlayer  // Set the current player as the roll owner
        
        // Mark eligible pawns based on the roll
        if let currentPawns = pawns[currentPlayer] {
            eligiblePawns = getEligiblePawns()
            
            // If it's an AI's turn, let it make a move
            if aiControlledPlayers.contains(currentPlayer) {
                if let strategy = aiStrategies[currentPlayer],
                   let pawnAndDirection = strategy.selectPawnMovementStrategy(from: eligiblePawns, for: currentPlayer, in: self) {
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
        }
        
        // If no pawns can move, advance to next turn after a delay
        if eligiblePawns.isEmpty {
            // Keep the current player's roll visible for 1 seconds before moving to next turn
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
        rollID += 1 // Increment the roll ID to ensure UI updates
        GameLogger.shared.log("🎲 [RESULT] Admin set dice to \(self.diceValue) (Roll ID: \(self.rollID))")
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

        // Recursive call if the newly set currentPlayer has completed their game.
        // This is to immediately skip over a completed player's turn.
        if hasCompletedGame(color: currentPlayer) {
            // Before recursing, check if ALL *selected* players have completed.
            // If so, the game is over.
            if haveAllOtherPlayersCompleted() {
                isGameOver = true
                finalRankings = getFinalRankings() // Finalize rankings on game over
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
        finalRankings = []
        // Reset scores and home completion order
        scores = [.red: 0, .green: 0, .yellow: 0, .blue: 0]
        homeCompletionOrder = []
        totalPawnsAtFinishingHome = 0
        self.mirchiArrowActivated = Dictionary(uniqueKeysWithValues: PlayerColor.allCases.map { ($0, false) })

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
                shouldGetAnotherRoll = movePawnToAnotherSpotOnPath(color: color, pawnIndex: pawnIndex, currentPath: currentPath, newIndex: newIndex)
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
    
    // Helper to check if a position is a safe spot
    func isSafePosition(_ position: Position) -> Bool {
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
    func isValidBackwardMove(color: PlayerColor, pawnId: Int) -> Bool {
        // Standard move validation
        guard color == currentPlayer,
              color == currentRollPlayer,
              eligiblePawns.contains(pawnId) else {
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

    private func movePawnToAnotherSpotOnPath(color: PlayerColor, pawnIndex: Int, currentPath: [Position], newIndex: Int) -> Bool {
        var shouldGetAnotherRoll = false
        
        // First check if the new position would result in a capture
        let newPosition = currentPath[newIndex]
        
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
                        NotificationCenter.default.post(
                            name: .animatePawnCapture,
                            object: nil,
                            userInfo: ["color": otherColor, "pawnId": otherPawn.id]
                        )
                        shouldGetAnotherRoll = true
                        // Add points for capture
                        scores[color] = (scores[color] ?? 0) + GameConstants.capturePoints
                        // Increment kill count for capturing player
                        killCounts[color] = (killCounts[color] ?? 0) + 1
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
        
        // Add points for reaching home based on global order
        totalPawnsAtFinishingHome += 1
        let points = GameConstants.maxScorePerPawn - (totalPawnsAtFinishingHome - 1)  // First pawn gets 16, second gets 15, etc.
        scores[color] = (scores[color] ?? 0) + points
        
        // If this was the last pawn for this player, check for game over
        if hasCompletedGame(color: color) {
            if haveAllOtherPlayersCompleted() {
                isGameOver = true
                finalRankings = getFinalRankings()
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
}

extension Notification.Name {
    static let animatePawnFromHome = Notification.Name("AnimatePawnFromHome")
    static let animatePawnCapture = Notification.Name("AnimatePawnCapture")
} 
