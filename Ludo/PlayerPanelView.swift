import SwiftUI

struct PlayerPanelView: View {
    @EnvironmentObject var game: LudoGame
    let color: PlayerColor
    let showDice: Bool
    let diceValue: Int
    let isDiceRolling: Bool
    let onDiceTap: () -> Void
    @State private var localDiceRolling: Bool = false
    
    private let diceAnimationDuration: TimeInterval = 0.8

    var body: some View {
        let panelWidth: CGFloat = game.gameMode == .mirchi ? 260 : 220
        
        ZStack {
            // White background rectangle
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)

            // Colored overlay rectangle
            RoundedRectangle(cornerRadius: 20)
                .fill(color.toSwiftUIColor(for: color).opacity(0.5))

            HStack(spacing: 12) {
                // 1. Avatar (larger)
                ZStack {
                    Circle()
                        .fill(color.toSwiftUIColor(for: color).opacity(0.7))
                        .frame(width: 70, height: 70)

                    if game.aiControlledPlayers.contains(color) {
                        Image("avatar_alien")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .foregroundColor(.black)
                    } else {
                        Image("avatar_\(color.rawValue)")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                    }
                }
                .frame(width: 80, height: 80)

                // 2. Score display
                Text("\(game.scores[color] ?? 0)")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .center)

                // 3. Mirchi Arrow (only in Mirchi mode)
                if game.gameMode == .mirchi {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title)
                        .foregroundColor(game.mirchiArrowActivated[color] == true ? color.toSwiftUIColor(for: color) : .white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                        .onTapGesture {
                            game.mirchiArrowActivated[color]?.toggle()
                        }
                }

                // 4. Dice (only for current player)
                if showDice {
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
                } else {
                    Spacer().frame(width: 60)
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(width: panelWidth, height: 100)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.toSwiftUIColor(for: color), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5)
        .onChange(of: game.rollID) { _ in
            if showDice && !isDiceRolling && !localDiceRolling {
                localDiceRolling = true
                DispatchQueue.main.asyncAfter(deadline: .now() + diceAnimationDuration) {
                    localDiceRolling = false
                }
            }
        }
    }
} 
