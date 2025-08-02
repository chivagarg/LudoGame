import SwiftUI

struct GameBoardView: View {
    @EnvironmentObject var game: LudoGame
    @State private var showPauseMenu: Bool = false
    
    var body: some View {
        ZStack {
            if game.isAdminMode {
                VStack(spacing: 16) {
                    AdminControlsView(
                        currentPlayer: game.currentPlayer,
                        eligiblePawns: game.eligiblePawns,
                        onTestRoll: { value in
                            game.testRollDice(value: value)
                        }
                    )
                    LudoBoardView(maximized: false)
                }
            } else {
                LudoBoardView(maximized: true)
            }

            // Pause button at top right
            VStack {
                HStack {
                    Spacer()
                    Button(action: { showPauseMenu = true }) {
                        Image(systemName: "pause.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.primary) // Adaptive color
                            .shadow(radius: 3)
                    }
                    .offset(y: -12) // Move slightly higher to avoid accidental taps
                    .padding()
                }
                Spacer()
            }

            // Dimmed background and dialog
            if showPauseMenu {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture { showPauseMenu = false }

                PauseDialogView(
                    onResume: {
                        showPauseMenu = false
                    },
                    onRestart: {
                        showPauseMenu = false
                        game.startGame(selectedPlayers: game.selectedPlayers, aiPlayers: game.aiControlledPlayers, mode: game.gameMode)
                    },
                    onExit: {
                        showPauseMenu = false
                        game.gameStarted = false
                    }
                )
                .frame(width: 220)
            }
        }
    }
} 
 