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

                HStack(spacing: 6) {
                    // 1. Avatar with Score Pill
                    ZStack(alignment: .bottomTrailing) {
                        // Avatar
                        ZStack {
                            Image("pawn_\(color.rawValue)_marble_filled")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                        }
                        .frame(width: 100, height: 80)
                        
                        // Score Pill
                        Text("\(game.scores[color] ?? 0)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(color.toSwiftUIColor(for: color))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.white))
                            .offset(x: 8, y: 8)
                    }
                    .frame(width: 100, height: 100)
                    .offset(x: -20, y: -5)

                    // 2. Kill counts: skull icon with score underneath
                    VStack(spacing: 4) {
                        Image("skull_cute")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 48, height: 48)
                        Text("\(game.killCounts[color] ?? 0)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.white))
                    }
                    .offset(x: -16)

                    // 3. Mirchi Arrow (only in Mirchi mode)
                    if game.gameMode == .mirchi {
                        let isMirchiActive = game.mirchiArrowActivated[color] == true
                        let hasMirchiMoves = game.mirchiMovesRemaining[color, default: 0] > 0

                        VStack(spacing: 4) {
                            Button(action: {
                                if hasMirchiMoves {
                                    game.mirchiArrowActivated[color]?.toggle()
                                    // Provide haptic feedback for interaction
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                }
                            }) {
                                Image("mirchi")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 56, height: 56)
                                    .saturation(isMirchiActive ? 1.0 : 0.4) // Full color when active, less when not
                                    .opacity(isMirchiActive ? 1.0 : 0.7)   // Fully opaque when active
                                    .grayscale(hasMirchiMoves ? 0 : 1)       // Grayscale when no moves left
                                    .shadow(color: .black.opacity(isMirchiActive ? 0.4 : 0.2), radius: isMirchiActive ? 5 : 2, x: 1, y: 1)
                                    .scaleEffect(isMirchiActive ? 1.2 : 1.0) // Pop effect when active
                                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isMirchiActive)
                            }
                            .buttonStyle(PlainButtonStyle()) // Use PlainButtonStyle to avoid default button styling

                            Text("\(game.mirchiMovesRemaining[color, default: 0])")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.black)
                        }
                        .offset(x: -10)
                    }

                    // 4. Dice (only for current player, uses opacity to maintain layout)
                    let canRoll = showDice && !isDiceRolling && !localDiceRolling && game.eligiblePawns.isEmpty && game.currentRollPlayer == nil && !game.isBusy && !game.aiControlledPlayers.contains(color)
#if DEBUG
                    let _ = { print("[DEBUG] canRoll for \(color.rawValue):", canRoll) }()
#endif
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
                }
                .padding(.horizontal, 8)
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
 
