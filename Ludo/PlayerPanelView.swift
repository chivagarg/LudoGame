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
                            Image("pawn_\(color.rawValue)_marble")
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
                        Image("skull")
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
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.title)
                                .foregroundColor(game.mirchiMovesRemaining[color, default: 0] == 0 ? .gray : (game.mirchiArrowActivated[color] == true ? color.toSwiftUIColor(for: color) : .white))
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                                .onTapGesture {
                                    // Only allow toggling if moves remain
                                    if game.mirchiMovesRemaining[color, default: 0] > 0 {
                                        game.mirchiArrowActivated[color]?.toggle()
                                    }
                                }
                            // Placeholder count – will be wired to game logic in part 2
                            Text("\(game.mirchiMovesRemaining[color, default: 0])")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.black)
                        }
                        .offset(x: -10)
                    }

                    // 4. Dice (only for current player, uses opacity to maintain layout)
                    DiceView(
                        value: diceValue,
                        isRolling: isDiceRolling || localDiceRolling,
                        onTap: {
                            // Disable tap for AI players
                            if !game.aiControlledPlayers.contains(color) {
                                onDiceTap()
                            }
                        }
                    )
                    .opacity(showDice ? 1.0 : 0.0)
                    .allowsHitTesting(showDice)
                }
                .padding(.horizontal, 8)
            }
        }
        .frame(height: 100)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(game.selectedPlayers.contains(color) ? color.toSwiftUIColor(for: color) : Color.clear, lineWidth: 2)
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
 