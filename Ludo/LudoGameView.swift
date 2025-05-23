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
            
            if !game.eligiblePawns.isEmpty {
                Text("Make your move \(game.currentPlayer.rawValue.capitalized)!")
                    .font(.title2)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Button("Roll Dice") {
                game.rollDice()
            }
            .font(.title2)
            .padding()
            .background(game.eligiblePawns.isEmpty ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(!game.eligiblePawns.isEmpty)
            
            // Ludo Board
            LudoBoardView()
        }
    }
}

struct LudoBoardView: View {
    let gridSize = 15
    @EnvironmentObject var game: LudoGame
    
    var body: some View {
        GeometryReader { geometry in
            let boardSize = min(geometry.size.width, geometry.size.height) * 0.75
            let cellSize = boardSize / CGFloat(gridSize)
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
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .padding()
        .aspectRatio(1, contentMode: .fit)
    }
    
    @ViewBuilder
    func cellView(row: Int, col: Int, cellSize: CGFloat) -> some View {
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
            
            // Draw pawns
            ForEach(PlayerColor.allCases, id: \.self) { color in
                ForEach(game.pawns[color] ?? [], id: \.id) { pawn in
                    if let positionIndex = pawn.positionIndex {
                        if positionIndex >= 0 { // On the path
                            let position = game.path(for: color)[positionIndex]
                            if position.row == row && position.col == col {
                                PawnView(color: color, size: cellSize * 0.8)
                                    .onTapGesture {
                                        if color == game.currentPlayer {
                                            game.movePawn(color: color, pawnId: pawn.id, steps: game.diceValue)
                                        }
                                    }
                            }
                        }
                    } else { // At home
                        // Position pawns in their home area
                        switch color {
                        case .red:
                            if (row == 1 || row == 4) && (col == 1 || col == 4) {
                                PawnView(color: color, size: cellSize * 0.8)
                                    .onTapGesture {
                                        if color == game.currentPlayer && game.diceValue == 6 {
                                            game.movePawn(color: color, pawnId: pawn.id, steps: game.diceValue)
                                        }
                                    }
                            }
                        case .green:
                            if (row == 1 || row == 4) && (col == 10 || col == 13) {
                                PawnView(color: color, size: cellSize * 0.8)
                                    .onTapGesture {
                                        if color == game.currentPlayer && game.diceValue == 6 {
                                            game.movePawn(color: color, pawnId: pawn.id, steps: game.diceValue)
                                        }
                                    }
                            }
                        case .yellow:
                            if (row == 10 || row == 13) && (col == 10 || col == 13) {
                                PawnView(color: color, size: cellSize * 0.8)
                                    .onTapGesture {
                                        if color == game.currentPlayer && game.diceValue == 6 {
                                            game.movePawn(color: color, pawnId: pawn.id, steps: game.diceValue)
                                        }
                                    }
                            }
                        case .blue:
                            if (row == 10 || row == 13) && (col == 1 || col == 4) {
                                PawnView(color: color, size: cellSize * 0.8)
                                    .onTapGesture {
                                        if color == game.currentPlayer && game.diceValue == 6 {
                                            game.movePawn(color: color, pawnId: pawn.id, steps: game.diceValue)
                                        }
                                    }
                            }
                        }
                    }
                }
            }
        }
        .frame(width: cellSize, height: cellSize)
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
