import SwiftUI

enum PlayerColor: String, CaseIterable, Identifiable {
    case red, green, yellow, blue
    var id: String { rawValue }
    
    func toSwiftUIColor(for color: PlayerColor) -> Color {
        switch self {
        case .red:
            return .red
        case .green:
            return .green
        case .yellow:
            return .yellow
        case .blue:
            return .blue
        }
    }
    
    var color: Color {
        switch self {
        case .red: return .red
        case .green: return .green
        case .yellow: return .yellow
        case .blue: return .blue
        }
    }
} 

public enum GameConstants {
    // Scoring
    static let maxScorePerPawn = 16
    static let capturePoints = 3
    
    // Dice rolling
    static let weightedSixProbability = 1.0 / 3.0
    static let standardDiceSides = 6
    
    // Timing
    static let turnAdvanceDelay: TimeInterval = 1.2
    static let aiThinkingDelay: TimeInterval = 1.0
    
    // Game state
    static let pawnsPerPlayer = 4
    static let finishedPawnIndex = -1
    static let homePawnIndex: Int? = nil
    static let startingPathIndex = 0
    
    // Dice values
    static let sixDiceRoll = 6


    static let diceAnimationDuration: TimeInterval = 0.8
}

