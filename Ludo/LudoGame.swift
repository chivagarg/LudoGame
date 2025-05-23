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
    @Published var eligiblePawns: Set<Int> = []  // Track which pawns are eligible to move

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
        // Start at entry point
        Position(row: 1, col: 8), Position(row: 2, col: 8), Position(row: 3, col: 8), Position(row: 4, col: 8), Position(row: 5, col: 8), Position(row: 6, col: 8),
        // Right
        Position(row: 6, col: 9), Position(row: 6, col: 10), Position(row: 6, col: 11), Position(row: 6, col: 12), Position(row: 6, col: 13), Position(row: 6, col: 14),
        // Down
        Position(row: 7, col: 14), Position(row: 8, col: 14),
        // Left
        Position(row: 8, col: 13), Position(row: 8, col: 12), Position(row: 8, col: 11), Position(row: 8, col: 10), Position(row: 8, col: 9), Position(row: 8, col: 8),
        // Down
        Position(row: 9, col: 8), Position(row: 10, col: 8), Position(row: 11, col: 8), Position(row: 12, col: 8), Position(row: 13, col: 8), Position(row: 14, col: 8),
        // Left
        Position(row: 14, col: 7), Position(row: 14, col: 6),
        // Up
        Position(row: 13, col: 6), Position(row: 12, col: 6), Position(row: 11, col: 6), Position(row: 10, col: 6), Position(row: 9, col: 6), Position(row: 8, col: 6),
        // Left
        Position(row: 8, col: 5), Position(row: 8, col: 4), Position(row: 8, col: 3), Position(row: 8, col: 2), Position(row: 8, col: 1), Position(row: 8, col: 0),
        // Up
        Position(row: 7, col: 0), Position(row: 6, col: 0),
        // Right
        Position(row: 6, col: 1), Position(row: 6, col: 2), Position(row: 6, col: 3), Position(row: 6, col: 4), Position(row: 6, col: 5), Position(row: 6, col: 6),
        // Up
        Position(row: 5, col: 6), Position(row: 4, col: 6), Position(row: 3, col: 6), Position(row: 2, col: 6), Position(row: 1, col: 6), Position(row: 0, col: 6),
        // Right
        Position(row: 0, col: 7), // End of main path loop for Green
        Position(row: 1, col: 7), Position(row: 2, col: 7), Position(row: 3, col: 7), Position(row: 4, col: 7), Position(row: 5, col: 7), // Green Safe Zone
        Position(row: 6, col: 7) // Green Home
    ]

    static let yellowPath: [Position] = [
        // Left
        Position(row: 8, col: 13), Position(row: 8, col: 12), Position(row: 8, col: 11), Position(row: 8, col: 10), Position(row: 8, col: 9), Position(row: 8, col: 8),
        // Down
        Position(row: 9, col: 8), Position(row: 10, col: 8), Position(row: 11, col: 8), Position(row: 12, col: 8), Position(row: 13, col: 8), Position(row: 14, col: 8),
        // Left
        Position(row: 14, col: 7), Position(row: 14, col: 6),
        // Up
        Position(row: 13, col: 6), Position(row: 12, col: 6), Position(row: 11, col: 6), Position(row: 10, col: 6), Position(row: 9, col: 6), Position(row: 8, col: 6),
        // Left
        Position(row: 8, col: 5), Position(row: 8, col: 4), Position(row: 8, col: 3), Position(row: 8, col: 2), Position(row: 8, col: 1), Position(row: 8, col: 0),
        // Up
        Position(row: 7, col: 0), Position(row: 6, col: 0),
        // Right
        Position(row: 6, col: 1), Position(row: 6, col: 2), Position(row: 6, col: 3), Position(row: 6, col: 4), Position(row: 6, col: 5), Position(row: 6, col: 6),
        // Up
        Position(row: 5, col: 6), Position(row: 4, col: 6), Position(row: 3, col: 6), Position(row: 2, col: 6), Position(row: 1, col: 6), Position(row: 0, col: 6),
        // Right
        Position(row: 0, col: 7), Position(row: 0, col: 8),
        // Down
        Position(row: 1, col: 8), Position(row: 2, col: 8), Position(row: 3, col: 8), Position(row: 4, col: 8), Position(row: 5, col: 8), Position(row: 6, col: 8),
        // Right
        Position(row: 6, col: 9), Position(row: 6, col: 10), Position(row: 6, col: 11), Position(row: 6, col: 12), Position(row: 6, col: 13), Position(row: 6, col: 14),
        // Down
        Position(row: 7, col: 14),  // End of main path loop for Yellow
        Position(row: 7, col: 13), Position(row: 7, col: 12), Position(row: 7, col: 11), Position(row: 7, col: 10), Position(row: 7, col: 9), // Yellow Safe Zone
        Position(row: 7, col: 8) // Yellow Home
    ]

    static let bluePath: [Position] = [
        // Up
        Position(row: 13, col: 6), Position(row: 12, col: 6), Position(row: 11, col: 6), Position(row: 10, col: 6), Position(row: 9, col: 6), Position(row: 8, col: 6),
        // Left
        Position(row: 8, col: 5), Position(row: 8, col: 4), Position(row: 8, col: 3), Position(row: 8, col: 2), Position(row: 8, col: 1), Position(row: 8, col: 0),
        // Up
        Position(row: 7, col: 0), Position(row: 6, col: 0),
        // Right
        Position(row: 6, col: 1), Position(row: 6, col: 2), Position(row: 6, col: 3), Position(row: 6, col: 4), Position(row: 6, col: 5), Position(row: 6, col: 6),
        // Up
        Position(row: 5, col: 6), Position(row: 4, col: 6), Position(row: 3, col: 6), Position(row: 2, col: 6), Position(row: 1, col: 6), Position(row: 0, col: 6),
        // right
        Position(row: 0, col: 7), Position(row: 0, col: 8),
        // Down
        Position(row: 1, col: 8), Position(row: 2, col: 8), Position(row: 3, col: 8), Position(row: 4, col: 8), Position(row: 5, col: 8), Position(row: 6, col: 8),
        // Right
        Position(row: 6, col: 9), Position(row: 6, col: 10), Position(row: 6, col: 11), Position(row: 6, col: 12), Position(row: 6, col: 13), Position(row: 6, col: 14),
        // Down
        Position(row: 7, col: 14), Position(row: 8, col: 14),
        // Left
        Position(row: 8, col: 13), Position(row: 8, col: 12), Position(row: 8, col: 11), Position(row: 8, col: 10), Position(row: 8, col: 9), Position(row: 8, col: 8),
        // Down
        Position(row: 9, col: 8),Position(row: 10, col: 8), Position(row: 11, col: 8),Position(row: 12, col: 8), Position(row: 13, col: 8),Position(row: 14, col: 8),
        // Left
        Position(row: 14, col: 7),
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
        // Only allow rolling if there are no eligible pawns
        guard eligiblePawns.isEmpty else { return }
        
        // Roll the dice
        diceValue = Int.random(in: 1...6)
        
        // Mark eligible pawns based on the roll
        if let currentPawns = pawns[currentPlayer] {
            eligiblePawns = Set(currentPawns.filter { pawn in
                if let positionIndex = pawn.positionIndex {
                    // Pawn is on the path
                    return positionIndex >= 0
                } else {
                    // Pawn is at home and dice is 6
                    return diceValue == 6
                }
            }.map { $0.id })
        }
        
        // If no pawns can move, advance to next turn immediately
        if eligiblePawns.isEmpty {
            nextTurn()
        }
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
        eligiblePawns.removeAll()
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
        // Only allow moving eligible pawns
        guard color == currentPlayer && eligiblePawns.contains(pawnId) else { return }
        
        guard let pawnIndex = pawns[color]?.firstIndex(where: { $0.id == pawnId }) else { return }
        
        print("Moving pawn \(pawnId) of color \(color)")
        print("Before move - positionIndex: \(String(describing: pawns[color]?[pawnIndex].positionIndex))")
        
        if let positionIndex = pawns[color]?[pawnIndex].positionIndex {
            // Pawn is on the path
            let currentPath = path(for: color)
            let newIndex = positionIndex + steps
            
            if newIndex < currentPath.count - 1 {
                pawns[color]?[pawnIndex].positionIndex = newIndex
                checkPosition(color: color, pawnIndex: pawnIndex)
            } else if newIndex == currentPath.count - 1 {
                // Pawn reaches home
                pawns[color]?[pawnIndex].positionIndex = -1
            }
        } else {
            // Pawn is at home
            if steps == 6 {
                // Move pawn to start position (index 0)
                pawns[color]?[pawnIndex].positionIndex = 0
            }
        }
        
        print("After move - positionIndex: \(String(describing: pawns[color]?[pawnIndex].positionIndex))")
        
        // After moving the pawn, check if we should advance the turn
        // Only keep the same player's turn if they rolled a 6
        if diceValue != 6 {
            nextTurn()
        }
        
        // Clear eligible pawns
        eligiblePawns.removeAll()
    }

    // Function to check if a pawn can capture another pawn or is in a safe spot
    private func checkPosition(color: PlayerColor, pawnIndex: Int) {
        guard let currentPawn = pawns[color]?[pawnIndex],
              let positionIndex = currentPawn.positionIndex,
              positionIndex >= 0 else { return }
        
        let currentPosition = path(for: color)[positionIndex]
        
        // Check if the position is a safe spot
        let isSafeSpot = isSafePosition(currentPosition)
        if isSafeSpot { return }
        
        // Check for other pawns at the same position
        for (otherColor, otherPawns) in pawns {
            if otherColor == color { continue } // Skip same color
            
            for (otherIndex, otherPawn) in otherPawns.enumerated() {
                guard let otherPositionIndex = otherPawn.positionIndex,
                      otherPositionIndex >= 0 else { continue }
                
                let otherPosition = path(for: otherColor)[otherPositionIndex]
                if otherPosition == currentPosition {
                    // Capture the other pawn
                    pawns[otherColor]?[otherIndex].positionIndex = nil
                }
            }
        }
    }
    
    // Helper to check if a position is a safe spot
    private func isSafePosition(_ position: Position) -> Bool {
        // Check if position is in any safe zone
        if Self.redSafeZone.contains(position) || Self.redHome == position { return true }
        if Self.greenSafeZone.contains(position) || Self.greenHome == position { return true }
        if Self.yellowSafeZone.contains(position) || Self.yellowHome == position { return true }
        if Self.blueSafeZone.contains(position) || Self.blueHome == position { return true }
        
        // Check if position is at the start of any path
        if position == Self.redPath[0] || position == Self.greenPath[0] ||
           position == Self.yellowPath[0] || position == Self.bluePath[0] {
            return true
        }
        
        return false
    }
} 
