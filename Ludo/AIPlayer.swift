import Foundation

/// A tuple representing the AI's chosen move, including the pawn and direction.
typealias AIPlayerMove = (pawnId: Int, moveBackwards: Bool)

/// Checks if an opponent pawn is at a specific board position.
private func isOpponentAt(position: Position, in game: LudoGame, excluding player: PlayerColor) -> Bool {
    for (opponentColor, opponentPawns) in game.pawns where opponentColor != player {
        let opponentPath = game.path(for: opponentColor)
        guard !opponentPath.isEmpty else { continue }
        for opponentPawn in opponentPawns {
            if let opponentIndex = opponentPawn.positionIndex,
               opponentIndex >= 0 && opponentIndex < opponentPath.count {
                if opponentPath[opponentIndex] == position {
                    return true
                }
            }
        }
    }
    return false
}

/// A protocol that defines the decision-making logic for an AI player.
protocol AILogicStrategy {
    /// Selects a pawn to move and the direction of movement from a set of eligible pawns.
    /// - Parameters:
    ///   - eligiblePawns: A set of pawn IDs that are legal to move.
    ///   - game: The current state of the Ludo game.
    /// - Returns: An `AIPlayerMove` tuple, or `nil` if no choice could be made.
    func selectPawnMovementStrategy(from eligiblePawns: Set<Int>, for player: PlayerColor, in game: LudoGame) -> AIPlayerMove?
}


/// A simple AI strategy that chooses a pawn to move completely at random.
struct RandomMoveStrategy: AILogicStrategy {
    func selectPawnMovementStrategy(from eligiblePawns: Set<Int>, for player: PlayerColor, in game: LudoGame) -> AIPlayerMove? {
        // This simple strategy never moves backward.
        if let pawnId = eligiblePawns.randomElement() {
            return (pawnId: pawnId, moveBackwards: false)
        }
        return nil
    }
}


/// An AI strategy that attempts to make rational moves based on a prioritized set of rules.
struct RationalMoveStrategy: AILogicStrategy {
    
    func selectPawnMovementStrategy(from eligiblePawns: Set<Int>, for player: PlayerColor, in game: LudoGame) -> AIPlayerMove? {
        GameLogger.shared.log("🤖 [AI RATIONAL] \(player.rawValue) is thinking. Eligible pawns: \(eligiblePawns)", level: .debug)
        guard !eligiblePawns.isEmpty else { return nil }
        
        let currentPath = game.path(for: player)
        guard !currentPath.isEmpty else { return (eligiblePawns.first!, moveBackwards: false) }

        // --- Mirchi Mode: Tier 0.5 - Offensive Backward Capture ---
        if game.gameMode == .mirchi {
            let movesLeft = game.mirchiMovesRemaining[player, default: 0]
            for pawnId in eligiblePawns {
                if movesLeft > 0 && game.isValidBackwardMove(color: player, pawnId: pawnId) {
                    if let pawn = game.pawns[player]?.first(where: { $0.id == pawnId }),
                       let positionIndex = pawn.positionIndex {
                        
                        let destinationIndex = positionIndex - game.diceValue
                        let destination = currentPath[destinationIndex]
                        
                        if !game.isSafePosition(destination) && isOpponentAt(position: destination, in: game, excluding: player) {
                            GameLogger.shared.log("🤖 [AI RATIONAL] Found backward capture! Moving pawn \(pawnId).")
                            return (pawnId: pawnId, moveBackwards: true)
                        }
                    }
                }
            }
        }
        
        // --- Tier 1: Offensive - Prioritize Capturing an Opponent (Forward) ---
        for pawnId in eligiblePawns {
            if let pawn = game.pawns[player]?.first(where: { $0.id == pawnId }),
               let positionIndex = pawn.positionIndex {
                
                let destinationIndex = positionIndex + game.diceValue
                if destinationIndex < currentPath.count {
                    let destination = currentPath[destinationIndex]
                    
                    if !game.isSafePosition(destination) && isOpponentAt(position: destination, in: game, excluding: player) {
                        GameLogger.shared.log("🤖 [AI RATIONAL] Found forward capture! Moving pawn \(pawnId).")
                        return (pawnId: pawnId, moveBackwards: false)
                    }
                }
            }
        }
        
        // --- Tier 2: Defensive - Prioritize Moving Pawns From Unsafe "At Risk" Positions ---
        let atRiskPawns = eligiblePawns.filter { pawnId in
            if let pawn = game.pawns[player]?.first(where: { $0.id == pawnId }),
               let positionIndex = pawn.positionIndex,
               positionIndex < currentPath.count {
                return !game.isSafePosition(currentPath[positionIndex])
            }
            return false
        }
        
        if !atRiskPawns.isEmpty {
            let pawnToMove = atRiskPawns.max { (pawnIdA, pawnIdB) -> Bool in
                let posA = game.pawns[player]?.first(where: { $0.id == pawnIdA })?.positionIndex ?? 0
                let posB = game.pawns[player]?.first(where: { $0.id == pawnIdB })?.positionIndex ?? 0
                return posA < posB
            }
            if let pawnId = pawnToMove {
                GameLogger.shared.log("🤖 [AI RATIONAL] Found pawn(s) at risk. Moving the most advanced one: pawn \(pawnId).")
                return (pawnId: pawnId, moveBackwards: false)
            }
        }
        
        // --- Tier 3: Prioritize Moving a Pawn from Home on a Roll of 6 ---
        if game.diceValue == 6 {
            let homePawnId = eligiblePawns.first { pawnId in
                game.pawns[player]?.first(where: { $0.id == pawnId })?.positionIndex == nil
            }
            
            if let pawnToMove = homePawnId {
                GameLogger.shared.log("🤖 [AI RATIONAL] Rolled a 6. Prioritizing moving pawn \(pawnToMove) from home.")
                return (pawnId: pawnToMove, moveBackwards: false)
            }
        }

        // --- Mirchi Mode: Tier 3.5 - Defensive Backward Move to Safety ---
        if game.gameMode == .mirchi {
            let movesLeft = game.mirchiMovesRemaining[player, default: 0]
            // Only attempt this strategy if we have a comfortable number of backward moves
            if movesLeft > 1 {
                for pawnId in eligiblePawns {
                    if game.isValidBackwardMove(color: player, pawnId: pawnId) {
                        if let pawn = game.pawns[player]?.first(where: { $0.id == pawnId }),
                           let positionIndex = pawn.positionIndex {
                            let destinationIndex = positionIndex - game.diceValue
                            if game.isSafePosition(currentPath[destinationIndex]) {
                                GameLogger.shared.log("🤖 [AI RATIONAL] Found backward move to safety. Moving pawn \(pawnId).")
                                return (pawnId: pawnId, moveBackwards: true)
                            }
                        }
                    }
                }
            }
        }

        // --- Tier 4: Positional - Prioritize Moving Pawns into a Safe Zone (Forward) ---
        for pawnId in eligiblePawns {
            if let pawn = game.pawns[player]?.first(where: { $0.id == pawnId }),
               let positionIndex = pawn.positionIndex {
                
                let destinationIndex = positionIndex + game.diceValue
                if destinationIndex < currentPath.count && game.isSafePosition(currentPath[destinationIndex]) {
                    GameLogger.shared.log("🤖 [AI RATIONAL] Found forward move to a safe space. Moving pawn \(pawnId).")
                    return (pawnId: pawnId, moveBackwards: false)
                }
            }
        }
        
        // --- Tier 5: Fallback - Move the Most Advanced Pawn ---
        let pawnToMove = eligiblePawns.max { (pawnIdA, pawnIdB) -> Bool in
            let posA = game.pawns[player]?.first(where: { $0.id == pawnIdA })?.positionIndex ?? 0
            let posB = game.pawns[player]?.first(where: { $0.id == pawnIdB })?.positionIndex ?? 0
            return posA < posB
        }
        if let pawnId = pawnToMove {
            GameLogger.shared.log("🤖 [AI RATIONAL] No optimal move found. Moving most advanced pawn: \(pawnId).")
            return (pawnId: pawnId, moveBackwards: false)
        }
        
        // --- Final Safety Net: If all else fails, pick a random eligible pawn ---
        if let randomPawn = eligiblePawns.randomElement() {
            GameLogger.shared.log("🤖 [AI RATIONAL] CRITICAL FALLBACK. Moving random pawn: \(randomPawn).")
            return (pawnId: randomPawn, moveBackwards: false)
        }

        return nil
    }
}


/// An AI strategy that prioritizes aggressive moves to capture or chase opponents.
struct AggressiveMoveStrategy: AILogicStrategy {

    func selectPawnMovementStrategy(from eligiblePawns: Set<Int>, for player: PlayerColor, in game: LudoGame) -> AIPlayerMove? {
        GameLogger.shared.log("🤖 [AI BERSERKER] \(player.rawValue) is thinking. Eligible pawns: \(eligiblePawns)", level: .debug)
        guard !eligiblePawns.isEmpty else { return nil }
        
        let currentPath = game.path(for: player)
        guard !currentPath.isEmpty else { return (eligiblePawns.first!, moveBackwards: false) }

        // --- Tier 1: Capture at All Costs (Forward and Backward) ---
        for pawnId in eligiblePawns {
            if let pawn = game.pawns[player]?.first(where: { $0.id == pawnId }),
               let positionIndex = pawn.positionIndex {
                
                // Check for FORWARD capture
                let forwardDestIndex = positionIndex + game.diceValue
                if forwardDestIndex < currentPath.count {
                    let destination = currentPath[forwardDestIndex]
                    if !game.isSafePosition(destination) && isOpponentAt(position: destination, in: game, excluding: player) {
                        GameLogger.shared.log("🤖 [AI BERSERKER] Found forward capture! Moving pawn \(pawnId).")
                        return (pawnId: pawnId, moveBackwards: false)
                    }
                }

                // Check for BACKWARD capture (Mirchi Mode only)
                if game.gameMode == .mirchi && game.isValidBackwardMove(color: player, pawnId: pawnId) {
                    let backwardDestIndex = positionIndex - game.diceValue
                    let destination = currentPath[backwardDestIndex]
                    if !game.isSafePosition(destination) && isOpponentAt(position: destination, in: game, excluding: player) {
                        GameLogger.shared.log("🤖 [AI BERSERKER] Found backward capture! Moving pawn \(pawnId).")
                        return (pawnId: pawnId, moveBackwards: true)
                    }
                }
            }
        }
        
        // --- Tier 1.5: Probabilistic Home Exit on a 6 ---
        if game.diceValue == 6 {
            let homePawns = eligiblePawns.filter { pawnId in
                game.pawns[player]?.first(where: { $0.id == pawnId })?.positionIndex == nil
            }
            if !homePawns.isEmpty {
                if Double.random(in: 0.0..<1.0) < 0.6 {
                    GameLogger.shared.log("🤖 [AI BERSERKER] Rolled a 6, probabilistic choice to move pawn from home.")
                    return (pawnId: homePawns.first!, moveBackwards: false)
                }
            }
        }
        
        // --- Tier 2: Relentless Chase ---
        var chaseCandidates: [(pawnId: Int, minDistance: Int)] = []
        for pawnId in eligiblePawns {
            guard let pawn = game.pawns[player]?.first(where: { $0.id == pawnId }),
                  let positionIndex = pawn.positionIndex else { continue }
            let destinationIndex = positionIndex + game.diceValue
            if destinationIndex < currentPath.count {
                let destination = currentPath[destinationIndex]
                var closestOpponentDistance = Int.max
                for (opponentColor, opponentPawns) in game.pawns where opponentColor != player {
                    let opponentPath = game.path(for: opponentColor)
                    guard !opponentPath.isEmpty else { continue }
                    for opponentPawn in opponentPawns {
                        if let opponentIndex = opponentPawn.positionIndex,
                           opponentIndex >= 0 && opponentIndex < opponentPath.count {
                            let opponentPosition = opponentPath[opponentIndex]
                            let distance = manhattanDistance(from: destination, to: opponentPosition)
                            closestOpponentDistance = min(closestOpponentDistance, distance)
                        }
                    }
                }
                if closestOpponentDistance != Int.max {
                    chaseCandidates.append((pawnId: pawnId, minDistance: closestOpponentDistance))
                }
            }
        }

        if !chaseCandidates.isEmpty {
            if let bestChaseMove = chaseCandidates.min(by: { $0.minDistance < $1.minDistance })?.pawnId {
                 GameLogger.shared.log("🤖 [AI BERSERKER] No capture found. Chasing with pawn \(bestChaseMove) to get closer.")
                return (pawnId: bestChaseMove, moveBackwards: false)
            }
        }
        
        // --- Tier 2.5: Defensive Retreat to Safety (Mirchi Mode) ---
        if game.gameMode == .mirchi {
            for pawnId in eligiblePawns {
                if game.isValidBackwardMove(color: player, pawnId: pawnId) {
                    if let pawn = game.pawns[player]?.first(where: { $0.id == pawnId }),
                       let positionIndex = pawn.positionIndex {
                        let destinationIndex = positionIndex - game.diceValue
                        if game.isSafePosition(currentPath[destinationIndex]) {
                            GameLogger.shared.log("🤖 [AI BERSERKER] No chase possible. Retreating pawn \(pawnId) to safety.")
                            return (pawnId: pawnId, moveBackwards: true)
                        }
                    }
                }
            }
        }

        // --- Tier 3: Last Resort ---
        let fallbackMove = eligiblePawns.max { (pawnIdA, pawnIdB) -> Bool in
            let posA = game.pawns[player]?.first(where: { $0.id == pawnIdA })?.positionIndex ?? -1
            let posB = game.pawns[player]?.first(where: { $0.id == pawnIdB })?.positionIndex ?? -1
            return posA < posB
        }
        if let pawnId = fallbackMove {
            GameLogger.shared.log("🤖 [AI BERSERKER] No other move possible. Making fallback move with pawn \(pawnId).")
            return (pawnId: pawnId, moveBackwards: false)
        }

        // --- Final Safety Net: If all else fails, pick a random eligible pawn ---
        if let randomPawn = eligiblePawns.randomElement() {
            GameLogger.shared.log("🤖 [AI BERSERKER] CRITICAL FALLBACK. Moving random pawn: \(randomPawn).")
            return (pawnId: randomPawn, moveBackwards: false)
        }

        return nil
    }

    /// Calculates the Manhattan distance between two board positions.
    private func manhattanDistance(from: Position, to: Position) -> Int {
        return abs(from.row - to.row) + abs(from.col - to.col)
    }
}

/// An AI strategy specifically for testing that always prioritizes moving backward if possible.
struct BackwardOnlyMoveStrategy: AILogicStrategy {
    func selectPawnMovementStrategy(from eligiblePawns: Set<Int>, for player: PlayerColor, in game: LudoGame) -> AIPlayerMove? {
        guard !eligiblePawns.isEmpty else { return nil }

        // --- Priority 1: Find any valid backward move ---
        if game.gameMode == .mirchi {
            for pawnId in eligiblePawns {
                if game.isValidBackwardMove(color: player, pawnId: pawnId) {
                    GameLogger.shared.log("🤖 [AI BACKWARD TEST] Found valid backward move for pawn \(pawnId). Selecting it.", level: .debug)
                    return (pawnId: pawnId, moveBackwards: true)
                }
            }
        }

        // --- Priority 2: Fallback to any forward move ---
        // If no backward move was found, just pick the first available pawn and move it forward.
        if let pawnId = eligiblePawns.first {
            GameLogger.shared.log("🤖 [AI BACKWARD TEST] No backward move possible. Falling back to forward move for pawn \(pawnId).", level: .debug)
            return (pawnId: pawnId, moveBackwards: false)
        }
        
        return nil
    }
} 
 