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
                GameOverView(selectedPlayers: $selectedPlayers)
            } else {
                GameBoardView()
            }
        }
        .padding()
        .environmentObject(game)
    }
}

#Preview {
    LudoGameView()
} 
