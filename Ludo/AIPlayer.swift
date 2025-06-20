import Foundation

/// A protocol that defines the decision-making logic for an AI player.
protocol AILogicStrategy {
    /// Selects a pawn to move from a set of eligible pawns.
    /// - Parameters:
    ///   - eligiblePawns: A set of pawn IDs that are legal to move.
    ///   - game: The current state of the Ludo game.
    /// - Returns: The ID of the chosen pawn, or `nil` if no choice could be made.
    func selectPawnToMove(from eligiblePawns: Set<Int>, for player: PlayerColor, in game: LudoGame) -> Int?
}


/// A simple AI strategy that chooses a pawn to move completely at random.
struct RandomMoveStrategy: AILogicStrategy {
    func selectPawnToMove(from eligiblePawns: Set<Int>, for player: PlayerColor, in game: LudoGame) -> Int? {
        // For the simplest strategy, just pick a random eligible pawn.
        return eligiblePawns.randomElement()
    }
}


/// An AI strategy that attempts to make rational moves based on a prioritized set of rules.
struct RationalMoveStrategy: AILogicStrategy {
    
    func selectPawnToMove(from eligiblePawns: Set<Int>, for player: PlayerColor, in game: LudoGame) -> Int? {
        guard !eligiblePawns.isEmpty else { return nil }
        
        let currentPath = game.path(for: player)
        guard !currentPath.isEmpty else { return eligiblePawns.first } // Failsafe

        // --- Tier 1: Offensive - Prioritize Capturing an Opponent ---
        for pawnId in eligiblePawns {
            if let pawn = game.pawns[player]?.first(where: { $0.id == pawnId }),
               let positionIndex = pawn.positionIndex {
                
                let destinationIndex = positionIndex + game.diceValue
                if destinationIndex < currentPath.count {
                    let destination = currentPath[destinationIndex]
                    
                    // A capture is only possible on an unsafe space
                    if !game.isSafePosition(destination) {
                        for (opponentColor, opponentPawns) in game.pawns where opponentColor != player {
                            for opponentPawn in opponentPawns {
                                let opponentPath = game.path(for: opponentColor)
                                if let opponentIndex = opponentPawn.positionIndex,
                                   opponentIndex >= 0,
                                   opponentIndex < opponentPath.count {
                                    
                                    if opponentPath[opponentIndex] == destination {
                                        print("🤖 [AI STRATEGY] Found capture opportunity! Moving pawn \(pawnId) to capture pawn from \(opponentColor.rawValue).")
                                        return pawnId // Highest priority: execute capture
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // --- Tier 2: Defensive - Prioritize Moving Pawns From Unsafe "At Risk" Positions ---
        // An "at risk" pawn is one that is currently on an unsafe square.
        let atRiskPawns = eligiblePawns.filter { pawnId in
            if let pawn = game.pawns[player]?.first(where: { $0.id == pawnId }),
               let positionIndex = pawn.positionIndex {
                return !game.isSafePosition(currentPath[positionIndex])
            }
            return false
        }
        
        if !atRiskPawns.isEmpty {
            // Of the pawns at risk, move the one that is furthest along the path.
            let pawnToMove = atRiskPawns.max { (pawnIdA, pawnIdB) -> Bool in
                let posA = game.pawns[player]?.first(where: { $0.id == pawnIdA })?.positionIndex ?? 0
                let posB = game.pawns[player]?.first(where: { $0.id == pawnIdB })?.positionIndex ?? 0
                return posA < posB
            }
            print("🤖 [AI STRATEGY] Found pawn(s) at risk. Moving the most advanced one: pawn \(pawnToMove ?? -1).")
            return pawnToMove
        }
        
        // --- Tier 3: Prioritize Moving a Pawn from Home on a Roll of 6 ---
        if game.diceValue == 6 {
            let homePawnId = eligiblePawns.first { pawnId in
                if let pawn = game.pawns[player]?.first(where: { $0.id == pawnId }) {
                    return pawn.positionIndex == nil
                }
                return false
            }
            
            if let pawnToMove = homePawnId {
                print("🤖 [AI STRATEGY] Rolled a 6. Prioritizing moving pawn \(pawnToMove) from home.")
                return pawnToMove
            }
        }
        
        // --- Tier 4: Positional - Prioritize Moving Pawns into a Safe Zone ---
        for pawnId in eligiblePawns {
            if let pawn = game.pawns[player]?.first(where: { $0.id == pawnId }),
               let positionIndex = pawn.positionIndex {
                
                let destinationIndex = positionIndex + game.diceValue
                if destinationIndex < currentPath.count && game.isSafePosition(currentPath[destinationIndex]) {
                    print("🤖 [AI STRATEGY] Found move to a safe space. Moving pawn \(pawnId).")
                    return pawnId // Move a pawn into a safe position
                }
            }
        }
        
        // --- Tier 5: Fallback - Move the Most Advanced Pawn ---
        // If no other strategic move is found, just move the pawn that is furthest ahead.
        let pawnToMove = eligiblePawns.max { (pawnIdA, pawnIdB) -> Bool in
            let posA = game.pawns[player]?.first(where: { $0.id == pawnIdA })?.positionIndex ?? 0
            let posB = game.pawns[player]?.first(where: { $0.id == pawnIdB })?.positionIndex ?? 0
            return posA < posB
        }
        print("🤖 [AI STRATEGY] No optimal move found. Moving most advanced pawn: \(pawnToMove ?? -1).")
        return pawnToMove
    }
}


/// An AI strategy that prioritizes aggressive moves to capture or chase opponents.
struct AggressiveMoveStrategy: AILogicStrategy {

    func selectPawnToMove(from eligiblePawns: Set<Int>, for player: PlayerColor, in game: LudoGame) -> Int? {
        guard !eligiblePawns.isEmpty else { return nil }
        
        let currentPath = game.path(for: player)
        guard !currentPath.isEmpty else { return eligiblePawns.first }

        // --- Tier 1: Capture at All Costs ---
        // Find any move that results in a direct capture. This is the highest priority.
        for pawnId in eligiblePawns {
            if let pawn = game.pawns[player]?.first(where: { $0.id == pawnId }),
               let positionIndex = pawn.positionIndex {
                
                let destinationIndex = positionIndex + game.diceValue
                if destinationIndex < currentPath.count {
                    let destination = currentPath[destinationIndex]
                    
                    // A capture is only possible on an unsafe space.
                    if !game.isSafePosition(destination) {
                        for (opponentColor, opponentPawns) in game.pawns where opponentColor != player {
                            let opponentPath = game.path(for: opponentColor)
                            guard !opponentPath.isEmpty else { continue }
                            
                            for opponentPawn in opponentPawns {
                                if let opponentIndex = opponentPawn.positionIndex,
                                   opponentIndex >= 0 && opponentIndex < opponentPath.count {
                                    
                                    if opponentPath[opponentIndex] == destination {
                                        print("🤖 [AI BERSERKER] Found capture! Moving pawn \(pawnId).")
                                        return pawnId // Highest priority: execute capture.
                                    }
                                }
                            }
                        }
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
                // With a 60% probability, choose to move a pawn from home.
                if Double.random(in: 0.0..<1.0) < 0.6 {
                    print("🤖 [AI BERSERKER] Rolled a 6, probabilistic choice to move pawn from home.")
                    return homePawns.first!
                }
            }
        }
        
        // --- Tier 2: Relentless Chase ---
        // If no capture is possible, find the move that gets closest to any opponent.
        var chaseCandidates: [(pawnId: Int, minDistance: Int)] = []

        for pawnId in eligiblePawns {
            // Pawns at home can't chase yet, so we only consider pawns on the board.
            guard let pawn = game.pawns[player]?.first(where: { $0.id == pawnId }),
                  let positionIndex = pawn.positionIndex else { continue }

            let destinationIndex = positionIndex + game.diceValue
            if destinationIndex < currentPath.count {
                let destination = currentPath[destinationIndex]
                var closestOpponentDistance = Int.max

                // Find the distance to the nearest opponent from this move's destination.
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
                
                // If a valid distance was found, add it as a candidate.
                if closestOpponentDistance != Int.max {
                    chaseCandidates.append((pawnId: pawnId, minDistance: closestOpponentDistance))
                }
            }
        }

        // If we have any valid chase moves, pick the one that gets us closest.
        if !chaseCandidates.isEmpty {
            let bestChaseMove = chaseCandidates.min(by: { $0.minDistance < $1.minDistance })
            if let pawnToMove = bestChaseMove?.pawnId {
                 print("🤖 [AI BERSERKER] No capture found. Chasing with pawn \(pawnToMove) to get closer.")
                return pawnToMove
            }
        }
        
        // --- Tier 3: Last Resort ---
        // If no other move is possible (e.g., can't chase, must move from home), pick any valid move.
        // The most advanced pawn is a reasonable default.
        let fallbackMove = eligiblePawns.max { (pawnIdA, pawnIdB) -> Bool in
            let posA = game.pawns[player]?.first(where: { $0.id == pawnIdA })?.positionIndex ?? -1
            let posB = game.pawns[player]?.first(where: { $0.id == pawnIdB })?.positionIndex ?? -1
            return posA < posB
        }
        print("🤖 [AI BERSERKER] No capture or chase possible. Making fallback move with pawn \(fallbackMove ?? -1).")
        return fallbackMove
    }

    /// Calculates the Manhattan distance between two board positions.
    private func manhattanDistance(from: Position, to: Position) -> Int {
        return abs(from.row - to.row) + abs(from.col - to.col)
    }
} 
