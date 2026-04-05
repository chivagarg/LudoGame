import SwiftUI

struct GameBoardView: View {
    @EnvironmentObject var game: LudoGame
    @State private var showPauseMenu: Bool = false
    /// Space reserved under the safe area for the admin strip (two rows: dice + scores).
    private let adminToolbarReservedHeight: CGFloat = 124
    
    var body: some View {
        ZStack {
            if game.isAdminMode {
                LudoBoardView(maximized: false)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    // Keep board content (top player panels) below admin toolbar.
                    .padding(.top, adminToolbarReservedHeight + 12)
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
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, 8)
                        .padding(.top, 10)
                    }
            } else {
                LudoBoardView(maximized: true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .overlay(alignment: .topTrailing) {
            if !showPauseMenu {
                Button {
                    game.pauseGame()
                    showPauseMenu = true
                } label: {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(.plain)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .padding(.top, 6)
                .padding(.trailing, 8)
                .accessibilityLabel("Pause")
            }
        }
    }
} 
 