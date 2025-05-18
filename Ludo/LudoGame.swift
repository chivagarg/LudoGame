import Foundation

enum PlayerColor: String, CaseIterable, Identifiable {
    case red, green, yellow, blue
    var id: String { rawValue }
}

struct Position: Equatable {
    var row: Int
    var col: Int
}

struct Pawn: Identifiable {
    let id: Int // 0-3 for each player
    let color: PlayerColor
    var positionIndex: Int? // nil = at home, 0...N = on path, -1 = finished
}

class LudoGame: ObservableObject {
    @Published var currentPlayer: PlayerColor = .red
    @Published var diceValue: Int = 1
    @Published var gameStarted: Bool = false

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
        Position(row: 6, col: 1), Position(row: 6, col: 2), Position(row: 6, col: 3), Position(row: 6, col: 4), Position(row: 6, col: 5), Position(row: 6, col: 6),
        Position(row: 5, col: 6), Position(row: 4, col: 6), Position(row: 3, col: 6), Position(row: 2, col: 6), Position(row: 1, col: 6), Position(row: 0, col: 6),
        Position(row: 0, col: 7), Position(row: 0, col: 8),
        Position(row: 1, col: 8), Position(row: 2, col: 8), Position(row: 3, col: 8), Position(row: 4, col: 8), Position(row: 5, col: 8), Position(row: 6, col: 8),
        Position(row: 6, col: 9), Position(row: 6, col: 10), Position(row: 6, col: 11), Position(row: 6, col: 12), Position(row: 6, col: 13), Position(row: 6, col: 14),
        Position(row: 7, col: 14), Position(row: 8, col: 14),
        Position(row: 8, col: 13), Position(row: 8, col: 12), Position(row: 8, col: 11), Position(row: 8, col: 10), Position(row: 8, col: 9), Position(row: 8, col: 8),
        Position(row: 9, col: 8), Position(row: 10, col: 8), Position(row: 11, col: 8), Position(row: 12, col: 8), Position(row: 13, col: 8), Position(row: 14, col: 8),
        Position(row: 14, col: 7), Position(row: 14, col: 6),
        Position(row: 13, col: 6), Position(row: 12, col: 6), Position(row: 11, col: 6), Position(row: 10, col: 6), Position(row: 9, col: 6), Position(row: 8, col: 6),
        Position(row: 8, col: 5), Position(row: 8, col: 4), Position(row: 8, col: 3), Position(row: 8, col: 2), Position(row: 8, col: 1), Position(row: 8, col: 0),
        Position(row: 7, col: 0), // End of main path loop for Red
        Position(row: 7, col: 1), Position(row: 7, col: 2), Position(row: 7, col: 3), Position(row: 7, col: 4), Position(row: 7, col: 5), // Red Safe Zone
        Position(row: 7, col: 6) // Red Home
    ]

    static let greenPath: [Position] = [
        Position(row: 1, col: 8), Position(row: 2, col: 8), Position(row: 3, col: 8), Position(row: 4, col: 8), Position(row: 5, col: 8), Position(row: 6, col: 8),
        Position(row: 6, col: 9), Position(row: 6, col: 10), Position(row: 6, col: 11), Position(row: 6, col: 12), Position(row: 6, col: 13), Position(row: 6, col: 14),
        Position(row: 7, col: 14), Position(row: 8, col: 14),
        Position(row: 8, col: 13), Position(row: 8, col: 12), Position(row: 8, col: 11), Position(row: 8, col: 10), Position(row: 8, col: 9), Position(row: 8, col: 8),
        Position(row: 9, col: 8), Position(row: 10, col: 8), Position(row: 11, col: 8), Position(row: 12, col: 8), Position(row: 13, col: 8), Position(row: 14, col: 8),
        Position(row: 14, col: 7), Position(row: 14, col: 6),
        Position(row: 13, col: 6), Position(row: 12, col: 6), Position(row: 11, col: 6), Position(row: 10, col: 6), Position(row: 9, col: 6), Position(row: 8, col: 6),
        Position(row: 8, col: 5), Position(row: 8, col: 4), Position(row: 8, col: 3), Position(row: 8, col: 2), Position(row: 8, col: 1), Position(row: 8, col: 0),
        Position(row: 7, col: 0), Position(row: 6, col: 0),
        Position(row: 5, col: 0), Position(row: 4, col: 0), Position(row: 3, col: 0), Position(row: 2, col: 0), Position(row: 1, col: 0), Position(row: 0, col: 0), // Looping back to start
        Position(row: 0, col: 6), Position(row: 0, col: 7), // End of main path loop for Green
        Position(row: 1, col: 7), Position(row: 2, col: 7), Position(row: 3, col: 7), Position(row: 4, col: 7), Position(row: 5, col: 7), // Green Safe Zone
        Position(row: 6, col: 7) // Green Home
    ]

    static let yellowPath: [Position] = [
        Position(row: 8, col: 13), Position(row: 8, col: 12), Position(row: 8, col: 11), Position(row: 8, col: 10), Position(row: 8, col: 9), Position(row: 8, col: 8),
        Position(row: 9, col: 8), Position(row: 10, col: 8), Position(row: 11, col: 8), Position(row: 12, col: 8), Position(row: 13, col: 8), Position(row: 14, col: 8),
        Position(row: 14, col: 7), Position(row: 14, col: 6),
        Position(row: 13, col: 6), Position(row: 12, col: 6), Position(row: 11, col: 6), Position(row: 10, col: 6), Position(row: 9, col: 6), Position(row: 8, col: 6),
        Position(row: 8, col: 5), Position(row: 8, col: 4), Position(row: 8, col: 3), Position(row: 8, col: 2), Position(row: 8, col: 1), Position(row: 8, col: 0),
        Position(row: 7, col: 0), Position(row: 6, col: 0),
        Position(row: 5, col: 0), Position(row: 4, col: 0), Position(row: 3, col: 0), Position(row: 2, col: 0), Position(row: 1, col: 0), Position(row: 0, col: 0),
        Position(row: 0, col: 6), Position(row: 0, col: 7), Position(row: 0, col: 8),
        Position(row: 1, col: 8), Position(row: 2, col: 8), Position(row: 3, col: 8), Position(row: 4, col: 8), Position(row: 5, col: 8), Position(row: 6, col: 8),
        Position(row: 6, col: 9), Position(row: 6, col: 10), Position(row: 6, col: 11), Position(row: 6, col: 12), Position(row: 6, col: 13), Position(row: 6, col: 14), // Looping back to start
        Position(row: 7, col: 14), // End of main path loop for Yellow
        Position(row: 7, col: 13), Position(row: 7, col: 12), Position(row: 7, col: 11), Position(row: 7, col: 10), Position(row: 7, col: 9), // Yellow Safe Zone
        Position(row: 7, col: 8) // Yellow Home
    ]

    static let bluePath: [Position] = [
        Position(row: 13, col: 6), Position(row: 12, col: 6), Position(row: 11, col: 6), Position(row: 10, col: 6), Position(row: 9, col: 6), Position(row: 8, col: 6),
        Position(row: 8, col: 5), Position(row: 8, col: 4), Position(row: 8, col: 3), Position(row: 8, col: 2), Position(row: 8, col: 1), Position(row: 8, col: 0),
        Position(row: 7, col: 0), Position(row: 6, col: 0),
        Position(row: 6, col: 1), Position(row: 6, col: 2), Position(row: 6, col: 3), Position(row: 6, col: 4), Position(row: 6, col: 5), Position(row: 6, col: 6),
        Position(row: 0, col: 6), Position(row: 0, col: 7), Position(row: 0, col: 8),
        Position(row: 1, col: 8), Position(row: 2, col: 8), Position(row: 3, col: 8), Position(row: 4, col: 8), Position(row: 5, col: 8), Position(row: 6, col: 8),
        Position(row: 6, col: 9), Position(row: 6, col: 10), Position(row: 6, col: 11), Position(row: 6, col: 12), Position(row: 6, col: 13), Position(row: 6, col: 14),
        Position(row: 7, col: 14), Position(row: 8, col: 14),
        Position(row: 8, col: 13), Position(row: 8, col: 12), Position(row: 8, col: 11), Position(row: 8, col: 10), Position(row: 8, col: 9), Position(row: 8, col: 8), // Looping back to start
        Position(row: 14, col: 8), Position(row: 14, col: 7), // End of main path loop for Blue
        Position(row: 13, col: 7), Position(row: 12, col: 7), Position(row: 11, col: 7), Position(row: 10, col: 7), Position(row: 9, col: 7), // Blue Safe Zone
        Position(row: 8, col: 7) // Blue Home
    ]

    @Published var pawns: [PlayerColor: [Pawn]] = [
        .red: (0..<4).map { Pawn(id: $0, color: .red, positionIndex: nil) },
        .green: (0..<4).map { Pawn(id: $0, color: .green, positionIndex: nil) },
        .yellow: (0..<4).map { Pawn(id: $0, color: .yellow, positionIndex: nil) },
        .blue: (0..<4).map { Pawn(id: $0, color: .blue, positionIndex: nil) }
    ]
    
    func rollDice() {
        diceValue = Int.random(in: 1...6)
    }
    
    func nextTurn() {
        let colors = PlayerColor.allCases
        if let currentIndex = colors.firstIndex(of: currentPlayer) {
            let nextIndex = (currentIndex + 1) % colors.count
            currentPlayer = colors[nextIndex]
        }
    }
    
    func startGame() {
        gameStarted = true
        currentPlayer = .red
        // Reset pawns
        pawns = [
            .red: (0..<4).map { Pawn(id: $0, color: .red, positionIndex: nil) },
            .green: (0..<4).map { Pawn(id: $0, color: .green, positionIndex: nil) },
            .yellow: (0..<4).map { Pawn(id: $0, color: .yellow, positionIndex: nil) },
            .blue: (0..<4).map { Pawn(id: $0, color: .blue, positionIndex: nil) }
        ]
    }
    
    // Helper to get the path for a color
    func path(for color: PlayerColor) -> [Position] {
        switch color {
        case .red: return Self.redPath
        case .green: return Self.greenPath
        case .yellow: return Self.yellowPath
        case .blue: return Self.bluePath
        }
    }

    // MARK: - Game Logic

    // Function to move a pawn
    func movePawn(color: PlayerColor, pawnId: Int, steps: Int) {
        guard let pawnIndex = pawns[color]?.firstIndex(where: { $0.id == pawnId }) else { return }
        var pawn = pawns[color]![pawnIndex] // Get a mutable copy
        let currentPath = path(for: color)

        // If pawn is at home and dice is not 6, it cannot move
        if pawn.positionIndex == nil && steps != 6 {
            print("\(color.rawValue.capitalized) pawn \(pawnId) is at home and rolled a \(steps). Needs a 6 to move out.")
            return
        }

        // If pawn is at home and dice is 6, move to the entry position
        if pawn.positionIndex == nil && steps == 6 {
            pawn.positionIndex = 0 // Assuming the entry is the first position in the color's path
            pawns[color]?[pawnIndex] = pawn // Update directly in the dictionary
            print("\(color.rawValue.capitalized) pawn \(pawnId) moved out of home.")
            return
        }

        // If pawn is on the path, calculate the new position
        if let currentIndex = pawn.positionIndex {
            let newIndex = currentIndex + steps

            // Check if the new position is within the bounds of the path
            if newIndex < currentPath.count - 1 {
                // Moved to a position on the path (not the final spot)
                pawns[color]?[pawnIndex].positionIndex = newIndex
                print("\(color.rawValue.capitalized) pawn \(pawnId) moved from index \(currentIndex) to \(newIndex).")
                // checkPosition(for: &pawns[color]![pawnIndex], at: newIndex)
            } else if newIndex == currentPath.count - 1 { // This condition is now correctly reached for the final spot
                 // Pawn reached home exactly
                pawns[color]?[pawnIndex].positionIndex = -1 // Mark as finished
                print("DEBUG: Pawn \(pawnId) of color \(color.rawValue) reached home exactly. Setting positionIndex to -1.") // Added debug print\n                print("\(color.rawValue.capitalized) pawn \(pawnId) reached home.")
                // TODO: Handle winning condition
            } else {
                // Overshot, cannot move
                print("\(color.rawValue.capitalized) pawn \(pawnId) at index \(currentIndex) with dice \(steps) overshot the path.")
                return
            }
        }
    }

    // Helper to update a pawn in the published pawns dictionary
    // (This helper is no longer strictly needed with the direct update approach in movePawn,
    // but keeping it for now in case it's used elsewhere or for future logic)
    private func updatePawn(_ pawn: Pawn) {
        if let index = pawns[pawn.color]?.firstIndex(where: { $0.id == pawn.id }) {
            pawns[pawn.color]?[index] = pawn
            // print("Updated \(pawn.color.rawValue.capitalized) pawn \(pawn.id) to positionIndex: \(pawn.positionIndex ?? -2).") // Debug print
        }
    }
} 
