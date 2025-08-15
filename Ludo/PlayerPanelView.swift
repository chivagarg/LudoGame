import SwiftUI

struct PlayerPanelView: View {
    @EnvironmentObject var game: LudoGame
    let color: PlayerColor
    let showDice: Bool
    let diceValue: Int
    let isDiceRolling: Bool
    let onDiceTap: () -> Void
    @State private var localDiceRolling: Bool = false

    var body: some View {
        ZStack {
            if game.selectedPlayers.contains(color) {
                // White background rectangle
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)

                // Colored overlay rectangle
                RoundedRectangle(cornerRadius: 20)
                    .fill(color.toSwiftUIColor(for: color).opacity(0.5))

                // CONSTANTS
                let iconSize: CGFloat = 56

                HStack(spacing: 16) {
                    let canRoll = showDice && !isDiceRolling && !localDiceRolling && game.eligiblePawns.isEmpty && game.currentRollPlayer == nil && !game.isBusy && !game.aiControlledPlayers.contains(color)
                    if color == .red || color == .green {
                        // 1. Dice
                        DiceView(
                            value: diceValue,
                            isRolling: isDiceRolling || localDiceRolling,
                            shouldPulse: canRoll,
                            onTap: {
                                // Disable tap for AI players
                                if !game.aiControlledPlayers.contains(color) {
                                    onDiceTap()
                                }
                            }
                        )
                        .id(canRoll)
                        .opacity(showDice ? 1.0 : 0.0)
                        .allowsHitTesting(showDice)
                        .frame(width: 72, height: 72)

                        // 2. Mirchi (only in Mirchi mode)
                        if game.gameMode == .mirchi {
                            let isMirchiActive = game.mirchiArrowActivated[color] == true
                            let hasMirchiMoves = game.mirchiMovesRemaining[color, default: 0] > 0

                            VStack(spacing: 4) {
                                Button(action: {
                                    if hasMirchiMoves {
                                        game.mirchiArrowActivated[color]?.toggle()
                                        // Haptic
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    }
                                }) {
                                    Image("mirchi")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: iconSize, height: iconSize)
                                        .scaleEffect(1.25)
                                        .saturation(isMirchiActive ? 1.0 : 0.4)
                                        .opacity(isMirchiActive ? 1.0 : 0.7)
                                        .grayscale(hasMirchiMoves ? 0 : 1)
                                        .shadow(color: .black.opacity(isMirchiActive ? 0.4 : 0.2), radius: isMirchiActive ? 5 : 2, x: 1, y: 1)
                                        .scaleEffect(isMirchiActive ? 1.15 : 1.0)
                                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isMirchiActive)
                                }
                                .buttonStyle(PlainButtonStyle())

                                Text("\(game.mirchiMovesRemaining[color, default: 0])/5")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.black)
                                    .frame(minWidth: 60)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(Color.white))
                            }
                        }

                        // 3. Skull & kills
                        VStack(spacing: 4) {
                            Image("skull_cute")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: iconSize, height: iconSize)

                            Text("\(game.killCounts[color] ?? 0)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.black)
                                .frame(minWidth: 60)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.white))
                        }

                        // 4. Pawn & score
                        VStack(spacing: 4) {
                            Image(game.selectedAvatar(for: color))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: iconSize, height: iconSize)

                            Text("\(game.scores[color] ?? 0)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(color.toSwiftUIColor(for: color))
                                .frame(minWidth: 60)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.white))
                        }
                    } else {
                        // 1. Pawn & score
                        VStack(spacing: 4) {
                            Image(game.selectedAvatar(for: color))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: iconSize, height: iconSize)

                            Text("\(game.scores[color] ?? 0)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(color.toSwiftUIColor(for: color))
                                .frame(minWidth: 60)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.white))
                        }

                        // 2. Skull & kills
                        VStack(spacing: 4) {
                            Image("skull_cute")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: iconSize, height: iconSize)

                            Text("\(game.killCounts[color] ?? 0)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.black)
                                .frame(minWidth: 60)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.white))
                        }

                        // 3. Mirchi (only in Mirchi mode)
                        if game.gameMode == .mirchi {
                            let isMirchiActive = game.mirchiArrowActivated[color] == true
                            let hasMirchiMoves = game.mirchiMovesRemaining[color, default: 0] > 0

                            VStack(spacing: 4) {
                                Button(action: {
                                    if hasMirchiMoves {
                                        game.mirchiArrowActivated[color]?.toggle()
                                        // Haptic
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    }
                                }) {
                                    Image("mirchi")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: iconSize, height: iconSize)
                                        .scaleEffect(1.25)
                                        .saturation(isMirchiActive ? 1.0 : 0.4)
                                        .opacity(isMirchiActive ? 1.0 : 0.7)
                                        .grayscale(hasMirchiMoves ? 0 : 1)
                                        .shadow(color: .black.opacity(isMirchiActive ? 0.4 : 0.2), radius: isMirchiActive ? 5 : 2, x: 1, y: 1)
                                        .scaleEffect(isMirchiActive ? 1.15 : 1.0)
                                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isMirchiActive)
                                }
                                .buttonStyle(PlainButtonStyle())

                                Text("\(game.mirchiMovesRemaining[color, default: 0])/5")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.black)
                                    .frame(minWidth: 60)
                                    .padding(.vertical, 6)
                                    .background(Capsule().fill(Color.white))
                            }
                        }

                        // 4. Dice
                        DiceView(
                            value: diceValue,
                            isRolling: isDiceRolling || localDiceRolling,
                            shouldPulse: canRoll,
                            onTap: {
                                // Disable tap for AI players
                                if !game.aiControlledPlayers.contains(color) {
                                    onDiceTap()
                                }
                            }
                        )
                        .id(canRoll)
                        .opacity(showDice ? 1.0 : 0.0)
                        .allowsHitTesting(showDice)
                        .frame(width: 72, height: 72)
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .frame(height: 100)
        // Base border for selected players
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(game.selectedPlayers.contains(color) ? color.toSwiftUIColor(for: color) : Color.clear, lineWidth: 2)
        )
        // Additional halo to highlight current player
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(game.currentPlayer == color ? color.toSwiftUIColor(for: color) : Color.clear, lineWidth: 4)
                .shadow(color: color.toSwiftUIColor(for: color).opacity(game.currentPlayer == color ? 0.7 : 0), radius: 6)
        )
        .shadow(color: .black.opacity(game.selectedPlayers.contains(color) ? 0.3 : 0), radius: 5, x: 0, y: 5)
        .onChange(of: game.rollID) { _ in
            if showDice && !isDiceRolling && !localDiceRolling {
                localDiceRolling = true
                DispatchQueue.main.asyncAfter(deadline: .now() + GameConstants.diceAnimationDuration) {
                    localDiceRolling = false
                }
            }
        }
    }
} 
 
