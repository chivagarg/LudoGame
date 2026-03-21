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
    @State private var aiPlayers: Set<PlayerColor> = []
    @State private var selectedMode: GameMode = .classic
    
    /// Tighter insets while playing so the board uses more of the screen; start/over screens keep comfortable margins.
    private var isPlayingGame: Bool {
        game.gameStarted && !game.isGameOver
    }
    
    private var horizontalPadding: CGFloat { isPlayingGame ? 10 : 16 }
    private var verticalPadding: CGFloat { isPlayingGame ? 8 : 16 }
    
    var body: some View {
        VStack {
            if !game.gameStarted {
                StartGameView(
                    isAdminMode: $game.isAdminMode,
                    selectedPlayers: $selectedPlayers,
                    aiPlayers: $aiPlayers,
                    selectedMode: $selectedMode,
                    onStartGame: {
                        game.startGame(selectedPlayers: selectedPlayers, aiPlayers: aiPlayers, mode: selectedMode)
                    }
                )
            } else if game.isGameOver {
                GameOverView(selectedPlayers: $selectedPlayers, onExitGame: {
                    game.resetGame()
                })
            } else {
                GameBoardView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(Color(.systemBackground)) // Ensure consistent background in both Light & Dark modes
        .environmentObject(game)
    }
}

#Preview {
    LudoGameView()
} 
