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

    // A threshold for how close a pawn must be to an opponent to be considered a "chase".
    private let chaseDistanceThreshold = 8

    func selectPawnToMove(from eligiblePawns: Set<Int>, for player: PlayerColor, in game: LudoGame) -> Int? {
        guard !eligiblePawns.isEmpty else { return nil }
        
        let currentPath = game.path(for: player)
        guard !currentPath.isEmpty else { return eligiblePawns.first }

        // --- Tier 1: Offensive - Prioritize Capturing an Opponent ---
        for pawnId in eligiblePawns {
            if let pawn = game.pawns[player]?.first(where: { $0.id == pawnId }),
               let positionIndex = pawn.positionIndex {
                
                let destinationIndex = positionIndex + game.diceValue
                if destinationIndex < currentPath.count {
                    let destination = currentPath[destinationIndex]
                    
                    if !game.isSafePosition(destination) {
                        for (opponentColor, opponentPawns) in game.pawns where opponentColor != player {
                            for opponentPawn in opponentPawns {
                                let opponentPath = game.path(for: opponentColor)
                                if let opponentIndex = opponentPawn.positionIndex,
                                   !opponentPath.isEmpty,
                                   opponentIndex < opponentPath.count {
                                    
                                    if opponentPath[opponentIndex] == destination {
                                        print("🤖 [AI AGGRESSIVE] Found capture! Moving pawn \(pawnId).")
                                        return pawnId
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // --- Tier 2: Prioritize Moving a Pawn from Home on a Roll of 6 ---
        if game.diceValue == 6 {
            let homePawnId = eligiblePawns.first { pawnId in
                if let pawn = game.pawns[player]?.first(where: { $0.id == pawnId }) {
                    return pawn.positionIndex == nil
                }
                return false
            }
            
            if let pawnToMove = homePawnId {
                print("🤖 [AI AGGRESSIVE] Rolled a 6. Prioritizing moving pawn \(pawnToMove) from home.")
                return pawnToMove
            }
        }
        
        // --- Tier 3: Chase an Opponent ---
        // Find the move that results in the smallest distance to any single opponent.
        var chaseCandidates: [(pawnId: Int, minDistance: Int)] = []

        for pawnId in eligiblePawns {
            if let pawn = game.pawns[player]?.first(where: { $0.id == pawnId }),
               let positionIndex = pawn.positionIndex {

                let destinationIndex = positionIndex + game.diceValue
                if destinationIndex < currentPath.count {
                    let destination = currentPath[destinationIndex]
                    var closestOpponentDistance = Int.max

                    // Find the distance to the nearest opponent from this move's destination
                    for (opponentColor, opponentPawns) in game.pawns where opponentColor != player {
                        for opponentPawn in opponentPawns {
                            let opponentPath = game.path(for: opponentColor)
                            if let opponentIndex = opponentPawn.positionIndex, !opponentPath.isEmpty, opponentIndex < opponentPath.count {
                                let opponentPosition = opponentPath[opponentIndex]
                                let distance = manhattanDistance(from: destination, to: opponentPosition)
                                closestOpponentDistance = min(closestOpponentDistance, distance)
                            }
                        }
                    }
                    
                    if closestOpponentDistance <= chaseDistanceThreshold {
                        chaseCandidates.append((pawnId: pawnId, minDistance: closestOpponentDistance))
                    }
                }
            }
        }

        // If we have any valid chase moves, pick the one that gets us closest.
        if !chaseCandidates.isEmpty {
            let bestChaseMove = chaseCandidates.min(by: { $0.minDistance < $1.minDistance })
            if let pawnToMove = bestChaseMove?.pawnId {
                 print("🤖 [AI AGGRESSIVE] Found chase opportunity. Moving pawn \(pawnToMove).")
                return pawnToMove
            }
        }


        // --- Tier 4: Progress Safely / Furthest Pawn ---
        // If no attack is possible, move based on position.
        // Prioritize moves that land on a safe spot.
        let safeMovers = eligiblePawns.filter { pawnId in
            if let pawn = game.pawns[player]?.first(where: { $0.id == pawnId }),
               let positionIndex = pawn.positionIndex {
                let destinationIndex = positionIndex + game.diceValue
                if destinationIndex < currentPath.count {
                    return game.isSafePosition(currentPath[destinationIndex])
                }
            }
            return false
        }

        // If there are moves that land on a safe spot, take the one from the most advanced pawn.
        if !safeMovers.isEmpty {
            let pawnToMove = safeMovers.max { (pawnIdA, pawnIdB) -> Bool in
                let posA = game.pawns[player]?.first(where: { $0.id == pawnIdA })?.positionIndex ?? 0
                let posB = game.pawns[player]?.first(where: { $0.id == pawnIdB })?.positionIndex ?? 0
                return posA < posB
            }
            print("🤖 [AI AGGRESSIVE] No chase found. Moving most advanced pawn to a safe spot: \(pawnToMove ?? -1).")
            return pawnToMove
        }

        // --- Tier 5: Fallback - Move the Most Advanced Pawn ---
        // If no safe move is possible, just move the most advanced pawn.
        let pawnToMove = eligiblePawns.max { (pawnIdA, pawnIdB) -> Bool in
            let posA = game.pawns[player]?.first(where: { $0.id == pawnIdA })?.positionIndex ?? 0
            let posB = game.pawns[player]?.first(where: { $0.id == pawnIdB })?.positionIndex ?? 0
            return posA < posB
        }
        print("🤖 [AI AGGRESSIVE] No optimal move found. Moving most advanced pawn: \(pawnToMove ?? -1).")
        return pawnToMove
    }

    /// Calculates the Manhattan distance between two board positions.
    private func manhattanDistance(from pos1: Position, to pos2: Position) -> Int {
        return abs(pos1.row - pos2.row) + abs(pos1.col - pos2.col)
    }
} 
