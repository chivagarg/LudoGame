import SwiftUI
import AVFoundation

struct LudoGameView: View {
    static var renderCount = 0
    init() {
        Self.renderCount += 1
        print("LudoGameView rendered \(Self.renderCount) times")
    }
    @StateObject private var game = LudoGame()
    @State private var selectedPlayers: Set<PlayerColor> = Set(PlayerColor.allCases)
    
    var body: some View {
        VStack {
            if !game.gameStarted {
                startGameView
            } else if game.isGameOver {
                GameOverView(selectedPlayers: $selectedPlayers)
            } else {
                gameBoardView
            }
        }
        .padding()
        .environmentObject(game)
    }
    
    // MARK: - Settings Table View
    private struct SettingsTableView: View {
        @Binding var isAdminMode: Bool
        @Environment(\.colorScheme) var colorScheme
        
        var body: some View {
            VStack(spacing: 0) {
                // Header
                Text("Game Settings")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding(.bottom, 8)
                
                // Settings Table
                VStack(spacing: 0) {
                    // Table Header
                    HStack {
                        Text("Mode")
                            .font(.subheadline)
                            .foregroundColor(.green)
                        Spacer()
                        Text("Status")
                            .font(.subheadline)
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1))
                    
                    // Admin Mode Row
                    HStack {
                        Text("Admin Mode")
                            .font(.body)
                            .foregroundColor(.red)
                        Spacer()
                        Toggle("", isOn: $isAdminMode)
                            .labelsHidden()
                            .tint(.red)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(colorScheme == .dark ? Color.black : Color.white)
                }
                .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
            .padding()
            .background(colorScheme == .dark ? Color.black : Color.white)
            .cornerRadius(15)
            .shadow(radius: 2)
            .frame(width: 300)
        }
    }
    
    // MARK: - Admin Controls View
    private struct AdminControlsView: View {
        let currentPlayer: PlayerColor
        let eligiblePawns: Set<Int>
        let onTestRoll: (Int) -> Void
        
        var body: some View {
            VStack {
                Text("Current Player: \(currentPlayer.rawValue.capitalized)")
                    .font(.title2)
                
                HStack {
                    ForEach([1, 2, 3, 4, 5, 6, 48, 56], id: \.self) { value in
                        Button("\(value)") {
                            onTestRoll(value)
                        }
                        .font(.title3)
                        .padding(8)
                        .background(eligiblePawns.isEmpty ? (value == 48 || value == 56 ? Color.purple : Color.green) : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(!eligiblePawns.isEmpty)
                    }
                }
            }
        }
    }
    
    // MARK: - Start Game View
    private var startGameView: some View {
        VStack(spacing: 20) {
            Text("Ludo")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            SettingsTableView(isAdminMode: $game.isAdminMode)
            
            PlayerSelectionView(selectedPlayers: $selectedPlayers)
            
            Button("Start Game") {
                game.startGame(selectedPlayers: selectedPlayers)
            }
            .font(.title2)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(selectedPlayers.count < 2)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.05))
    }
    
    // MARK: - Game Board View
    private var gameBoardView: some View {
        VStack(spacing: 16) {
            if game.isAdminMode {
                AdminControlsView(
                    currentPlayer: game.currentPlayer,
                    eligiblePawns: game.eligiblePawns,
                    onTestRoll: { value in
                        game.testRollDice(value: value)
                    }
                )
            }
            
            ScoringPanelView(
                scores: game.scores,
                hasCompletedGame: { color in
                    game.hasCompletedGame(color: color)
                }
            )
            
            LudoBoardView()
        }
    }
}

struct LudoBoardView: View {
    @EnvironmentObject var game: LudoGame
    
    static var renderCount = 0
    let gridSize = 15
    
    @State private var isDiceRolling = false
    @State private var animatingPawns: [String: (start: Int, end: Int, progress: Double)] = [:]
    @State private var currentStep = 0
    @State private var isPathAnimating = false
    @State private var capturedPawns: [(color: PlayerColor, id: Int, progress: Double)] = []
    
    private func getDicePosition() -> (row: Int, col: Int)? {
        if game.hasCompletedGame(color: game.currentPlayer) {
            return nil
        }
        
        switch game.currentPlayer {
        case .red:
            return (row: 2, col: 2)  // Center of red home area
        case .green:
            return (row: 2, col: 11)  // Center of green home area
        case .yellow:
            return (row: 11, col: 11)  // Center of yellow home area
        case .blue:
            return (row: 11, col: 2)  // Center of blue home area
        }
    }
    
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
    
    private func animatePawnMovementForPath(pawn: PawnState, color: PlayerColor, from: Int, to: Int, steps: Int) {
        isPathAnimating = true
        currentStep = 0
        
        // Remove from homeToStartPawns if it's there (moving from starting home to path)
        // homeToStartPawns.removeAll(where: { $0.color == color && $0.id == pawn.id })
        
        // Play swish sound if moving from home
        if from == -1 {
            SoundManager.shared.playSound("swish")
        }
        
        func animateNextStep() {
            guard currentStep < steps else {
                isPathAnimating = false
                isDiceRolling = false  // Reset dice rolling state after pawn movement
                return
            }
            
            let key = "\(color.rawValue)-\(pawn.id)"
            let currentFrom = from + currentStep
            let currentTo = currentFrom + 1
            
            // Safety check: if we're at the end of the path, don't try to animate further
            if currentTo >= game.path(for: color).count {
                isPathAnimating = false
                return
            }
            
            animatingPawns[key] = (currentFrom, currentTo, 0)
            
            // Play hop sound for each step
            SoundManager.shared.playSound("hop")
            
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
            guard to >= 0 else {
                // Play victory sound if reaching home
                SoundManager.shared.playSound("victory")
                return
            }
            
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
                        // Play capture sound
                        SoundManager.shared.playSound("capture")
                        
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
    
    private func getStartingHomePosition(pawn: PawnState, color: PlayerColor) -> (row: Int, col: Int) {
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
    
    private func getCurrentPosition(pawn: PawnState, color: PlayerColor, positionIndex: Int) -> (row: Int, col: Int) {
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
        let _ = {
            Self.renderCount += 1
            print("LudoBoardView rendered \(Self.renderCount) times")
        }()

        return GeometryReader { geometry in
            let (boardSize, cellSize, boardOffsetX, boardOffsetY) = calculateBoardDimensions(geometry: geometry)
            
            ZStack {
                VStack(spacing: 0) {
                    ForEach(0..<gridSize, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<gridSize, id: \.self) { col in
                                let pawns = self.pawnsInCell(row: row, col: col)
                                
                                BoardCellView(
                                    pawnsInCell: pawns,
                                    parent: self,
                                    row: row,
                                    col: col,
                                    cellSize: cellSize
                                )
                                .equatable()
                            }
                        }
                    }
                }
                .frame(width: boardSize, height: boardSize)
                .cornerRadius(cellSize / 4)
                .overlay(
                    RoundedRectangle(cornerRadius: cellSize / 4)
                        .stroke(Color.black, lineWidth: 2)
                )
                
                // Dice View
                if let dicePos = getDicePosition() {
                    DiceView(value: game.diceValue, isRolling: isDiceRolling) {
                        // Only allow rolling if:
                        // 1. Not already rolling
                        // 2. No eligible pawns to move
                        // 3. No current roll (currentRollPlayer is nil)
                        if !isDiceRolling && game.eligiblePawns.isEmpty {
                            isDiceRolling = true
                            game.rollDice()
                            // Simulate rolling animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isDiceRolling = false
                            }
                        }
                    }
                    .position(
                        x: boardOffsetX + CGFloat(dicePos.col + 1) * cellSize,
                        y: boardOffsetY + CGFloat(dicePos.row + 1) * cellSize
                    )
                    .onChange(of: game.diceValue) { newValue in
                        // Only trigger animation if we're not already rolling from a tap
                        if !isDiceRolling {
                            isDiceRolling = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                isDiceRolling = false
                            }
                        }
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
                        PawnView(pawn: pawn, size: cellSize * 0.8, currentPlayer: game.currentPlayer)
                            .position(
                                x: startX + xOffset + cellSize/2,
                                y: startY + yOffset + cellSize/2
                            )
                    }
                }
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .onAppear {
                // Add observer for pawn movement animation
                NotificationCenter.default.addObserver(
                    forName: NSNotification.Name("AnimatePawnMovement"),
                    object: nil,
                    queue: .main
                ) { notification in
                    if let userInfo = notification.userInfo,
                       let color = userInfo["color"] as? PlayerColor,
                       let pawnId = userInfo["pawnId"] as? Int,
                       let from = userInfo["from"] as? Int,
                       let to = userInfo["to"] as? Int,
                       let steps = userInfo["steps"] as? Int,
                       let pawn = game.pawns[color]?.first(where: { $0.id == pawnId }) {
                        animatePawnMovementForPath(pawn: pawn, color: color, from: from, to: to, steps: steps)
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private func pawnsInCell(row: Int, col: Int) -> [PawnState] {
        var pawnsInCell: [PawnState] = []
        for (_, pwns) in game.pawns {
            for pawn in pwns {
                // Check home pawns
                if pawn.positionIndex == nil {
                    let homePos = getStartingHomePosition(pawn: pawn, color: pawn.color)
                    if homePos.row == row && homePos.col == col {
                        pawnsInCell.append(pawn)
                    }
                }
                // Check pawns on path
                else if let positionIndex = pawn.positionIndex, positionIndex >= 0 {
                    let currentPos = getCurrentPosition(pawn: pawn, color: pawn.color, positionIndex: positionIndex)
                    if currentPos.row == row && currentPos.col == col {
                        pawnsInCell.append(pawn)
                    }
                }
            }
        }
        return pawnsInCell
    }

    // MARK: - BoardCellView
    struct BoardCellView: View, Equatable {
        let pawnsInCell: [PawnState]
        let parent: LudoBoardView
        let row: Int
        let col: Int
        let cellSize: CGFloat

        static func == (lhs: BoardCellView, rhs: BoardCellView) -> Bool {
            let lhsPawnIDs = lhs.pawnsInCell.map { $0.id }.sorted()
            let rhsPawnIDs = rhs.pawnsInCell.map { $0.id }.sorted()
            
            // For the view to be considered "equal" (and thus skip a re-render),
            // the pawns in the cell must be identical.
            return lhsPawnIDs == rhsPawnIDs
        }

        var body: some View {
            parent.cellView(row: row, col: col, cellSize: cellSize)
        }
    }
    
    @ViewBuilder
    func cellView(row: Int, col: Int, cellSize: CGFloat) -> some View {
        struct RenderCounter {
            static var count = 0
        }
        RenderCounter.count += 1
        print("cellView rendered \(RenderCounter.count) times (row: \(row), col: \(col))")
        return ZStack {
            cellBackground(row: row, col: col, cellSize: cellSize)
            cellPawns(row: row, col: col, cellSize: cellSize)
        }
        .frame(width: cellSize, height: cellSize)
    }
    
    @ViewBuilder
    private func cellBackground(row: Int, col: Int, cellSize: CGFloat) -> some View {
        ZStack {
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
            // Green Safe Zone
            } else if col == 7 && (1...5).contains(row) {
                Rectangle().fill(Color.green.opacity(0.7))
            // Yellow Safe Zone
            } else if row == 7 && (9...13).contains(col) {
                Rectangle().fill(Color.yellow.opacity(0.7))
            // Blue Safe Zone
            } else if col == 7 && (9...13).contains(row) {
                Rectangle().fill(Color.blue.opacity(0.7))
            // 3 by 3 center
            } else if row == 6 && col == 6 {
                Path { path in
                         path.move(to: CGPoint(x: 0, y: 0))
                         path.addLine(to: CGPoint(x: 0, y: cellSize))
                         path.addLine(to: CGPoint(x: cellSize, y: cellSize))
                         path.closeSubpath()
                     }
                     .fill(Color.red.opacity(0.7))

                     Path { path in
                         path.move(to: CGPoint(x: 0, y: 0))
                         path.addLine(to: CGPoint(x: cellSize, y: 0))
                         path.addLine(to: CGPoint(x: cellSize, y: cellSize))
                         path.closeSubpath()
                     }
                     .fill(Color.green.opacity(0.7))
            } else if row == 6 && col == 7 {
                Rectangle().fill(Color.green.opacity(0.7))
            } else if row == 6 && col == 8 {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: cellSize, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: cellSize))
                    path.closeSubpath()
                }
                .fill(Color.green.opacity(0.7))

                Path { path in
                    path.move(to: CGPoint(x: cellSize, y: 0))
                    path.addLine(to: CGPoint(x: cellSize, y: cellSize))
                    path.addLine(to: CGPoint(x: 0, y: cellSize))
                    path.closeSubpath()
                }
                .fill(Color.yellow.opacity(0.7))
                
            } else if row == 7 && col == 6 {
                Rectangle().fill(Color.red.opacity(0.7))
            } else if row == 7 && col == 7 {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: cellSize/2, y: cellSize/2))
                    path.addLine(to: CGPoint(x: 0, y: cellSize))
                    path.closeSubpath()
                }
                .fill(Color.red.opacity(0.7))

                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: cellSize/2, y: cellSize/2))
                    path.addLine(to: CGPoint(x: cellSize, y: 0))
                    path.closeSubpath()
                }
                .fill(Color.green.opacity(0.7))

                Path { path in
                    path.move(to: CGPoint(x: cellSize, y: 0))
                    path.addLine(to: CGPoint(x: cellSize/2, y: cellSize/2))
                    path.addLine(to: CGPoint(x: cellSize, y: cellSize))
                    path.closeSubpath()
                }
                .fill(Color.yellow.opacity(0.7))

                Path { path in
                    path.move(to: CGPoint(x: 0, y: cellSize))
                    path.addLine(to: CGPoint(x: cellSize/2, y: cellSize/2))
                    path.addLine(to: CGPoint(x: cellSize, y: cellSize))
                    path.closeSubpath()
                }
                .fill(Color.blue.opacity(0.7))
            } else if row == 7 && col == 8 {
                Rectangle().fill(Color.yellow.opacity(0.7))
            } else if row == 8 && col == 6 {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: cellSize))
                    path.addLine(to: CGPoint(x: cellSize, y: 0))
                    path.closeSubpath()
                }
                .fill(Color.red.opacity(0.7))

                Path { path in
                    path.move(to: CGPoint(x: 0, y: cellSize))
                    path.addLine(to: CGPoint(x: cellSize, y: cellSize))
                    path.addLine(to: CGPoint(x: cellSize, y: 0))
                    path.closeSubpath()
                }
                .fill(Color.blue.opacity(0.7))
            } else if row == 8 && col == 7 {
                Rectangle().fill(Color.blue.opacity(0.7))
            } else if row == 8 && col == 8 {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: cellSize, y: 0))
                    path.addLine(to: CGPoint(x: cellSize, y: cellSize))
                    path.closeSubpath()
                }
                .fill(Color.yellow.opacity(0.7))

                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: cellSize))
                    path.addLine(to: CGPoint(x: cellSize, y: cellSize))
                    path.closeSubpath()
                }
                .fill(Color.blue.opacity(0.7))
            } else {
                Rectangle().fill(Color.white)
            }
            
            // Color-coded star spaces
            if (row == 6 && col == 1) || (row == 2 && col == 6) {
                Rectangle().fill(Color.red.opacity(0.3))
            } else if (row == 1 && col == 8) || (row == 6 && col == 12) {
                Rectangle().fill(Color.green.opacity(0.3))
            } else if (row == 8 && col == 13) || (row == 12 && col == 8) {
                Rectangle().fill(Color.yellow.opacity(0.3))
            } else if (row == 13 && col == 6) || (row == 8 && col == 2) {
                Rectangle().fill(Color.blue.opacity(0.3))
            }
            
            // Draw star if this is a star space
            if isStarSpace(row: row, col: col) {
                Image(systemName: "star.fill")
                    .foregroundColor(.black)
                    .font(.system(size: cellSize * 0.5))
                    .shadow(color: .black, radius: 1, x: 0, y: 0)
                    .overlay(
                        Image(systemName: "star.fill")
                            .foregroundColor(.black)
                            .font(.system(size: cellSize * 0.5))
                            .blur(radius: 1)
                            .opacity(0.5)
                    )
            }
            
            // Only draw stroke for cells outside the center 3x3 grid
            if !(6...8).contains(row) || !(6...8).contains(col) {
                Rectangle().stroke(Color.black, lineWidth: 0.5)
            }
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
        ForEach(game.pawns[color] ?? [], id: \.id) { pawnState in
            pawnView(pawn: pawnState, color: color, row: row, col: col, cellSize: cellSize)
        }
    }

    @ViewBuilder
    private func pawnView(pawn: PawnState, color: PlayerColor, row: Int, col: Int, cellSize: CGFloat) -> some View {
        Group {
            if let positionIndex = pawn.positionIndex {
                if positionIndex >= 0 {
                    // Pawn is on the path
                    pathPawnView(pawn: pawn, color: color, positionIndex: positionIndex, row: row, col: col, cellSize: cellSize)
                } else {
                    // Pawn is in ending home
                    endingHomePawnView(pawn: pawn, color: color, row: row, col: col, cellSize: cellSize)
                }
            } else {
                // Pawn is in starting home
                homePawnView(pawn: pawn, color: color, row: row, col: col, cellSize: cellSize)
            }
        }
    }
    

    private func countPawnsInCell(row: Int, col: Int) -> Int {
        var count = 0
        for (_, pwns) in game.pawns {
            for pawn in pwns {
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

    private func getPawnIndexInCell(pawn: PawnState, color: PlayerColor, row: Int, col: Int) -> Int {
        var index = 0
        for (_, pwns) in game.pawns {
            for p in pwns {
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
    private func pathPawnView(pawn: PawnState, color: PlayerColor, positionIndex: Int, row: Int, col: Int, cellSize: CGFloat) -> some View {
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
                
                PawnView(pawn: pawn, size: size, currentPlayer: game.currentPlayer)
                    .offset(x: xOffset, y: yOffset - hopOffset)
                    .shadow(color: .black.opacity(isAnimating ? 0.3 : 0.1), radius: isAnimating ? 4 : 2)
                    .onTapGesture {
                        if !isPathAnimating {
                            if game.isValidMove(color: color, pawnId: pawn.id) {
                                let currentPos = pawn.positionIndex ?? -1
                                let steps = game.diceValue
                                
                                if let destinationIndex = game.getDestinationIndex(color: color, pawnId: pawn.id) {
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
    }
    
    @ViewBuilder
    private func endingHomePawnView(pawn: PawnState, color: PlayerColor, row: Int, col: Int, cellSize: CGFloat) -> some View {
        if isCorrectEndingHomePosition(pawn: pawn, color: color, row: row, col: col) {
            // Count total pawns in this ending home
            let totalPawns = game.pawns[color]?.filter { $0.positionIndex == -1 }.count ?? 0
            
            // Calculate this pawn's index in the ending home
            let pawnIndex = game.pawns[color]?.filter { $0.positionIndex == -1 }.firstIndex(where: { $0.id == pawn.id }) ?? 0
            
            // Calculate size and position
            let (size, xOffset, yOffset) = calculatePawnSizeAndOffset(cellSize: cellSize, totalPawns: totalPawns, index: pawnIndex)
            
            PawnView(pawn: pawn, size: size, currentPlayer: game.currentPlayer)
                .offset(x: xOffset, y: yOffset)
                .shadow(color: .black.opacity(0.2), radius: 2)
        }
    }
    
    private func isCorrectEndingHomePosition(pawn: PawnState, color: PlayerColor, row: Int, col: Int) -> Bool {
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
    private func homePawnView(pawn: PawnState, color: PlayerColor, row: Int, col: Int, cellSize: CGFloat) -> some View {
        // Only draw pawn if the player color is selected
        if game.selectedPlayers.contains(color) && isCorrectStartingHomePosition(pawn: pawn, color: color, row: row, col: col) {
            PawnView(pawn: pawn, size: cellSize * 0.8, currentPlayer: game.currentPlayer)
                .onTapGesture {
                    print("--- HOME PAWN TAPPED ---")
                    print("Pawn: \(pawn.color), id: \(pawn.id)")
                    print("Current Player: \(game.currentPlayer)")
                    print("Dice Value: \(game.diceValue)")
                    print("Is Eligible: \(game.eligiblePawns.contains(pawn.id))")
                    
                    if color == game.currentPlayer && !isPathAnimating && game.diceValue == 6 && game.eligiblePawns.contains(pawn.id) {
                        print("Condition met. Calling movePawn.")
                        // Instantly move the pawn without animation or sound
                        game.movePawn(color: color, pawnId: pawn.id, steps: game.diceValue)
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
    
    private func isCorrectStartingHomePosition(pawn: PawnState, color: PlayerColor, row: Int, col: Int) -> Bool {
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
}

struct PawnView: View {
    let pawn: PawnState
    let size: CGFloat
    let currentPlayer: PlayerColor

    private var pawnColor: Color {
        switch pawn.color {
        case .red: return .red
        case .green: return .green
        case .yellow: return .yellow
        case .blue: return .blue
        }
    }

    private var isCurrentPlayer: Bool {
        pawn.color == currentPlayer
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(pawnColor)
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)

            Circle()
                .stroke(Color.white.opacity(0.8), lineWidth: size * 0.05)
                .frame(width: size * 0.6, height: size * 0.6)
        }
    }
}

#Preview {
    LudoGameView()
} 
