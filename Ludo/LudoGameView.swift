import SwiftUI

struct LudoGameView: View {
    @StateObject private var game = LudoGame()
    
    var body: some View {
        VStack {
            if !game.gameStarted {
                startGameView
            } else {
                gameBoardView
            }
        }
        .padding()
        .environmentObject(game)
    }
    
    private var startGameView: some View {
        VStack {
            Text("Ludo")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Button("Start Game") {
                game.startGame()
            }
            .font(.title2)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
    
    private var gameBoardView: some View {
        VStack {
            Text("Current Player: \(game.currentPlayer.rawValue.capitalized)")
                .font(.title2)
            
            Text("Dice: \(game.diceValue)")
                .font(.title)
                .padding()
            
            HStack {
                Button("Roll Dice") {
                    game.rollDice()
                }
                .font(.title2)
                .padding()
                .background(game.eligiblePawns.isEmpty ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(!game.eligiblePawns.isEmpty)
                
                // Test dice roll buttons
                HStack {
                    ForEach([1, 2, 3, 4, 5, 6, 48], id: \.self) { value in
                        Button("\(value)") {
                            game.testRollDice(value: value)
                        }
                        .font(.title3)
                        .padding(8)
                        .background(game.eligiblePawns.isEmpty ? (value == 48 ? Color.purple : Color.green) : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(!game.eligiblePawns.isEmpty)
                    }
                }
            }
            
            // Ludo Board
            LudoBoardView()
        }
    }
}

struct LudoBoardView: View {
    let gridSize = 15
    @EnvironmentObject var game: LudoGame
    private static var pawnViewCount = 0
    @State private var animatingPawns: [String: (start: Int, end: Int, progress: Double)] = [:]
    @State private var currentStep = 0
    @State private var isPathAnimating = false
    @State private var capturedPawns: [(color: PlayerColor, id: Int, progress: Double)] = []
    @State private var homeToStartPawns: [(color: PlayerColor, id: Int, progress: Double)] = []
    
    private func calculateBoardDimensions(geometry: GeometryProxy) -> (boardSize: CGFloat, cellSize: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
        let boardSize = min(geometry.size.width, geometry.size.height) * 0.95
        let cellSize = boardSize / CGFloat(gridSize)
        let boardOffsetX = (geometry.size.width - boardSize) / 2
        let boardOffsetY = (geometry.size.height - boardSize) / 2
        
        return (boardSize, cellSize, boardOffsetX, boardOffsetY)
    }
    
    private func isStarSpace(row: Int, col: Int) -> Bool {
        // Starting positions for each color
        let startPositions = [
            (6, 1),  // Red start
            (1, 8),  // Green start
            (8, 13), // Yellow start
            (13, 6)  // Blue start
        ]
        
        // Additional star spaces
        let additionalStarSpaces = [
            (8, 2),
            (12, 8),
            (6, 12),
            (2, 6)
        ]
        
        return startPositions.contains(where: { $0.0 == row && $0.1 == col }) ||
               additionalStarSpaces.contains(where: { $0.0 == row && $0.1 == col })
    }
    
    private func animatePawnMovementForPath(pawn: Pawn, color: PlayerColor, from: Int, to: Int, steps: Int) {
        print("DEBUG: animatePawnMovementForPath called for pawn \(pawn.id) of color \(color)")
        print("DEBUG: from: \(from), to: \(to), steps: \(steps)")
        
        isPathAnimating = true
        currentStep = 0
        
        // Remove from homeToStartPawns if it's there (moving from starting home to path)
        homeToStartPawns.removeAll(where: { $0.color == color && $0.id == pawn.id })
        
        func animateNextStep() {
            guard currentStep < steps else {
                print("DEBUG: Animation complete - currentStep (\(currentStep)) >= steps (\(steps))")
                isPathAnimating = false
                return
            }
            
            let key = "\(color.rawValue)-\(pawn.id)"
            let currentFrom = from + currentStep
            let currentTo = currentFrom + 1
            
            // print("DEBUG: Animation step - currentFrom: \(currentFrom), currentTo: \(currentTo), path count: \(game.path(for: color).count)")
            
            // Safety check: if we're at the end of the path, don't try to animate further
            if currentTo >= game.path(for: color).count {
                print("DEBUG: Reached end of path without ending home animation")
                isPathAnimating = false
                return
            }
            
            // print("DEBUG: Animating step \(currentStep) from \(currentFrom) to \(currentTo)")
            animatingPawns[key] = (currentFrom, currentTo, 0)
            
            withAnimation(.spring(response: 0.25, dampingFraction: 0.4, blendDuration: 0)) {
                animatingPawns[key]?.progress = 1.0
            }
            
            currentStep += 1
            
            // Schedule next step
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                animateNextStep()
            }
        }
        
        // Start the animation
        animateNextStep()
        
        // After all steps are complete, check for captures
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(steps) * 0.25) {
            // Safety check: if the pawn has reached ending home (to < 0), don't check for captures
            guard to >= 0 else { return }
            
            // Get the final position
            let finalPosition = game.path(for: color)[to]
            
            // Check for captures at the final position
            for (otherColor, otherPawns) in game.pawns {
                if otherColor == color { continue } // Skip same color
                
                for (otherIndex, otherPawn) in otherPawns.enumerated() {
                    guard let otherPositionIndex = otherPawn.positionIndex,
                          otherPositionIndex >= 0 else { continue }
                    
                    let otherPosition = game.path(for: otherColor)[otherPositionIndex]
                    if otherPosition == finalPosition && !isStarSpace(row: finalPosition.row, col: finalPosition.col) {
                        // Add the pawn to captured pawns for animation
                        capturedPawns.append((color: otherColor, id: otherPawn.id, progress: 0))
                        
                        // Animate the capture
                        withAnimation(.easeInOut(duration: 0.5)) {
                            if let index = capturedPawns.firstIndex(where: { $0.color == otherColor && $0.id == otherPawn.id }) {
                                capturedPawns[index].progress = 1.0
                            }
                        }
                        
                        // After animation completes, update the game state
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            capturedPawns.removeAll(where: { $0.color == otherColor && $0.id == otherPawn.id })
                        }
                    }
                }
            }
        }
    }
    
    private func getStartingHomePosition(pawn: Pawn, color: PlayerColor) -> (row: Int, col: Int) {
        switch color {
        case .red:
            return (row: pawn.id < 2 ? 1 : 4, col: pawn.id % 2 == 0 ? 1 : 4)
        case .green:
            return (row: pawn.id < 2 ? 1 : 4, col: pawn.id % 2 == 0 ? 10 : 13)
        case .yellow:
            return (row: pawn.id < 2 ? 10 : 13, col: pawn.id % 2 == 0 ? 10 : 13)
        case .blue:
            return (row: pawn.id < 2 ? 10 : 13, col: pawn.id % 2 == 0 ? 1 : 4)
        }
    }
    
    private func getCurrentPosition(pawn: Pawn, color: PlayerColor, positionIndex: Int) -> (row: Int, col: Int) {
        let key = "\(color.rawValue)-\(pawn.id)"
        if let animation = animatingPawns[key] {
            let progress = animation.progress
            let startPos: Position
            if animation.start == -1 {
                // If start is -1, we're moving from home
                let homePos = getStartingHomePosition(pawn: pawn, color: color)
                startPos = Position(row: homePos.row, col: homePos.col)
            } else {
                startPos = game.path(for: color)[animation.start]
            }
            let endPos = game.path(for: color)[animation.end]
            
            // Calculate current position with a hop
            let currentRow = Int(Double(startPos.row) + Double(endPos.row - startPos.row) * progress)
            let currentCol = Int(Double(startPos.col) + Double(endPos.col - startPos.col) * progress)
            
            return (row: currentRow, col: currentCol)
        }
        let position = game.path(for: color)[positionIndex]
        return (row: position.row, col: position.col)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let (boardSize, cellSize, boardOffsetX, boardOffsetY) = calculateBoardDimensions(geometry: geometry)
            
            ZStack {
                VStack(spacing: 0) {
                    ForEach(0..<gridSize, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<gridSize, id: \.self) { col in
                                cellView(row: row, col: col, cellSize: cellSize)
                            }
                        }
                    }
                }
                .frame(width: boardSize, height: boardSize)
                .border(Color.black, width: 2)
                
                // Home to start animations
                ForEach(homeToStartPawns, id: \.id) { animating in
                    if let pawn = game.pawns[animating.color]?.first(where: { $0.id == animating.id }) {
                        let homePos = getStartingHomePosition(pawn: pawn, color: animating.color)
                        let startPos = getPathStartPosition(for: animating.color)
                        
                        // Calculate the exact center positions relative to the board
                        let startX = boardOffsetX + CGFloat(homePos.col) * cellSize
                        let startY = boardOffsetY + CGFloat(homePos.row) * cellSize
                        let endX = boardOffsetX + CGFloat(startPos.col) * cellSize
                        let endY = boardOffsetY + CGFloat(startPos.row) * cellSize
                        
                        // Calculate the offset based on animation progress
                        let xOffset = animating.progress * (endX - startX)
                        let yOffset = animating.progress * (endY - startY)
                        
                        // Position the pawn at the start position and animate to end position
                        PawnView(color: animating.color, size: cellSize * 0.8)
                            .position(
                                x: startX + xOffset + cellSize/2,
                                y: startY + yOffset + cellSize/2
                            )
                    }
                }
                
                // Captured pawns layer
                ForEach(capturedPawns, id: \.id) { captured in
                    if let pawn = game.pawns[captured.color]?.first(where: { $0.id == captured.id }) {
                        // Get the actual position where the pawn was captured
                        let capturedPosition = game.path(for: captured.color)[pawn.positionIndex ?? 0]
                        let homePos = getStartingHomePosition(pawn: pawn, color: captured.color)
                        
                        // Calculate the exact center positions relative to the board
                        let startX = boardOffsetX + CGFloat(capturedPosition.col) * cellSize
                        let startY = boardOffsetY + CGFloat(capturedPosition.row) * cellSize
                        let endX = boardOffsetX + CGFloat(homePos.col) * cellSize
                        let endY = boardOffsetY + CGFloat(homePos.row) * cellSize
                        
                        // Calculate the offset based on capture progress
                        let xOffset = captured.progress * (endX - startX)
                        let yOffset = captured.progress * (endY - startY)
                        
                        // Position the pawn at the start position and animate to end position
                        PawnView(color: captured.color, size: cellSize * 0.8)
                            .position(
                                x: startX + xOffset + cellSize/2,
                                y: startY + yOffset + cellSize/2
                            )
                    }
                }
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .onAppear {
                Self.pawnViewCount = 0
                print("\nDEBUG: Reset pawn view counter to 0")
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    @ViewBuilder
    func cellView(row: Int, col: Int, cellSize: CGFloat) -> some View {
        ZStack {
            cellBackground(row: row, col: col, cellSize: cellSize)
            cellPawns(row: row, col: col, cellSize: cellSize)
        }
        .frame(width: cellSize, height: cellSize)
    }
    
    @ViewBuilder
    private func cellBackground(row: Int, col: Int, cellSize: CGFloat) -> some View {
        ZStack {
            // Red Home Area
            if row < 6 && col < 6 {
                Rectangle().fill(Color.red.opacity(0.7))
                if (row == 1 || row == 4) && (col == 1 || col == 4) {
                    Circle().fill(Color.red).padding(cellSize * 0.1)
                }
            // Green Home Area
            } else if row < 6 && col > 8 {
                Rectangle().fill(Color.green.opacity(0.7))
                if (row == 1 || row == 4) && (col == 10 || col == 13) {
                    Circle().fill(Color.green).padding(cellSize * 0.1)
                }
            // Blue Home Area
            } else if row > 8 && col < 6 {
                Rectangle().fill(Color.blue.opacity(0.7))
                if (row == 10 || row == 13) && (col == 1 || col == 4) {
                    Circle().fill(Color.blue).padding(cellSize * 0.1)
                }
            // Yellow Home Area
            } else if row > 8 && col > 8 {
                Rectangle().fill(Color.yellow.opacity(0.7))
                if (row == 10 || row == 13) && (col == 10 || col == 13) {
                    Circle().fill(Color.yellow).padding(cellSize * 0.1)
                }
            // Red Safe Zone
            } else if row == 7 && (1...5).contains(col) {
                Rectangle().fill(Color.red.opacity(0.7))
            // Red Home (Dark Red)
            } else if row == 7 && col == 6 {
                Rectangle().fill(Color(red: 0.5, green: 0, blue: 0))
            // Green Safe Zone
            } else if col == 7 && (1...5).contains(row) {
                Rectangle().fill(Color.green.opacity(0.7))
            // Green Home (Dark Green)
            } else if row == 6 && col == 7 {
                Rectangle().fill(Color(red: 0, green: 0.4, blue: 0))
            // Yellow Safe Zone
            } else if row == 7 && (9...13).contains(col) {
                Rectangle().fill(Color.yellow.opacity(0.7))
            // Yellow Home (Dark Yellow)
            } else if row == 7 && col == 8 {
                Rectangle().fill(Color(red: 0.6, green: 0.6, blue: 0))
            // Blue Safe Zone
            } else if col == 7 && (9...13).contains(row) {
                Rectangle().fill(Color.blue.opacity(0.7))
            // Blue Home (Dark Blue)
            } else if row == 8 && col == 7 {
                Rectangle().fill(Color(red: 0, green: 0, blue: 0.5))
            } else {
                Rectangle().fill(Color.white)
            }
            
            // Draw star if this is a star space
            if isStarSpace(row: row, col: col) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: cellSize * 0.4))
            }
            
            Rectangle().stroke(Color.black, lineWidth: 0.5)
        }
    }
    
    @ViewBuilder
    private func cellPawns(row: Int, col: Int, cellSize: CGFloat) -> some View {
        ForEach(PlayerColor.allCases, id: \.self) { color in
            pawnsForColor(color: color, row: row, col: col, cellSize: cellSize)
        }
    }
    
    @ViewBuilder
    private func pawnsForColor(color: PlayerColor, row: Int, col: Int, cellSize: CGFloat) -> some View {
        ForEach(game.pawns[color] ?? [], id: \.id) { pawn in
            pawnView(pawn: pawn, color: color, row: row, col: col, cellSize: cellSize)
        }
    }

    private func debugPrintHomePawnTap(pawn: Pawn, color: PlayerColor) {
        guard color == .red && pawn.id == 1 else { return }
        print("\nDEBUG: Red pawn 1 tapped in home")
        print("Current state - positionIndex: \(String(describing: pawn.positionIndex))")
        print("Game state - Current player: \(game.currentPlayer), Dice value: \(game.diceValue)")
    }

    private func debugPrintHomePawnMove(pawn: Pawn, color: PlayerColor) {
        guard color == .red && pawn.id == 1 else { return }
        print("\nDEBUG: Red pawn 1 moving from home")
        print("Before move - positionIndex: \(String(describing: pawn.positionIndex))")
    }

    private func debugPrintHomePawnAfterMove(pawn: Pawn, color: PlayerColor) {
        guard color == .red && pawn.id == 1 else { return }
        print("After move - positionIndex: \(String(describing: game.pawns[color]?.first(where: { $0.id == pawn.id })?.positionIndex))")
    }

    @ViewBuilder
    private func pawnView(pawn: Pawn, color: PlayerColor, row: Int, col: Int, cellSize: CGFloat) -> some View {
        Group {
            if let positionIndex = pawn.positionIndex {
                if positionIndex >= 0 {
                    // Pawn is on the path
                    pathPawnView(pawn: pawn, color: color, positionIndex: positionIndex, row: row, col: col, cellSize: cellSize)
                } else {
                    // Pawn is in ending home (positionIndex == -1)
                    endingHomePawnView(pawn: pawn, color: color, row: row, col: col, cellSize: cellSize)
                }
            } else {
                // Pawn is in starting home
                homePawnView(pawn: pawn, color: color, row: row, col: col, cellSize: cellSize)
            }
        }
    }
    
    private func isValidMove(color: PlayerColor, pawnId: Int) -> Bool {
        // Check if it's the current player's turn
        guard color == game.currentPlayer else { return false }
        
        // Check if it's the current player's roll
        guard color == game.currentRollPlayer else { return false }
        
        // Check if the pawn is eligible to move
        guard game.eligiblePawns.contains(pawnId) else { return false }
        
        // Additional check for overshooting home
        if let pawn = game.pawns[color]?.first(where: { $0.id == pawnId }),
           let positionIndex = pawn.positionIndex,
           positionIndex >= 0 {
            let currentPath = game.path(for: color)
            let newIndex = positionIndex + game.diceValue
            return newIndex <= currentPath.count - 1
        }
        
        return true
    }

    private func countPawnsInCell(row: Int, col: Int) -> Int {
        var count = 0
        for (_, pawns) in game.pawns {
            for pawn in pawns {
                if let positionIndex = pawn.positionIndex, positionIndex >= 0 {
                    let currentPos = getCurrentPosition(pawn: pawn, color: pawn.color, positionIndex: positionIndex)
                    if currentPos.row == row && currentPos.col == col {
                        count += 1
                    }
                }
            }
        }
        return count
    }

    private func calculatePawnSizeAndOffset(cellSize: CGFloat, totalPawns: Int, index: Int) -> (size: CGFloat, xOffset: CGFloat, yOffset: CGFloat) {
        // Special case for single pawn
        if totalPawns == 1 {
            let size = cellSize * 0.8 // Keep original size for single pawn
            return (size, 0, 0) // Center in cell with no offset
        }
        
        // Base size for calculations
        let baseSize = cellSize * 0.8
        
        // Define layouts for different numbers of pawns
        switch totalPawns {
        case 2:
            // Two pawns side by side
            let size = baseSize * 0.5
            let xOffset = index == 0 ? -size/2 : size/2
            return (size, xOffset, 0)
            
        case 3:
            // Triangle formation
            let size = baseSize * 0.4
            let positions: [(x: CGFloat, y: CGFloat)] = [
                (0, -size/2),      // Top
                (-size/2, size/2), // Bottom left
                (size/2, size/2)   // Bottom right
            ]
            return (size, positions[index].x, positions[index].y)
            
        case 4:
            // 2x2 grid
            let size = baseSize * 0.4
            let row = index / 2
            let col = index % 2
            let xOffset = (CGFloat(col) * size) - (size/2)
            let yOffset = (CGFloat(row) * size) - (size/2)
            return (size, xOffset, yOffset)
            
        case 5...8:
            // 3x3 grid with some empty spots
            let size = baseSize * 0.3
            let cols = 3
            let row = index / cols
            let col = index % cols
            let xOffset = (CGFloat(col) * size) - size
            let yOffset = (CGFloat(row) * size) - size
            return (size, xOffset, yOffset)
            
        case 9...12:
            // 4x3 grid
            let size = baseSize * 0.25
            let cols = 4
            let row = index / cols
            let col = index % cols
            let xOffset = (CGFloat(col) * size) - (size * 1.5)
            let yOffset = (CGFloat(row) * size) - size
            return (size, xOffset, yOffset)
            
        case 13...16:
            // 4x4 grid
            let size = baseSize * 0.2
            let cols = 4
            let row = index / cols
            let col = index % cols
            let xOffset = (CGFloat(col) * size) - (size * 1.5)
            let yOffset = (CGFloat(row) * size) - (size * 1.5)
            return (size, xOffset, yOffset)
            
        default:
            // Fallback for any other number (shouldn't happen)
            let size = baseSize * 0.2
            return (size, 0, 0)
        }
    }

    private func getPawnIndexInCell(pawn: Pawn, color: PlayerColor, row: Int, col: Int) -> Int {
        var index = 0
        for (_, pawns) in game.pawns {
            for p in pawns {
                if let posIndex = p.positionIndex, posIndex >= 0 {
                    let pos = getCurrentPosition(pawn: p, color: p.color, positionIndex: posIndex)
                    if pos.row == row && pos.col == col {
                        if p.id == pawn.id && p.color == color {
                            return index
                        }
                        index += 1
                    }
                }
            }
        }
        return index
    }

    @ViewBuilder
    private func pathPawnView(pawn: Pawn, color: PlayerColor, positionIndex: Int, row: Int, col: Int, cellSize: CGFloat) -> some View {
        if positionIndex >= 0 {
            let currentPos = getCurrentPosition(pawn: pawn, color: color, positionIndex: positionIndex)
            if currentPos.row == row && currentPos.col == col {
                let key = "\(color.rawValue)-\(pawn.id)"
                let hopOffset = animatingPawns[key] != nil ? sin(animatingPawns[key]!.progress * .pi) * 40 : 0
                let isAnimating = animatingPawns[key] != nil
                
                // Count total pawns in this cell
                let totalPawns = countPawnsInCell(row: row, col: col)
                
                // Calculate this pawn's index in the cell
                let pawnIndex = getPawnIndexInCell(pawn: pawn, color: color, row: row, col: col)
                
                // Calculate size and position
                let (size, xOffset, yOffset) = calculatePawnSizeAndOffset(cellSize: cellSize, totalPawns: totalPawns, index: pawnIndex)
                
                PawnView(color: color, size: size)
                    .offset(x: xOffset, y: yOffset - hopOffset)
                    .shadow(color: .black.opacity(isAnimating ? 0.3 : 0.1), radius: isAnimating ? 4 : 2)
                    .onTapGesture {
                        if !isPathAnimating {
                            let currentPos = pawn.positionIndex ?? -1
                            let steps = game.diceValue
                            
                            if isValidMove(color: color, pawnId: pawn.id) {
                                let currentPath = game.path(for: color)
                                let newIndex = currentPos + steps
                                let destinationIndex = newIndex >= currentPath.count - 1 ? -1 : newIndex
                                
                                animatePawnMovementForPath(pawn: pawn, color: color, from: currentPos, to: destinationIndex, steps: steps)
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + Double(steps) * 0.25 + 1.0) {
                                    game.movePawn(color: color, pawnId: pawn.id, steps: steps)
                                }
                            }
                        }
                    }
            }
        }
    }
    
    @ViewBuilder
    private func endingHomePawnView(pawn: Pawn, color: PlayerColor, row: Int, col: Int, cellSize: CGFloat) -> some View {
        if isCorrectEndingHomePosition(pawn: pawn, color: color, row: row, col: col) {
            PawnView(color: color, size: cellSize * 0.8)
                .shadow(color: .black.opacity(0.2), radius: 2)
        }
    }
    
    private func isCorrectEndingHomePosition(pawn: Pawn, color: PlayerColor, row: Int, col: Int) -> Bool {
        // Each color has its own ending home position in the center
        switch color {
        case .red:
            return row == 7 && col == 6
        case .green:
            return row == 6 && col == 7
        case .yellow:
            return row == 7 && col == 8
        case .blue:
            return row == 8 && col == 7
        }
    }
    
    @ViewBuilder
    private func homePawnView(pawn: Pawn, color: PlayerColor, row: Int, col: Int, cellSize: CGFloat) -> some View {
        if isCorrectStartingHomePosition(pawn: pawn, color: color, row: row, col: col) {
            PawnView(color: color, size: cellSize * 0.8)
                .onTapGesture {
                    let _ = debugPrintHomePawnTap(pawn: pawn, color: color)
                    
                    if color == game.currentPlayer && !isPathAnimating && game.diceValue == 6 {
                        // Add to home-to-start animations (moving from starting home to path)
                        homeToStartPawns.append((color: color, id: pawn.id, progress: 0))
                        
                        // Add to animatingPawns for position calculation
                        let key = "\(color.rawValue)-\(pawn.id)"
                        animatingPawns[key] = (-1, 0, 0) // -1 represents starting home position
                        
                        // Animate to final position
                        withAnimation(.easeInOut(duration: 0.5)) {
                            if let index = homeToStartPawns.firstIndex(where: { $0.color == color && $0.id == pawn.id }) {
                                homeToStartPawns[index].progress = 1.0
                            }
                            animatingPawns[key]?.progress = 1.0
                        }
                        
                        // Delay the actual move until after animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            let _ = debugPrintHomePawnMove(pawn: pawn, color: color)
                            
                            game.movePawn(color: color, pawnId: pawn.id, steps: game.diceValue)
                            
                            let _ = debugPrintHomePawnAfterMove(pawn: pawn, color: color)
                            
                            // Remove from animations
                            homeToStartPawns.removeAll(where: { $0.color == color && $0.id == pawn.id })
                            animatingPawns.removeValue(forKey: key)
                        }
                    }
                }
        }
    }
    
    // Helper function to get the start position on the path for each color
    private func getPathStartPosition(for color: PlayerColor) -> (row: Int, col: Int) {
        switch color {
        case .red:
            return (row: 6, col: 1)
        case .green:
            return (row: 1, col: 8)
        case .yellow:
            return (row: 8, col: 13)
        case .blue:
            return (row: 13, col: 6)
        }
    }
    
    private func isCorrectStartingHomePosition(pawn: Pawn, color: PlayerColor, row: Int, col: Int) -> Bool {
        switch color {
        case .red:
            return (pawn.id == 0 && row == 1 && col == 1) ||
                   (pawn.id == 1 && row == 1 && col == 4) ||
                   (pawn.id == 2 && row == 4 && col == 1) ||
                   (pawn.id == 3 && row == 4 && col == 4)
        case .green:
            return (pawn.id == 0 && row == 1 && col == 10) ||
                   (pawn.id == 1 && row == 1 && col == 13) ||
                   (pawn.id == 2 && row == 4 && col == 10) ||
                   (pawn.id == 3 && row == 4 && col == 13)
        case .yellow:
            return (pawn.id == 0 && row == 10 && col == 10) ||
                   (pawn.id == 1 && row == 10 && col == 13) ||
                   (pawn.id == 2 && row == 13 && col == 10) ||
                   (pawn.id == 3 && row == 13 && col == 13)
        case .blue:
            return (pawn.id == 0 && row == 10 && col == 1) ||
                   (pawn.id == 1 && row == 10 && col == 4) ||
                   (pawn.id == 2 && row == 13 && col == 1) ||
                   (pawn.id == 3 && row == 13 && col == 4)
        }
    }
    
    private func debugPrintTapAndAnimation(pawn: Pawn, color: PlayerColor, isAnimating: Bool) {
        print("\nDEBUG: TAP DETECTED on pawn \(pawn.id) of color \(color)")
        print("DEBUG: Current state:")
        print("DEBUG: - Current player: \(game.currentPlayer)")
        print("DEBUG: - Dice value: \(game.diceValue)")
        print("DEBUG: - Is animating: \(isAnimating)")
        
        if color == game.currentPlayer && !isAnimating && game.diceValue == 6 {
            print("DEBUG: Starting animation sequence")
        } else {
            print("DEBUG: Conditions not met for animation:")
            print("DEBUG: - color == currentPlayer: \(color == game.currentPlayer)")
            print("DEBUG: - !isAnimating: \(!isAnimating)")
            print("DEBUG: - diceValue == 6: \(game.diceValue == 6)")
        }
    }
}

struct PawnView: View {
    let color: PlayerColor
    let size: CGFloat
    
    var body: some View {
        Circle()
            .fill(colorForPlayer(color))
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
    }
    
    private func colorForPlayer(_ color: PlayerColor) -> Color {
        switch color {
        case .red: return .red
        case .green: return .green
        case .yellow: return .yellow
        case .blue: return .blue
        }
    }
}

#Preview {
    LudoGameView()
} 
