import SwiftUI

// MARK: - Ludo Color Palette ---------------------------------------------------

extension Color {
    // Yellow
    static let ludoYellowPrimary   = Color(red: 240/255, green: 200/255, blue:   8/255)
    static let ludoYellowSecondary = Color(red: 250/255, green: 245/255, blue: 198/255)

    // Blue
    static let ludoBluePrimary   = Color(red:  52/255, green:  89/255, blue: 149/255)
    static let ludoBlueSecondary = Color(red: 215/255, green: 237/255, blue: 255/255)

    // Green
    static let ludoGreenPrimary   = Color(red:  50/255, green: 159/255, blue:  91/255)
    static let ludoGreenSecondary = Color(red: 193/255, green: 242/255, blue: 207/255)

    // Red
    static let ludoRedPrimary   = Color(red: 251/255, green:  77/255, blue:  61/255)
    static let ludoRedSecondary = Color(red: 255/255, green: 222/255, blue: 224/255)
}

// MARK: - PlayerColor ----------------------------------------------------------

enum PlayerColor: String, CaseIterable, Identifiable {
    case red, green, yellow, blue
    var id: String { rawValue }
}

// MARK: - PlayerColor ↔ Palette Helpers ---------------------------------------

extension PlayerColor {
    /// Primary (darker) shade used for board houses, borders, etc.
    var primaryColor: Color {
        switch self {
        case .red:    return .ludoRedPrimary
        case .green:  return .ludoGreenPrimary
        case .yellow: return .ludoYellowPrimary
        case .blue:   return .ludoBluePrimary
        }
    }

    /// Secondary (lighter) shade used for inner cells, panels, etc.
    var secondaryColor: Color {
        switch self {
        case .red:    return .ludoRedSecondary
        case .green:  return .ludoGreenSecondary
        case .yellow: return .ludoYellowSecondary
        case .blue:   return .ludoBlueSecondary
        }
    }

    // Legacy helpers kept for existing code -----------------------------------

    /// Existing helper that many views call for stroke/fill colors.
    func toSwiftUIColor(for _: PlayerColor) -> Color {
        primaryColor
    }

    /// Legacy property still used across the codebase; maps to primaryColor.
    var color: Color {
        primaryColor
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

    static let captureAnimationCellsPerSecond: Double = 12.0 // Controls the speed of the capture animation
    static let diceAnimationDuration: TimeInterval = 0.8
}

// MARK: - Asset Constants --------------------------------------------------------

public enum PawnAssets {
    // Red
    static let redMarble = "pawn_red_marble_filled"
    static let redMirchi = "pawn_red_mirchi"
    
    // Yellow
    static let yellowMarble = "pawn_yellow_marble_filled"
    static let yellowMango = "pawn_yellow_mango"
    
    // Green
    static let greenMarble = "pawn_green_marble_filled"
    static let greenMango = "pawn_mango_green"
    
    // Blue
    static let blueMarble = "pawn_blue_marble_filled"
    
    // Generic/Other
    static let alien = "avatar_alien"
    static let mirchiIndicator = "mirchi" // UI icon for mirchi moves, not the pawn itself
    
    // Splash
    static let mirchiSplash = "pawn_mirchi_splash"
    
    static func defaultMarble(for color: PlayerColor) -> String {
        switch color {
        case .red: return redMarble
        case .green: return greenMarble
        case .yellow: return yellowMarble
        case .blue: return blueMarble
        }
    }
}

