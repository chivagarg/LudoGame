import SwiftUI

struct PlayerPanelView: View {
    @EnvironmentObject var game: LudoGame
    let color: PlayerColor
    let showDice: Bool
    let diceValue: Int
    let isDiceRolling: Bool
    let onDiceTap: () -> Void
    @State private var localDiceRolling: Bool = false

    private func canUseBoost(for color: PlayerColor) -> Bool {
        // Must be on your turn (boost can be armed anytime on your turn).
        return game.currentPlayer == color
            && !game.aiControlledPlayers.contains(color)
            && !game.isBusy
    }

    @ViewBuilder
    private func boostButton(for color: PlayerColor) -> some View {
        if let ability = game.boostAbility(for: color) {
            let state = game.getBoostState(for: color)
            let isUsed = state == .used
            let isActive = state == .armed
            let isEnabled = !isUsed && canUseBoost(for: color)
            let boostsRemaining = game.boostUsesRemaining[color] ?? PawnAssets.boostUses(for: game.selectedAvatar(for: color))

            VStack(spacing: 4) {
                Button(action: {
                    guard isEnabled else { return }
                    game.tapBoost(color: color)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)

                        if ability.kind == .rerollToSix {
                            // Custom Mango Boost Visuals: Big Gold Dice (Face 6)
                            Image(systemName: "die.face.6.fill")
                                .font(.system(size: 34)) // Adjusted size to fit container
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 0.8, green: 0.6, blue: 0.0)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: .orange.opacity(0.4), radius: 1, x: 1, y: 1)
                                .saturation(isUsed ? 0.0 : 1.0)
                                .opacity(isUsed ? 0.6 : 1.0)
                        } else if ability.kind == .extraBackwardMove {
                            // Custom Mirchi Boost Visuals: +1 with small mirchi inside
                            HStack(spacing: 2) {
                                Text("+1")
                                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                                    .foregroundColor(.red)
                                
                                Image(PawnAssets.mirchiIndicator)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 18, height: 18)
                            }
                            .saturation(isUsed ? 0.0 : 1.0)
                            .opacity(isUsed ? 0.6 : 1.0)
                        } else {
                            // Standard visuals for other boosts (Shield, Trap, Mirchi)
                            Image(systemName: ability.iconSystemName)
                                .font(.system(size: 26, weight: .heavy))
                                .foregroundColor(isUsed ? .gray : (isActive ? Color.purple : Color.purple.opacity(0.7)))
                        }
                    }
                    .frame(width: 56, height: 56)
                    .opacity(isUsed ? 0.35 : (isEnabled ? 1.0 : 0.6))
                    .scaleEffect(isActive ? 1.12 : 1.0)
                    .overlay(
                        Circle()
                            .stroke(isActive ? Color.purple.opacity(0.8) : Color.clear, lineWidth: 3)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!isEnabled)

                Text("\(max(0, boostsRemaining))")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(minWidth: 60)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white))
            }
        } else {
            EmptyView()
        }
    }

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
                                    Image(PawnAssets.mirchiIndicator)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: iconSize, height: iconSize)
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

                            // Boost (only for special pawns like mirchi/mango)
                            boostButton(for: color)
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
                            let avatarName = game.selectedAvatar(for: color)
                            AvatarIcon(avatarName: avatarName, playerColor: color.primaryColor)
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
                            let avatarName = game.selectedAvatar(for: color)
                            AvatarIcon(avatarName: avatarName, playerColor: color.primaryColor)
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
                                    Image(PawnAssets.mirchiIndicator)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: iconSize, height: iconSize)
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

                            // Boost (only for special pawns like mirchi/mango)
                            boostButton(for: color)
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
