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
