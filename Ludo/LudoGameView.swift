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
                    ForEach([1, 2, 3, 4, 5, 6], id: \.self) { value in
                        Button("\(value)") {
                            game.testRollDice(value: value)
                        }
                        .font(.title3)
                        .padding(8)
                        .background(game.eligiblePawns.isEmpty ? Color.green : Color.gray)
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
    
    private func printPawnPositions(color: PlayerColor) {
        print("\nDEBUG: All pawn positions for color \(color):")
        for pawn in game.pawns[color] ?? [] {
            if let positionIndex = pawn.positionIndex {
                if positionIndex >= 0 {
                    let position = game.path(for: color)[positionIndex]
                    print("Pawn \(pawn.id): on path at position \(positionIndex) (row: \(position.row), col: \(position.col))")
                } else {
                    print("Pawn \(pawn.id): finished")
                }
            } else {
                print("Pawn \(pawn.id): at home")
            }
        }
        print("")
    }
    
    private func debugPrintCapturedPawnPositions(capturedPosition: Position, homePos: (row: Int, col: Int), startX: CGFloat, startY: CGFloat, endX: CGFloat, endY: CGFloat, xOffset: CGFloat, yOffset: CGFloat) {
        print("\nDEBUG: Captured pawn positions:")
        print("Captured position: row \(capturedPosition.row), col \(capturedPosition.col)")
        print("Home position: row \(homePos.row), col \(homePos.col)")
        print("Start coordinates: x \(startX), y \(startY)")
        print("End coordinates: x \(endX), y \(endY)")
        print("Current offset: x \(xOffset), y \(yOffset)")
        print("Final position: x \(startX + xOffset), y \(startY + yOffset)")
    }
}

struct LudoBoardView: View {
    let gridSize = 15
    @EnvironmentObject var game: LudoGame
    private static var pawnViewCount = 0
    @State private var animatingPawns: [String: (start: Int, end: Int, progress: Double)] = [:]
    @State private var currentStep = 0
    @State private var isAnimating = false
    @State private var slidingPawn: (color: PlayerColor, id: Int, progress: Double)? = nil
    @State private var capturedPawns: [(color: PlayerColor, id: Int, progress: Double)] = []
    
    private func calculateBoardDimensions(geometry: GeometryProxy) -> (boardSize: CGFloat, cellSize: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
        let boardSize = min(geometry.size.width, geometry.size.height) * 0.95
        let cellSize = boardSize / CGFloat(gridSize)
        let boardOffsetX = (geometry.size.width - boardSize) / 2
        let boardOffsetY = (geometry.size.height - boardSize) / 2
        
        print("\nDEBUG: Board dimensions:")
        print("Board size: \(boardSize)")
        print("Cell size: \(cellSize)")
        print("Board offset X: \(boardOffsetX)")
        print("Board offset Y: \(boardOffsetY)")
        
        return (boardSize, cellSize, boardOffsetX, boardOffsetY)
    }
    
    private func debugPrintCapturedPawnPositions(capturedPosition: Position, homePos: (row: Int, col: Int), startX: CGFloat, startY: CGFloat, endX: CGFloat, endY: CGFloat, xOffset: CGFloat, yOffset: CGFloat) {
        print("\nDEBUG: Captured pawn positions:")
        print("Captured position: row \(capturedPosition.row), col \(capturedPosition.col)")
        print("Home position: row \(homePos.row), col \(homePos.col)")
        print("Start coordinates: x \(startX), y \(startY)")
        print("End coordinates: x \(endX), y \(endY)")
        print("Current offset: x \(xOffset), y \(yOffset)")
        print("Final position: x \(startX + xOffset), y \(startY + yOffset)")
    }
    
    private func printPawnPositions(color: PlayerColor) {
        print("\nDEBUG: All pawn positions for color \(color):")
        for pawn in game.pawns[color] ?? [] {
            if let positionIndex = pawn.positionIndex {
                if positionIndex >= 0 {
                    let position = game.path(for: color)[positionIndex]
                    print("Pawn \(pawn.id): on path at position \(positionIndex) (row: \(position.row), col: \(position.col))")
                } else {
                    print("Pawn \(pawn.id): finished")
                }
            } else {
                print("Pawn \(pawn.id): at home")
            }
        }
        print("")
    }
    
    private func animatePawnMovement(pawn: Pawn, color: PlayerColor, from: Int, to: Int, steps: Int) {
        print("DEBUG: animatePawnMovement called for pawn \(pawn.id) of color \(color)")
        print("DEBUG: from: \(from), to: \(to), steps: \(steps)")
        
        isAnimating = true
        currentStep = 0
        
        func animateNextStep() {
            guard currentStep < steps else {
                isAnimating = false
                return
            }
            
            let key = "\(color.rawValue)-\(pawn.id)"
            let currentFrom = from + currentStep
            let currentTo = currentFrom + 1
            
            animatingPawns[key] = (currentFrom, currentTo, 0)
            
            withAnimation(.easeInOut(duration: 0.15)) {
                animatingPawns[key]?.progress = 1.0
            }
            
            currentStep += 1
            
            // Schedule next step
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                animateNextStep()
            }
        }
        
        // Start the animation
        animateNextStep()
        
        // After all steps are complete, check for captures
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(steps) * 0.15) {
            // Get the final position
            let finalPosition = game.path(for: color)[to]
            
            // Check for captures at the final position
            for (otherColor, otherPawns) in game.pawns {
                if otherColor == color { continue } // Skip same color
                
                for (otherIndex, otherPawn) in otherPawns.enumerated() {
                    guard let otherPositionIndex = otherPawn.positionIndex,
                          otherPositionIndex >= 0 else { continue }
                    
                    let otherPosition = game.path(for: otherColor)[otherPositionIndex]
                    if otherPosition == finalPosition {
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
                            game.pawns[otherColor]?[otherIndex].positionIndex = nil
                            // Remove from captured pawns
                            capturedPawns.removeAll(where: { $0.color == otherColor && $0.id == otherPawn.id })
                        }
                    }
                }
            }
        }
    }
    
    private func getHomePosition(pawn: Pawn, color: PlayerColor) -> (row: Int, col: Int) {
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
            let startPos = game.path(for: color)[animation.start]
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
                
                // Captured pawns layer
                ForEach(capturedPawns, id: \.id) { captured in
                    if let pawn = game.pawns[captured.color]?.first(where: { $0.id == captured.id }) {
                        // Get the actual position where the pawn was captured
                        let capturedPosition = game.path(for: captured.color)[pawn.positionIndex ?? 0]
                        let homePos = getHomePosition(pawn: pawn, color: captured.color)
                        
                        // Calculate the exact center positions relative to the board
                        let startX = boardOffsetX + CGFloat(capturedPosition.col) * cellSize
                        let startY = boardOffsetY + CGFloat(capturedPosition.row) * cellSize
                        let endX = boardOffsetX + CGFloat(homePos.col) * cellSize
                        let endY = boardOffsetY + CGFloat(homePos.row) * cellSize
                        
                        // Calculate the offset based on capture progress
                        let xOffset = captured.progress * (endX - startX)
                        let yOffset = captured.progress * (endY - startY)
                        
                        // Debug print positions
                        let _ = debugPrintCapturedPawnPositions(
                            capturedPosition: capturedPosition,
                            homePos: homePos,
                            startX: startX,
                            startY: startY,
                            endX: endX,
                            endY: endY,
                            xOffset: xOffset,
                            yOffset: yOffset
                        )
                        
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
        
        // Print all pawn positions for this color
        if row == 0 && col == 0 {
            let _ = printPawnPositions(color: color)
        }
    }
    
    @ViewBuilder
    private func pawnView(pawn: Pawn, color: PlayerColor, row: Int, col: Int, cellSize: CGFloat) -> some View {
        Group {
            if let positionIndex = pawn.positionIndex {
                pathPawnView(pawn: pawn, color: color, positionIndex: positionIndex, row: row, col: col, cellSize: cellSize)
            } else {
                homePawnView(pawn: pawn, color: color, row: row, col: col, cellSize: cellSize)
            }
        }
    }
    
    @ViewBuilder
    private func pathPawnView(pawn: Pawn, color: PlayerColor, positionIndex: Int, row: Int, col: Int, cellSize: CGFloat) -> some View {
        if positionIndex >= 0 {
            let currentPos = getCurrentPosition(pawn: pawn, color: color, positionIndex: positionIndex)
            if currentPos.row == row && currentPos.col == col {
                let key = "\(color.rawValue)-\(pawn.id)"
                let hopOffset = animatingPawns[key] != nil ? sin(animatingPawns[key]!.progress * .pi) * 40 : 0
                
                PawnView(color: color, size: cellSize * 0.8)
                    .offset(y: -hopOffset)
                    .onTapGesture {
                        if color == game.currentPlayer && !isAnimating {
                            let currentPos = pawn.positionIndex ?? -1
                            game.movePawn(color: color, pawnId: pawn.id, steps: game.diceValue)
                            if let newPos = game.pawns[color]?.first(where: { $0.id == pawn.id })?.positionIndex,
                               newPos != currentPos {
                                animatePawnMovement(pawn: pawn, color: color, from: currentPos, to: newPos, steps: game.diceValue)
                            }
                        }
                    }
            }
        }
    }
    
    @ViewBuilder
    private func homePawnView(pawn: Pawn, color: PlayerColor, row: Int, col: Int, cellSize: CGFloat) -> some View {
        if isCorrectHomePosition(pawn: pawn, color: color, row: row, col: col) {
            let isSliding = slidingPawn?.color == color && slidingPawn?.id == pawn.id
            let slidingProgress = isSliding ? slidingPawn?.progress ?? 0 : 0
            
            // Calculate the path from home to start
            let homePos = getHomePosition(pawn: pawn, color: color)
            let startPos = getPathStartPosition(for: color)
            
            // Calculate the offset based on sliding progress
            let xOffset = slidingProgress * Double(startPos.col - homePos.col) * cellSize
            let yOffset = slidingProgress * Double(startPos.row - homePos.row) * cellSize
            
            PawnView(color: color, size: cellSize * 0.8)
                .offset(x: xOffset, y: yOffset)
                .onTapGesture {
                    let _ = debugPrintTapAndAnimation(pawn: pawn, color: color, isAnimating: isAnimating)
                    
                    if color == game.currentPlayer && !isAnimating && game.diceValue == 6 {
                        // Set initial animation state
                        slidingPawn = (color: color, id: pawn.id, progress: 0)
                        
                        // Animate to final position
                        withAnimation(.easeInOut(duration: 0.5)) {
                            slidingPawn?.progress = 1.0
                        }
                        
                        // Delay the actual move until after animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            print("DEBUG: Animation complete, executing move")
                            game.movePawn(color: color, pawnId: pawn.id, steps: game.diceValue)
                            slidingPawn = nil
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
    
    private func isCorrectHomePosition(pawn: Pawn, color: PlayerColor, row: Int, col: Int) -> Bool {
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
