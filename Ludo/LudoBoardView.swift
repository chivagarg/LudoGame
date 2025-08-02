import SwiftUI
import AVFoundation

// MARK: - Trail Particle Structure
struct TrailParticle: Identifiable {
    let id = UUID()
    let position: (row: Int, col: Int)
    let color: PlayerColor
    var opacity: Double
    var age: Double // 0.0 to 1.0, where 1.0 means fully faded
    let createdAt: Date
}

struct LudoBoardView: View {
    @EnvironmentObject var game: LudoGame
    
    static var renderCount = 0
    let gridSize = 15
    
    let maximized: Bool
    
    @State private var isDiceRolling = false
    @State private var pathAnimatingPawns: [String: (start: Int, end: Int, progress: Double)] = [:]
    @State private var homeToStartPawns: [(pawn: PawnState, progress: Double)] = []
    @State private var capturedPawns: [(pawn: PawnState, progress: Double)] = []
    @State private var currentStep = 0
    @State private var isPathAnimating = false
    @State private var isAnimatingHomeToStart = false
    @State private var isAnimatingCapture = false
    @State private var previousPawnsAtHome = 0
    
    // MARK: - Trail Animation State
    @State private var trailParticles: [TrailParticle] = []
    @State private var particleTimer: Timer? = nil // Timer for particle aging
    
    private let pawnResizeFactor: CGFloat = 1.0
    private var boardScaleFactor: CGFloat { maximized ? 0.95 : 0.90 }
    
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
    
    private func calculateBoardDimensions(geometry: GeometryProxy) -> (boardSize: CGFloat, cellSize: CGFloat, boardOffsetX: CGFloat, boardOffsetY: CGFloat) {
        let boardSize = min(geometry.size.width, geometry.size.height) * boardScaleFactor
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
    
    private func animatePawnMovementForPath(pawn: PawnState, color: PlayerColor, from: Int, steps: Int, backward: Bool = false, completion: @escaping () -> Void) {
        isPathAnimating = true
        currentStep = 0
                
        func animateNextStep() {
            guard currentStep < steps else {
                let key = "\(color.rawValue)-\(pawn.id)"
                self.pathAnimatingPawns.removeValue(forKey: key)  // Clear specific pawn data
                completion()
                return
            }
            
            let key = "\(color.rawValue)-\(pawn.id)"
            let direction = backward ? -1 : 1
            
            let currentFrom = from + (currentStep * direction)
            let currentTo = currentFrom + direction
            
            // Safety check to avoid going off the path
            if backward {
                if currentTo < 0 {
                    let key = "\(color.rawValue)-\(pawn.id)"
                    pathAnimatingPawns.removeValue(forKey: key)  // Clear specific pawn data
                    isPathAnimating = false
                    return
                }
            } else {
                if currentTo >= game.path(for: color).count {
                    let key = "\(color.rawValue)-\(pawn.id)"
                    pathAnimatingPawns.removeValue(forKey: key)  // Clear specific pawn data
                    isPathAnimating = false
                    return
                }
            }
            
            // Spawn trail particle at the starting position of this step
            let startPosition = game.path(for: color)[currentFrom]
            let trailParticle = TrailParticle(
                position: (row: startPosition.row, col: startPosition.col),
                color: color,
                opacity: 0.6,
                age: 0.0,
                createdAt: Date()
            )
            trailParticles.append(trailParticle)
            startParticleAgingTimerIfNeeded() // Start timer when first particle appears
            
            pathAnimatingPawns[key] = (start: currentFrom, end: currentTo, progress: 0)
            
            // Play hop sound for each step
            if backward {
                SoundManager.shared.playReverseHopSound()
            } else {
                SoundManager.shared.playPawnHopSound()
            }
            
            withAnimation(.spring(response: 0.15, dampingFraction: 0.3, blendDuration: 0)) {
                pathAnimatingPawns[key]?.progress = 1.0
            }
            
            currentStep += 1
            
            // Schedule next step with shorter delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                animateNextStep()
            }
        }
        
        // Start the animation
        animateNextStep()
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
        if let animation = pathAnimatingPawns[key] {
            let progress = animation.progress
            let startPos = game.path(for: color)[animation.start]
            let endPos = game.path(for: color)[animation.end]
            
            // Calculate current position with a higher hop
            let currentRow = Int(Double(startPos.row) + Double(endPos.row - startPos.row) * progress)
            let currentCol = Int(Double(startPos.col) + Double(endPos.col - startPos.col) * progress)
            
            return (row: currentRow, col: currentCol)
        }
        let position = game.path(for: color)[positionIndex]
        return (row: position.row, col: position.col)
    }
    
    var body: some View {
        let _ = {
            #if DEBUG
            Self.renderCount += 1
            print("[DEBUG] LudoBoardView rendered", Self.renderCount)
            #endif
        }()

        return GeometryReader { geometry in
            let (boardSize, cellSize, boardOffsetX, boardOffsetY) = calculateBoardDimensions(geometry: geometry)

            ZStack {
                // Board Grid extracted into a helper view
                boardGridView(boardSize: boardSize, cellSize: cellSize)

                // Player panels extracted into a helper view
                playerPanelsView(boardOffsetY: boardOffsetY)

                // Animation overlays extracted into dedicated helper views
                homeToStartPawnAnimationOverlay(boardOffsetX: boardOffsetX, boardOffsetY: boardOffsetY, cellSize: cellSize)
                capturedPawnAnimationOverlay(boardOffsetX: boardOffsetX, boardOffsetY: boardOffsetY, cellSize: cellSize)
                
                // MARK: - Trail Particles Overlay
                trailParticlesOverlay(boardOffsetX: boardOffsetX, boardOffsetY: boardOffsetY, cellSize: cellSize)
                // Confetti and +10 overlay
                ConfettiOverlay()
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .onChange(of: game.totalPawnsAtFinishingHome) { newCount in
                if newCount > previousPawnsAtHome {
                    SoundManager.shared.playPawnReachedHomeSound()
                }
                previousPawnsAtHome = newCount
            }
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
                        let moveDirection = userInfo["moveDirection"] as? String
                        let backward = (moveDirection == "backward")
                        
                        animatePawnMovementForPath(pawn: pawn, color: color, from: from, steps: steps, backward: backward) {
                            game.movePawn(color: color, pawnId: pawnId, steps: steps, backward: backward)
                            isPathAnimating = false
                            isDiceRolling = false
                        }
                    }
                }
                // Sync initial pawn count
                previousPawnsAtHome = game.totalPawnsAtFinishingHome
                
                // No need to start particle timer here; it will start when particles are added
            }
            .onReceive(NotificationCenter.default.publisher(for: .animatePawnFromHome)) { notification in
                guard let userInfo = notification.userInfo,
                      let color = userInfo["color"] as? PlayerColor,
                      let pawnId = userInfo["pawnId"] as? Int,
                      let pawn = game.pawns[color]?.first(where: { $0.id == pawnId }) else { return }
                
                isAnimatingHomeToStart = true // <-- Lock the UI
                
                if color == .red && pawnId == 0 {
                    GameLogger.shared.log("🐞 DEBUG LOG 3: Starting 'move from home' animation for Red Pawn 0. Its positionIndex is: \(String(describing: pawn.positionIndex))", level: .debug)
                }
                
                homeToStartPawns.append((pawn: pawn, progress: 0))

                let animationDuration = 0.25
                
                withAnimation(.easeInOut(duration: animationDuration)) {
                    if let index = homeToStartPawns.firstIndex(where: { $0.pawn.id == pawn.id && $0.pawn.color == color }) {
                        homeToStartPawns[index].progress = 1.0
                    }
                }
                
                // After the animation duration, complete the move in the model
                DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) { // Match the animation duration
                    homeToStartPawns.removeAll { $0.pawn.id == pawn.id && $0.pawn.color == color }
                    game.completeMoveFromHome(color: color, pawnId: pawnId)
                    isAnimatingHomeToStart = false // <-- Unlock the UI
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .animatePawnCapture)) { notification in
                guard let userInfo = notification.userInfo,
                      let color = userInfo["color"] as? PlayerColor,
                      let pawnId = userInfo["pawnId"] as? Int,
                      let pawn = game.pawns[color]?.first(where: { $0.id == pawnId }),
                      let startPositionIndex = pawn.positionIndex // We need the start index to calculate path length
                else { return }
                
                SoundManager.shared.playPawnCaptureSound()
                game.isBusy = true // Block moves/rolls during capture animation
                isAnimatingCapture = true // <-- Lock for capture
                
                capturedPawns.append((pawn: pawn, progress: 0))
                
                // --- Dynamically Calculate Animation Duration ---
                let animationPath = createCaptureAnimationPath(for: pawn, from: startPositionIndex)
                let pathLength = Double(animationPath.count - 1)
                let calculatedDuration = pathLength / GameConstants.captureAnimationCellsPerSecond
                let animationDuration = max(0.8, calculatedDuration) // Enforce a minimum duration

                withAnimation(.linear(duration: animationDuration)) {
                    if let index = capturedPawns.firstIndex(where: { $0.pawn.id == pawnId && $0.pawn.color == color }) {
                        capturedPawns[index].progress = 1.0
                    }
                }
                
                // After the animation duration, complete the move in the model
                DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                    game.completePawnCapture(color: color, pawnId: pawnId)
                    capturedPawns.removeAll { $0.pawn.id == pawnId && $0.pawn.color == color }
                    isAnimatingCapture = false // <-- Unlock for capture
                    // Step 3: Unblock game and trigger AI if needed
                    game.isBusy = false
                    if game.aiControlledPlayers.contains(game.currentPlayer) {
                        game.handleAITurn()
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    @ViewBuilder
    private func playerPanelsView(boardOffsetY: CGFloat) -> some View {
        // Calculate the required vertical padding to make the panels "hang" off the board.
        // Panel height is 100. We want 15% (15pt) overlap, so 85% (85pt) should be outside.
        // The padding from the screen edge needs to be the board's offset minus the 85pt overhang.
        let verticalPadding = boardOffsetY - 85

        VStack {
            // Top Row: Red and Green Panels
            HStack {
                PlayerPanelView(
                    color: .red,
                    showDice: game.currentPlayer == .red,
                    diceValue: game.diceValue,
                    isDiceRolling: isDiceRolling,
                    onDiceTap: {
                        if !isDiceRolling && game.eligiblePawns.isEmpty && !game.isBusy {
                            isDiceRolling = true
                            game.rollDice()
                            DispatchQueue.main.asyncAfter(deadline: .now() + GameConstants.diceAnimationDuration) {
                                isDiceRolling = false
                            }
                        }
                    }
                )
                .environmentObject(game)
                .fixedSize(horizontal: true, vertical: true)
                
                Spacer(minLength: 100)
                
                PlayerPanelView(
                    color: .green,
                    showDice: game.currentPlayer == .green,
                    diceValue: game.diceValue,
                    isDiceRolling: isDiceRolling,
                    onDiceTap: {
                        if !isDiceRolling && game.eligiblePawns.isEmpty && !game.isBusy {
                            isDiceRolling = true
                            game.rollDice()
                            DispatchQueue.main.asyncAfter(deadline: .now() + GameConstants.diceAnimationDuration) {
                                isDiceRolling = false
                            }
                        }
                    }
                )
                .environmentObject(game)
                .fixedSize(horizontal: true, vertical: true)
            }
            
            Spacer()
            
            // Bottom Row: Blue and Yellow Panels
            HStack {
                PlayerPanelView(
                    color: .blue,
                    showDice: game.currentPlayer == .blue,
                    diceValue: game.diceValue,
                    isDiceRolling: isDiceRolling,
                    onDiceTap: {
                        if !isDiceRolling && game.eligiblePawns.isEmpty && !game.isBusy {
                            isDiceRolling = true
                            game.rollDice()
                            DispatchQueue.main.asyncAfter(deadline: .now() + GameConstants.diceAnimationDuration) {
                                isDiceRolling = false
                            }
                        }
                    }
                )
                .environmentObject(game)
                .fixedSize(horizontal: true, vertical: false)
                
                Spacer(minLength: 100)
                
                PlayerPanelView(
                    color: .yellow,
                    showDice: game.currentPlayer == .yellow,
                    diceValue: game.diceValue,
                    isDiceRolling: isDiceRolling,
                    onDiceTap: {
                        if !isDiceRolling && game.eligiblePawns.isEmpty && !game.isBusy {
                            isDiceRolling = true
                            game.rollDice()
                            DispatchQueue.main.asyncAfter(deadline: .now() + GameConstants.diceAnimationDuration) {
                                isDiceRolling = false
                            }
                        }
                    }
                )
                .environmentObject(game)
                .fixedSize(horizontal: true, vertical: false)
            }
        }
        .padding(.vertical, verticalPadding)
    }
    
    @ViewBuilder
    private func boardGridView(boardSize: CGFloat, cellSize: CGFloat) -> some View {
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
                            cellSize: cellSize,
                            currentPlayer: game.currentPlayer,
                            eligiblePawns: game.eligiblePawns
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
    }
    
    private func pawnsInCell(row: Int, col: Int) -> [PawnState] {
        var pawnsInCell: [PawnState] = []
        for (_, pwns) in game.pawns {
            for pawn in pwns {
                // Exclude pawns currently being captured (in capturedPawns)
                if capturedPawns.contains(where: { $0.pawn.id == pawn.id && $0.pawn.color == pawn.color }) {
                    continue
                }
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
        let currentPlayer: PlayerColor
        let eligiblePawns: Set<Int>

        // Compute the set of eligible pawn IDs in this cell
        var eligiblePawnIdsInCell: Set<Int> {
            return Set(pawnsInCell.filter { $0.color == currentPlayer && eligiblePawns.contains($0.id) }.map { $0.id })
        }

        static func == (lhs: BoardCellView, rhs: BoardCellView) -> Bool {
            // Create a unique identifier string (e.g., "red-0") for each pawn so pawns with the
            // same id but different colors are considered different
            let lhsPawnKeys = lhs.pawnsInCell.map { "\($0.color.rawValue)-\($0.id)" }.sorted()
            let rhsPawnKeys = rhs.pawnsInCell.map { "\($0.color.rawValue)-\($0.id)" }.sorted()
            // Also compare eligible pawn IDs in the cell
            return lhsPawnKeys == rhsPawnKeys && lhs.eligiblePawnIdsInCell == rhs.eligiblePawnIdsInCell
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
        if row == 7 && col == 7 {
            renderCenterCell(row: row, col: col, cellSize: cellSize)
        } else if (6...8).contains(row) && (6...8).contains(col) {
            EmptyView()
        } else {
            ZStack {
                if row < 6 && col < 6 {
                    if (row == 1 || row == 4) && (col == 1 || col == 4) {
                        Rectangle().fill(Color.white)
                        Rectangle().fill(PlayerColor.red.secondaryColor)
                    } else {
                        Rectangle().fill(PlayerColor.red.primaryColor)
                    }
                // Green Home Area
                } else if row < 6 && col > 8 {
                    if (row == 1 || row == 4) && (col == 10 || col == 13) {
                        Rectangle().fill(Color.white)
                        Rectangle().fill(PlayerColor.green.secondaryColor)
                    } else {
                        Rectangle().fill(PlayerColor.green.primaryColor)
                    }
                // Blue Home Area
                } else if row > 8 && col < 6 {
                    if (row == 10 || row == 13) && (col == 1 || col == 4) {
                        Rectangle().fill(Color.white)
                        Rectangle().fill(PlayerColor.blue.secondaryColor)
                    } else {
                        Rectangle().fill(PlayerColor.blue.primaryColor)
                    }
                // Yellow Home Area
                } else if row > 8 && col > 8 {
                    if (row == 10 || row == 13) && (col == 10 || col == 13) {
                        Rectangle().fill(Color.white)
                        Rectangle().fill(PlayerColor.yellow.secondaryColor)
                    } else {
                        Rectangle().fill(PlayerColor.yellow.primaryColor)
                    }
                // Red Safe Zone
                } else if row == 7 && (1...5).contains(col) {
                    Rectangle().fill(PlayerColor.red.primaryColor)
                // Green Safe Zone
                } else if col == 7 && (1...5).contains(row) {
                    Rectangle().fill(PlayerColor.green.primaryColor)
                // Yellow Safe Zone
                } else if row == 7 && (9...13).contains(col) {
                    Rectangle().fill(PlayerColor.yellow.primaryColor)
                // Blue Safe Zone
                } else if col == 7 && (9...13).contains(row) {
                    Rectangle().fill(PlayerColor.blue.primaryColor)
                } else {
                    // Path cells
                    Rectangle().fill(Color.white)
                }
                
                // Color-coded star spaces
                if (row == 6 && col == 1) || (row == 2 && col == 6) {
                    Rectangle().fill(PlayerColor.red.secondaryColor)
                } else if (row == 1 && col == 8) || (row == 6 && col == 12) {
                    Rectangle().fill(PlayerColor.green.secondaryColor)
                } else if (row == 8 && col == 13) || (row == 12 && col == 8) {
                    Rectangle().fill(PlayerColor.yellow.secondaryColor)
                } else if (row == 13 && col == 6) || (row == 8 && col == 2) {
                    Rectangle().fill(PlayerColor.blue.secondaryColor)
                }
                
                // Only draw stroke for cells outside the center 3x3 grid
                if !(6...8).contains(row) || !(6...8).contains(col) {
                    Rectangle().stroke(Color.black, lineWidth: 0.5)
                }
            }
        }
    }

    @ViewBuilder
    private func renderCenterCell(row: Int, col: Int, cellSize: CGFloat) -> some View {
        let largeCellSize = cellSize * 3
        ZStack {            
            // Red triangle
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: largeCellSize/2, y: largeCellSize/2))
                path.addLine(to: CGPoint(x: 0, y: largeCellSize))
                path.closeSubpath()
            }
            .fill(PlayerColor.red.primaryColor)
            
            // Yellow triangle
            Path { path in
                path.move(to: CGPoint(x: largeCellSize, y: 0)) 
                path.addLine(to: CGPoint(x: largeCellSize/2, y: largeCellSize/2)) 
                path.addLine(to: CGPoint(x: largeCellSize, y: largeCellSize)) 
                path.closeSubpath()
            }
            .fill(PlayerColor.yellow.primaryColor)

            // Green triangle
            Path { path in
                path.move(to: CGPoint(x: largeCellSize, y: 0)) 
                path.addLine(to: CGPoint(x: largeCellSize/2, y: largeCellSize/2)) 
                path.addLine(to: CGPoint(x: 0, y: 0)) 
                path.closeSubpath()
            }
            .fill(PlayerColor.green.primaryColor)

            // Blue triangle
            Path { path in
                path.move(to: CGPoint(x: 0, y: largeCellSize)) 
                path.addLine(to: CGPoint(x: largeCellSize/2, y: largeCellSize/2)) 
                path.addLine(to: CGPoint(x: largeCellSize, y: largeCellSize)) 
                path.closeSubpath()
            }
            .fill(PlayerColor.blue.primaryColor)
            
            // Draw X using two diagonal lines across the entire 3x3 area
            Path { path in
                // First diagonal (top-left to bottom-right)
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: largeCellSize, y: largeCellSize))
                
                // Second diagonal (top-right to bottom-left)
                path.move(to: CGPoint(x: largeCellSize, y: 0))
                path.addLine(to: CGPoint(x: 0, y: largeCellSize))
            }
            .stroke(Color.black, lineWidth: 2)
        }
        .frame(width: largeCellSize, height: largeCellSize)
    }
    
    @ViewBuilder
    private func cellPawns(row: Int, col: Int, cellSize: CGFloat) -> some View {
        ForEach(PlayerColor.allCases, id: \.self) { color in
            pawnsForColor(color: color, row: row, col: col, cellSize: cellSize)
        }
    }

    @ViewBuilder
    private func pawnsForColor(color: PlayerColor, row: Int, col: Int, cellSize: CGFloat) -> some View {
        ForEach((game.pawns[color] ?? []).filter { pawnState in
            // Exclude pawns currently being captured (in capturedPawns)
            !capturedPawns.contains(where: { $0.pawn.id == pawnState.id && $0.pawn.color == pawnState.color })
        }, id: \.id) { pawnState in
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
                 // Pawn is in starting home (and not currently animating out)
                if !homeToStartPawns.contains(where: { $0.pawn.id == pawn.id && $0.pawn.color == color }) {
                    homePawnView(pawn: pawn, color: color, row: row, col: col, cellSize: cellSize)
                }
            }
        }
    }
    

    private func countPawnsInCell(row: Int, col: Int) -> Int {
        var count = 0
        for (_, pwns) in game.pawns {
            for pawn in pwns {
                // Exclude pawns currently being captured (in capturedPawns)
                if capturedPawns.contains(where: { $0.pawn.id == pawn.id && $0.pawn.color == pawn.color }) {
                    continue
                }
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
            let size = cellSize * pawnResizeFactor // Keep original size for single pawn
            return (size, 0, 0) // Center in cell with no offset
        }
        
        // Base size for calculations
        let baseSize = cellSize * pawnResizeFactor
        
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
                let hopOffset = pathAnimatingPawns[key] != nil ? sin(pathAnimatingPawns[key]!.progress * .pi) * 60 : 0
                let isAnimating = pathAnimatingPawns[key] != nil
                
                let isExpanded = isExpanded(pawn: pawn, row: row, col: col)
                
                if isExpanded {
                    PawnView(pawn: pawn, size: cellSize * pawnResizeFactor)
                        .offset(x: 0, y: -hopOffset)
                        .shadow(color: .black.opacity(isAnimating ? 0.3 : 0.1), radius: isAnimating ? 4 : 2)
                        .zIndex(1)
                        .onTapGesture {
                            handlePawnTap(pawn: pawn, color: color)
                        }
                } else {
                    // Count total pawns in this cell
                    let totalPawns = countPawnsInCell(row: row, col: col)
                    // Calculate this pawn's index in the cell
                    let pawnIndex = getPawnIndexInCell(pawn: pawn, color: color, row: row, col: col)

                    let (size, xOffset, yOffset) = calculatePawnSizeAndOffset(cellSize: cellSize, totalPawns: totalPawns, index: pawnIndex)
                    PawnView(pawn: pawn, size: size)
                        .offset(x: xOffset, y: yOffset - hopOffset)
                        .shadow(color: .black.opacity(isAnimating ? 0.3 : 0.1), radius: isAnimating ? 4 : 2)
                        .zIndex(0)
                        .onTapGesture {
                            handlePawnTap(pawn: pawn, color: color)
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
            
            PawnView(pawn: pawn, size: size)
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
            PawnView(pawn: pawn, size: cellSize * pawnResizeFactor)
                .onTapGesture {
                    guard !game.aiControlledPlayers.contains(color) else { return } // <-- Block AI pawn taps
                    
                    print("--- HOME PAWN TAPPED ---")
                    print("Pawn: \(pawn.color), id: \(pawn.id)")
                    print("Current Player: \(game.currentPlayer)")
                    print("Dice Value: \(game.diceValue)")
                    print("Is Eligible: \(game.eligiblePawns.contains(pawn.id))")
                    
                    if color == .red && pawn.id == 0 {
                        GameLogger.shared.log("🐞 DEBUG LOG 2: Tapped Red Pawn 0 at home. Its positionIndex is: \(String(describing: pawn.positionIndex))", level: .debug)
                    }
                    
                    if color == game.currentPlayer && !isPathAnimating && !isAnimatingHomeToStart && !isAnimatingCapture && !isDiceRolling && game.diceValue == 6 && game.eligiblePawns.contains(pawn.id) {
                        print("Condition met. Calling movePawn.")
                        // Instantly move the pawn without animation or sound
                        game.movePawn(color: color, pawnId: pawn.id, steps: game.diceValue)
                    }
                }
        }
    }
    
    // Helper function to get the start position on the path for each color
    private func getPathStartPosition(for color: PlayerColor) -> (row: Int, col: Int) {
        let path = game.path(for: color)
        guard let firstPos = path.first else {
            return (0, 0) // Should never happen
        }
        return (row: firstPos.row, col: firstPos.col)
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

    @ViewBuilder
    private func homeToStartPawnAnimationOverlay(boardOffsetX: CGFloat, boardOffsetY: CGFloat, cellSize: CGFloat) -> some View {
        ForEach(homeToStartPawns, id: \.pawn.id) { homeToStartPawn in
            let pawn = homeToStartPawn.pawn
            let progress = homeToStartPawn.progress
            
            let homePosition = getStartingHomePosition(pawn: pawn, color: pawn.color)
            let pathStartPosition = game.path(for: pawn.color)[0]

            let startX = CGFloat(homePosition.col) + 0.5
            let startY = CGFloat(homePosition.row) + 0.5
            let endX = CGFloat(pathStartPosition.col) + 0.5
            let endY = CGFloat(pathStartPosition.row) + 0.5
            
            let currentX = startX + (endX - startX) * progress
            let currentY = startY + (endY - startY) * progress
            
            let hopHeight = -cellSize * 1.5
            let yOffset = sin(progress * .pi) * hopHeight
            
            PawnView(pawn: pawn, size: cellSize * 0.8)
                .position(
                    x: boardOffsetX + currentX * cellSize,
                    y: boardOffsetY + currentY * cellSize + yOffset
                )
                .zIndex(50)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func capturedPawnAnimationOverlay(boardOffsetX: CGFloat, boardOffsetY: CGFloat, cellSize: CGFloat) -> some View {
        ForEach(capturedPawns, id: \.pawn.id) { capturedPawn in
            // Check if we have enough data to proceed
            if let startPositionIndex = capturedPawn.pawn.positionIndex {
                let pawn = capturedPawn.pawn
                let progress = capturedPawn.progress

                let animationPath = createCaptureAnimationPath(for: pawn, from: startPositionIndex)

                // Ensure path is valid and has a starting point before trying to animate
                if let startPoint = animationPath.first {
                    
                    // 2. The view is positioned at the starting point of the path.
                    let startX = boardOffsetX + (CGFloat(startPoint.col) + 0.5) * cellSize
                    let startY = boardOffsetY + (CGFloat(startPoint.row) + 0.5) * cellSize
                    
                    PawnView(pawn: pawn, size: cellSize * 0.8)
                        .position(x: startX, y: startY)
                        // 3. The modifier then handles the translation FROM that starting point.
                        .modifier(FollowPathEffect(path: animationPath, progress: progress, cellSize: cellSize))
                        .zIndex(50)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    /// Creates the sequence of board positions for the capture animation path.
    private func createCaptureAnimationPath(for pawn: PawnState, from startIndex: Int) -> [Position] {
        let playerPath = game.path(for: pawn.color)
        let reversedPathToStart = Array(playerPath[0...startIndex]).reversed()
        let homePosCoords = getStartingHomePosition(pawn: pawn, color: pawn.color)
        let homePosition = Position(row: homePosCoords.row, col: homePosCoords.col)
        return reversedPathToStart + [homePosition]
    }

    // Start the particle timer only if needed
    private func startParticleAgingTimerIfNeeded() {
        if particleTimer == nil {
            #if DEBUG
            print("[DEBUG] Particle timer START")
            #endif
            particleTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                // Age all particles
                for i in trailParticles.indices {
                    trailParticles[i].age += 0.05
                    trailParticles[i].opacity = 0.6 * (1.0 - trailParticles[i].age)
                }
                // Remove fully faded particles
                trailParticles.removeAll { $0.age >= 1.0 }
                // Stop timer if no particles remain
                if trailParticles.isEmpty {
                    #if DEBUG
                    print("[DEBUG] Particle timer STOP")
                    #endif
                    particleTimer?.invalidate()
                    particleTimer = nil
                }
            }
        }
    }

    @ViewBuilder
    private func trailParticlesOverlay(boardOffsetX: CGFloat, boardOffsetY: CGFloat, cellSize: CGFloat) -> some View {
        ForEach(trailParticles) { particle in
            TrailParticleView(particle: particle, cellSize: cellSize)
                .position(
                    x: boardOffsetX + (CGFloat(particle.position.col) + 0.5) * cellSize,
                    y: boardOffsetY + (CGFloat(particle.position.row) + 0.5) * cellSize
                )
                .zIndex(40) // Above board, below pawns
                .allowsHitTesting(false)
        }
    }

    // Helper for pawn tap logic from pathPawnView
    private func handlePawnTap(pawn: PawnState, color: PlayerColor) {
        if game.aiControlledPlayers.contains(color) {
            return
        }

        if isPathAnimating || isAnimatingHomeToStart || isAnimatingCapture || isDiceRolling {
            return
        }

        if game.gameMode == .mirchi && game.mirchiArrowActivated[color] == true {
            GameLogger.shared.log("🌶️ [MIRCHI] MIRCHI MODE ON AND arrow activated for \(color.rawValue).", level: .debug)
            if let currentPos = pawn.positionIndex, game.isValidBackwardMove(color: color, pawnId: pawn.id) {
                let steps = game.diceValue
                animatePawnMovementForPath(pawn: pawn, color: color, from: currentPos, steps: steps, backward: true) {
                    game.movePawn(color: color, pawnId: pawn.id, steps: steps, backward: true)
                    isPathAnimating = false
                    isDiceRolling = false
                }
            }
        } else {
            if game.isValidMove(color: color, pawnId: pawn.id) {
                let currentPos = pawn.positionIndex ?? -1
                let steps = game.diceValue
                
                if let destinationIndex = game.getDestinationIndex(color: color, pawnId: pawn.id) {
                    animatePawnMovementForPath(pawn: pawn, color: color, from: currentPos, steps: steps) {
                        game.movePawn(color: color, pawnId: pawn.id, steps: steps)
                        isPathAnimating = false
                        isDiceRolling = false
                    }
                }
            }
        }
    }

    // Helper to find all eligible pawns in a given cell
    private func eligiblePawnsInCell(row: Int, col: Int) -> [PawnState] {
        var pawns: [PawnState] = []
        for (_, pwns) in game.pawns {
            for p in pwns {
                if let posIndex = p.positionIndex, posIndex >= 0 {
                    let pos = getCurrentPosition(pawn: p, color: p.color, positionIndex: posIndex)
                    if pos.row == row && pos.col == col {
                        if p.color == game.currentPlayer && game.eligiblePawns.contains(p.id) {
                            pawns.append(p)
                        }
                    }
                }
            }
        }
        return pawns
    }

    // Helper to determine if a pawn is the expanded pawn in a cell
    private func isExpanded(pawn: PawnState, row: Int, col: Int) -> Bool {
        let eligiblePawnsInCell = eligiblePawnsInCell(row: row, col: col)
        guard let expandedPawn = eligiblePawnsInCell.first else { return false }
        return pawn.id == expandedPawn.id && pawn.color == expandedPawn.color
    }
} 
