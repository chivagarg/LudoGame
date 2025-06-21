import SwiftUI
import AVFoundation

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
    
    private let pawnResizeFactor: CGFloat = 0.9
    private var boardScaleFactor: CGFloat { maximized ? 0.95 : 0.85 }
    
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
                self.pathAnimatingPawns.removeAll()
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
                    isPathAnimating = false
                    return
                }
            } else {
                if currentTo >= game.path(for: color).count {
                    isPathAnimating = false
                    return
                }
            }
            
            pathAnimatingPawns[key] = (start: currentFrom, end: currentTo, progress: 0)
            
            // Play hop sound for each step
            SoundManager.shared.playPawnHopSound()
            
            withAnimation(.spring(response: 0.15, dampingFraction: 0.3, blendDuration: 0)) {
                pathAnimatingPawns[key]?.progress = 1.0
            }
            
            currentStep += 1
            
            // Schedule next step with shorter delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
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
            Self.renderCount += 1
            // print("LudoBoardView rendered \(Self.renderCount) times")
        }()

        return GeometryReader { geometry in
            let (boardSize, cellSize, boardOffsetX, boardOffsetY) = calculateBoardDimensions(geometry: geometry)
            let panelWidth: CGFloat = 220
            let panelHeight: CGFloat = 100
            let overlap: CGFloat = 20
            let horizontalInset: CGFloat = (maximized ? 190 : 170) + (game.gameMode == .mirchi ? 20 : 0)

            ZStack {
                // Board
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

                // Panels in corners, floating off the board
                PlayerPanelView(
                    color: .red,
                    showDice: game.currentPlayer == .red,
                    diceValue: game.diceValue,
                    isDiceRolling: isDiceRolling,
                    onDiceTap: {
                        if !isDiceRolling && game.eligiblePawns.isEmpty {
                            isDiceRolling = true
                            game.rollDice()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isDiceRolling = false
                            }
                        }
                    }
                )
                .environmentObject(game)
                .frame(width: panelWidth, height: panelHeight)
                .position(x: boardOffsetX - panelWidth/2 + horizontalInset, y: boardOffsetY - panelHeight/2 + overlap)
                PlayerPanelView(
                    color: .green,
                    showDice: game.currentPlayer == .green,
                    diceValue: game.diceValue,
                    isDiceRolling: isDiceRolling,
                    onDiceTap: {
                        if !isDiceRolling && game.eligiblePawns.isEmpty {
                            isDiceRolling = true
                            game.rollDice()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isDiceRolling = false
                            }
                        }
                    }
                )
                .environmentObject(game)
                .frame(width: panelWidth, height: panelHeight)
                .position(x: boardOffsetX + boardSize + panelWidth/2 - horizontalInset, y: boardOffsetY - panelHeight/2 + overlap)
                PlayerPanelView(
                    color: .blue,
                    showDice: game.currentPlayer == .blue,
                    diceValue: game.diceValue,
                    isDiceRolling: isDiceRolling,
                    onDiceTap: {
                        if !isDiceRolling && game.eligiblePawns.isEmpty {
                            isDiceRolling = true
                            game.rollDice()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isDiceRolling = false
                            }
                        }
                    }
                )
                .environmentObject(game)
                .frame(width: panelWidth, height: panelHeight)
                .position(x: boardOffsetX - panelWidth/2 + horizontalInset, y: boardOffsetY + boardSize + panelHeight/2 - overlap)
                PlayerPanelView(
                    color: .yellow,
                    showDice: game.currentPlayer == .yellow,
                    diceValue: game.diceValue,
                    isDiceRolling: isDiceRolling,
                    onDiceTap: {
                        if !isDiceRolling && game.eligiblePawns.isEmpty {
                            isDiceRolling = true
                            game.rollDice()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isDiceRolling = false
                            }
                        }
                    }
                )
                .environmentObject(game)
                .frame(width: panelWidth, height: panelHeight)
                .position(x: boardOffsetX + boardSize + panelWidth/2 - horizontalInset, y: boardOffsetY + boardSize + panelHeight/2 - overlap)

                // Pawns animating from their Home base to their starting path position
                ForEach(homeToStartPawns, id: \.pawn.id) { homeToStartPawn in
                    let pawn = homeToStartPawn.pawn
                    let progress = homeToStartPawn.progress
                    
                    // Get start (home) and end (path start) positions
                    let homePosition = getStartingHomePosition(pawn: pawn, color: pawn.color)
                    let pathStartPosition = game.path(for: pawn.color)[0]

                    // Interpolate the position based on progress
                    let startX = CGFloat(homePosition.col) + 0.5
                    let startY = CGFloat(homePosition.row) + 0.5
                    let endX = CGFloat(pathStartPosition.col) + 0.5
                    let endY = CGFloat(pathStartPosition.row) + 0.5
                    
                    let currentX = startX + (endX - startX) * progress
                    let currentY = startY + (endY - startY) * progress
                    
                    // Add a hop effect using a sine wave
                    let hopHeight = -cellSize * 1.5 // Hop 1.5 cells high
                    let yOffset = sin(progress * .pi) * hopHeight
                    
                    PawnView(pawn: pawn, size: cellSize * 0.8, currentPlayer: game.currentPlayer)
                        .position(
                            x: boardOffsetX + currentX * cellSize,
                            y: boardOffsetY + currentY * cellSize + yOffset
                        )
                        .zIndex(50) // Render above the board but below dice
                        .allowsHitTesting(false) // Don't let it intercept taps while animating
                }

                // Pawns animating from their path position to their Home base (on capture)
                ForEach(capturedPawns, id: \.pawn.id) { capturedPawn in
                    if let startPositionIndex = capturedPawn.pawn.positionIndex {
                        let pawn = capturedPawn.pawn
                        let progress = capturedPawn.progress
                        
                        // Get start (path) and end (home) positions
                        let pathPosition = game.path(for: pawn.color)[startPositionIndex]
                        let homePosition = getStartingHomePosition(pawn: pawn, color: pawn.color)

                        // Interpolate the position based on progress
                        let startX = CGFloat(pathPosition.col) + 0.5
                        let startY = CGFloat(pathPosition.row) + 0.5
                        let endX = CGFloat(homePosition.col) + 0.5
                        let endY = CGFloat(homePosition.row) + 0.5
                        
                        let currentX = startX + (endX - startX) * progress
                        let currentY = startY + (endY - startY) * progress
                        
                        // Add a hop effect using a sine wave
                        let hopHeight = -cellSize * 1.5 // Hop 1.5 cells high
                        let yOffset = sin(progress * .pi) * hopHeight
                        
                        PawnView(pawn: pawn, size: cellSize * 0.8, currentPlayer: game.currentPlayer)
                            .position(
                                x: boardOffsetX + currentX * cellSize,
                                y: boardOffsetY + currentY * cellSize + yOffset
                            )
                            .zIndex(50)
                            .allowsHitTesting(false)
                    }
                }
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
                        animatePawnMovementForPath(pawn: pawn, color: color, from: from, steps: steps) {
                            self.pathAnimatingPawns.removeAll()
                            game.movePawn(color: color, pawnId: pawnId, steps: steps)
                            isPathAnimating = false
                            isDiceRolling = false
                        }
                    }
                }
                // Sync initial pawn count
                previousPawnsAtHome = game.totalPawnsAtFinishingHome
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
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0)) {
                    if let index = homeToStartPawns.firstIndex(where: { $0.pawn.id == pawn.id && $0.pawn.color == color }) {
                        homeToStartPawns[index].progress = 1.0
                    }
                }
                
                // After the animation duration, complete the move in the model
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Match the spring response time
                    homeToStartPawns.removeAll { $0.pawn.id == pawn.id && $0.pawn.color == color }
                    game.completeMoveFromHome(color: color, pawnId: pawnId)
                    isAnimatingHomeToStart = false // <-- Unlock the UI
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .animatePawnCapture)) { notification in
                guard let userInfo = notification.userInfo,
                      let color = userInfo["color"] as? PlayerColor,
                      let pawnId = userInfo["pawnId"] as? Int,
                      let pawn = game.pawns[color]?.first(where: { $0.id == pawnId }) else { return }
                
                isAnimatingCapture = true // <-- Lock for capture
                
                capturedPawns.append((pawn: pawn, progress: 0))
                
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5, blendDuration: 0)) {
                    if let index = capturedPawns.firstIndex(where: { $0.pawn.id == pawnId && $0.pawn.color == color }) {
                        capturedPawns[index].progress = 1.0
                    }
                }
                
                // After the animation duration, complete the move in the model
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    if color == .red && pawnId == 0 {
                        GameLogger.shared.log("🐞 DEBUG LOG 1: Completing capture for Red Pawn 0. Its positionIndex is currently: \(String(describing: pawn.positionIndex))", level: .debug)
                    }
                    game.completePawnCapture(color: color, pawnId: pawnId)
                    capturedPawns.removeAll { $0.pawn.id == pawnId && $0.pawn.color == color }
                    isAnimatingCapture = false // <-- Unlock for capture
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
        if row == 7 && col == 7 {
            renderCenterCell(row: row, col: col, cellSize: cellSize)
        } else if (6...8).contains(row) && (6...8).contains(col) {
            EmptyView()
        } else {
            ZStack {
                if row < 6 && col < 6 {
                    if (row == 1 || row == 4) && (col == 1 || col == 4) {
                        Rectangle().fill(Color.white)
                        Rectangle().fill(Color.red.opacity(0.3))
                    } else {
                        Rectangle().fill(Color.red.opacity(0.7))
                    }
                // Green Home Area
                } else if row < 6 && col > 8 {
                    if (row == 1 || row == 4) && (col == 10 || col == 13) {
                        Rectangle().fill(Color.white)
                        Rectangle().fill(Color.green.opacity(0.3))
                    } else {
                        Rectangle().fill(Color.green.opacity(0.7))
                    }
                // Blue Home Area
                } else if row > 8 && col < 6 {
                    if (row == 10 || row == 13) && (col == 1 || col == 4) {
                        Rectangle().fill(Color.white)
                        Rectangle().fill(Color.blue.opacity(0.3))
                    } else {
                        Rectangle().fill(Color.blue.opacity(0.7))
                    }
                // Yellow Home Area
                } else if row > 8 && col > 8 {
                    if (row == 10 || row == 13) && (col == 10 || col == 13) {
                        Rectangle().fill(Color.white)
                        Rectangle().fill(Color.yellow.opacity(0.3))
                    } else {
                        Rectangle().fill(Color.yellow.opacity(0.7))
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
                } else {
                    // Path cells
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
            .fill(Color.red.opacity(0.7))
            
            // Yellow triangle
            Path { path in
                path.move(to: CGPoint(x: largeCellSize, y: 0)) 
                path.addLine(to: CGPoint(x: largeCellSize/2, y: largeCellSize/2)) 
                path.addLine(to: CGPoint(x: largeCellSize, y: largeCellSize)) 
                path.closeSubpath()
            }
            .fill(Color.yellow.opacity(0.7))

            // Green triangle
            Path { path in
                path.move(to: CGPoint(x: largeCellSize, y: 0)) 
                path.addLine(to: CGPoint(x: largeCellSize/2, y: largeCellSize/2)) 
                path.addLine(to: CGPoint(x: 0, y: 0)) 
                path.closeSubpath()
            }
            .fill(Color.green.opacity(0.7))

            // Blue triangle
            Path { path in
                path.move(to: CGPoint(x: 0, y: largeCellSize)) 
                path.addLine(to: CGPoint(x: largeCellSize/2, y: largeCellSize/2)) 
                path.addLine(to: CGPoint(x: largeCellSize, y: largeCellSize)) 
                path.closeSubpath()
            }
            .fill(Color.blue.opacity(0.7))
            
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
                        if !game.aiControlledPlayers.contains(color) && !isPathAnimating && !isAnimatingHomeToStart && !isAnimatingCapture && !isDiceRolling {
                            // Path 1: Mirchi Mode with activated arrow
                            if game.gameMode == .mirchi && game.mirchiArrowActivated[color] == true {
                                GameLogger.shared.log("🌶️ [MIRCHI] MIRCHI MODE ON AND arrow activated for \(color.rawValue).", level: .debug)
                                // In this path, we ONLY attempt a backward move. If not possible, we do nothing.
                                if let currentPos = pawn.positionIndex, currentPos - game.diceValue >= 0 {
                                    let steps = game.diceValue
                                    animatePawnMovementForPath(pawn: pawn, color: color, from: currentPos, steps: steps, backward: true) {
                                        self.pathAnimatingPawns.removeAll()
                                        game.movePawnBackward(color: color, pawnId: pawn.id, steps: steps)
                                        isPathAnimating = false
                                        isDiceRolling = false
                                    }
                                }
                            } else {
                                // CLASSIC MODE: Forward Movement Logic (unchanged)
                                if game.isValidMove(color: color, pawnId: pawn.id) {
                                    let currentPos = pawn.positionIndex ?? -1
                                    let steps = game.diceValue
                                    
                                    if let destinationIndex = game.getDestinationIndex(color: color, pawnId: pawn.id) {
                                        animatePawnMovementForPath(pawn: pawn, color: color, from: currentPos, steps: steps) {
                                            self.pathAnimatingPawns.removeAll()
                                            game.movePawn(color: color, pawnId: pawn.id, steps: steps)
                                            isPathAnimating = false
                                            isDiceRolling = false
                                        }
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
            PawnView(pawn: pawn, size: cellSize * pawnResizeFactor, currentPlayer: game.currentPlayer)
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
} 
