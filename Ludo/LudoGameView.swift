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
                StartGameView(
                    isAdminMode: $game.isAdminMode,
                    selectedPlayers: $selectedPlayers,
                    onStartGame: {
                        game.startGame(selectedPlayers: selectedPlayers)
                    }
                )
            } else if game.isGameOver {
                GameOverView(selectedPlayers: $selectedPlayers)
            } else {
                gameBoardView
            }
        }
        .padding()
        .environmentObject(game)
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

#Preview {
    LudoGameView()
} 
