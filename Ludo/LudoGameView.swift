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

#Preview {
    LudoGameView()
} 
