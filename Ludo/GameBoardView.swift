import SwiftUI

struct GameBoardView: View {
    @EnvironmentObject var game: LudoGame
    @State private var showPauseMenu: Bool = false
    private let adminToolbarHeight: CGFloat = 56
    private let adminToolbarVerticalOffset: CGFloat = -36
    
    var body: some View {
        ZStack {
            if game.isAdminMode {
                LudoBoardView(maximized: false)
                    // Keep board content (top player panels) below admin toolbar.
                    .padding(.top, adminToolbarHeight + 20)
                    .overlay(alignment: .topLeading) {
                        AdminControlsView(
                            eligiblePawns: game.eligiblePawns,
                            selectedPlayers: game.selectedPlayers,
                            currentScores: game.scores,
                            onTestRoll: { value in
                                game.testRollDice(value: value)
                            },
                            onEndGame: { finalScores in
                                game.adminEndGame(finalScores: finalScores)
                            },
                            onSetCoins: { amount in
                                game.adminSetCoins(amount)
                            },
                            onResetUnlocks: {
                                game.adminResetUnlocks()
                            },
                            onResetToFirstRun: {
                                game.adminResetToFirstRun()
                            }
                        )
                        .frame(height: adminToolbarHeight)
                        .padding(.top, 4)
                        .padding(.leading, 8)
                        .offset(y: adminToolbarVerticalOffset)
                    }
            } else {
                LudoBoardView(maximized: true)
            }

            // Pause button at top right
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        game.pauseGame()
                        showPauseMenu = true
                    }) {
                        Image(systemName: "pause.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.primary)
                            .shadow(radius: 3)
                    }
                    .offset(y: -12)
                    .padding()
                }
                Spacer()
            }

            // Dimmed background and dialog
            if showPauseMenu {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        showPauseMenu = false
                        game.resumeGame()
                    }

                PauseDialogView(
                    onResume: {
                        showPauseMenu = false
                        game.resumeGame()
                    },
                    onRestart: {
                        showPauseMenu = false
                        game.resumeGame()
                        game.startGame(selectedPlayers: game.selectedPlayers, aiPlayers: game.aiControlledPlayers, mode: game.gameMode)
                    },
                    onExit: {
                        showPauseMenu = false
                        game.resumeGame()
                        game.gameStarted = false
                    }
                )
                .frame(width: 360)
            }

            if game.showMirchiModeIph {
                InProductHelpBubbleView(
                    icon: .mirchiMode,
                    title: GameCopy.StartGame.mirchiModeIphTitle,
                    message: GameCopy.StartGame.mirchiModeIphMessage,
                    onClose: {
                        game.dismissMirchiModeIph()
                    }
                )
                .zIndex(10)
            } else if let boostIph = game.pawnBoostIphPayload {
                InProductHelpBubbleView(
                    icon: .image(boostIph.boostIconAssetName),
                    title: boostIph.title,
                    message: boostIph.message,
                    iconBadgeValue: boostIph.badgeValue,
                    onClose: {
                        game.dismissPawnBoostIph()
                    }
                )
                .zIndex(10)
            } else if let avatarName = game.boostUnavailableIphAvatarName {
                InProductHelpBubbleView(
                    icon: .image(avatarName),
                    title: GameCopy.BoostUnavailableIph.title,
                    message: GameCopy.BoostUnavailableIph.message,
                    onClose: {
                        game.dismissBoostUnavailableIph()
                    }
                )
                .zIndex(10)
            }
        }
    }
} 
 