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
    @Published var currentRollPlayer: PlayerColor? = nil  // Track whose roll is currently active
    @Published var scores: [PlayerColor: Int] = [.red: 0, .green: 0, .yellow: 0, .blue: 0]  // Track scores
    @Published var homeCompletionOrder: [PlayerColor] = []  // Track order of pawns reaching home
    @Published var isAdminMode: Bool = false  // Whether admin mode is enabled

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
        currentRollPlayer = currentPlayer  // Set the current player as the roll owner
        
        // Mark eligible pawns based on the roll
        if let currentPawns = pawns[currentPlayer] {
            eligiblePawns = Set(currentPawns.filter { pawn in
                if let positionIndex = pawn.positionIndex {
                    // Pawn is on the path
                    // Check if the move would overshoot home
                    let currentPath = path(for: currentPlayer)
                    let newIndex = positionIndex + diceValue
                    return positionIndex >= 0 && newIndex <= currentPath.count - 1
                } else {
                    // Pawn is at home and dice is 6
                    return diceValue == 6
                }
            }.map { $0.id })
            
            // If there's exactly one eligible pawn, simulate tapping it
            if eligiblePawns.count == 1 {
                if let pawnId = eligiblePawns.first,
                   let pawn = currentPawns.first(where: { $0.id == pawnId }) {
                    // Add a small delay to show the dice roll before moving
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
                                
                                // Move the pawn after animation
                                DispatchQueue.main.asyncAfter(deadline: .now() + Double(steps) * 0.25 + 1.0) {
                                    self.movePawn(color: self.currentPlayer, pawnId: pawnId, steps: steps)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // If no pawns can move, advance to next turn after a delay
        if eligiblePawns.isEmpty {
            // Keep the current player's roll visible for 1 seconds before moving to next turn
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.nextTurn(clearRoll: true)
            }
        }
    }
    
    // Function to set a specific dice value for testing
    func testRollDice(value: Int) {
        // Only allow rolling if there are no eligible pawns
        guard eligiblePawns.isEmpty else { return }
        
        // Set the specified dice value
        diceValue = value
        currentRollPlayer = currentPlayer  // Set the current player as the roll owner
        
        // Mark eligible pawns based on the roll
        if let currentPawns = pawns[currentPlayer] {
            eligiblePawns = Set(currentPawns.filter { pawn in
                if let positionIndex = pawn.positionIndex {
                    // Pawn is on the path
                    // Check if the move would overshoot home
                    let currentPath = path(for: currentPlayer)
                    let newIndex = positionIndex + diceValue
                    return positionIndex >= 0 && newIndex <= currentPath.count - 1
                } else {
                    // Pawn is at home and dice is 6
                    return diceValue == 6
                }
            }.map { $0.id })
            
            // If there's exactly one eligible pawn, simulate tapping it
            if eligiblePawns.count == 1 {
                if let pawnId = eligiblePawns.first,
                   let pawn = currentPawns.first(where: { $0.id == pawnId }) {
                    // Add a small delay to show the dice roll before moving
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
                                
                                // Move the pawn after animation
                                DispatchQueue.main.asyncAfter(deadline: .now() + Double(steps) * 0.25 + 1.0) {
                                    self.movePawn(color: self.currentPlayer, pawnId: pawnId, steps: steps)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // If no pawns can move, advance to next turn after a delay
        if eligiblePawns.isEmpty {
            // Keep the current player's roll visible for 1 seconds before moving to next turn
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.nextTurn(clearRoll: true)
            }
        }
    }
    
    func nextTurn(clearRoll: Bool = true) {
        let colors = PlayerColor.allCases
        if let currentIndex = colors.firstIndex(of: currentPlayer) {
            let nextIndex = (currentIndex + 1) % colors.count
            currentPlayer = colors[nextIndex]
            eligiblePawns.removeAll()
            if clearRoll {
                currentRollPlayer = nil
            }
        }
    }
    
    func startGame() {
        gameStarted = true
        currentPlayer = .red
        eligiblePawns.removeAll()
        currentRollPlayer = nil
        // Reset scores and home completion order
        scores = [.red: 0, .green: 0, .yellow: 0, .blue: 0]
        homeCompletionOrder = []
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
        // Only allow moving if:
        // 1. It's your turn
        // 2. It's your roll
        // 3. The pawn is eligible to move
        guard color == currentPlayer && 
              color == currentRollPlayer &&
              eligiblePawns.contains(pawnId) else { return }
        
        guard let pawnIndex = pawns[color]?.firstIndex(where: { $0.id == pawnId }) else { return }
        
        var shouldGetAnotherRoll = false
        
        if let positionIndex = pawns[color]?[pawnIndex].positionIndex {
            // Pawn is on the path
            let currentPath = path(for: color)
            let newIndex = positionIndex + steps
            
            if newIndex < currentPath.count - 1 {
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
                                  otherPositionIndex >= 0 else { continue }
                            
                            let otherPosition = path(for: otherColor)[otherPositionIndex]
                            
                            if otherPosition == newPosition {
                                // Capture the pawn
                                pawns[otherColor]?[otherIndex].positionIndex = nil
                                shouldGetAnotherRoll = true
                                // Add 3 points for capture
                                scores[color] = (scores[color] ?? 0) + 3
                            }
                        }
                    }
                }
                
                // Now move the pawn
                pawns[color]?[pawnIndex].positionIndex = newIndex
            } else if newIndex == currentPath.count - 1 {
                // Pawn reaches home
                pawns[color]?[pawnIndex].positionIndex = -1
                shouldGetAnotherRoll = true // Get another roll for reaching home
                
                // Add points for reaching home
                if !homeCompletionOrder.contains(color) {
                    homeCompletionOrder.append(color)
                    let points = 16 - (homeCompletionOrder.count - 1)  // First gets 16, then 15, etc.
                    scores[color] = (scores[color] ?? 0) + points
                }
            }
        } else {
            // Pawn is at home
            if steps == 6 {
                // Move pawn to start position (index 0)
                pawns[color]?[pawnIndex].positionIndex = 0
            }
        }
        
        // After moving the pawn, check if we should advance the turn
        // Keep the same player's turn if they rolled a 6, captured a pawn, or reached home
        if shouldGetAnotherRoll || diceValue == 6 {
            // Player gets another roll - clear the roll but keep the same player
            currentRollPlayer = nil
            eligiblePawns.removeAll()
        } else {
            // No extra roll - advance to next player
            nextTurn(clearRoll: true)
        }
    }
    
    // Helper to check if a position is a safe spot
    private func isSafePosition(_ position: Position) -> Bool {
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
    
    // Function to get the destination index for a move
    func getDestinationIndex(color: PlayerColor, pawnId: Int) -> Int? {
        guard let pawn = pawns[color]?.first(where: { $0.id == pawnId }),
              let positionIndex = pawn.positionIndex else { return nil }
        
        let currentPath = path(for: color)
        let newIndex = positionIndex + diceValue
        return newIndex >= currentPath.count - 1 ? -1 : newIndex
    }
} 
