import SwiftUI

struct PlayerPanelView: View {
    @EnvironmentObject var game: LudoGame
    let color: PlayerColor

    var body: some View {
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
                    Image("avatar_\(color.rawValue)")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                }
                .frame(width: 80, height: 80)

                // 2. Score display
                VStack {
                    Text("\(game.scores[color] ?? 0)")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity, alignment: .center)

                // 3. Empty section for future use
                Spacer()
                    .frame(width: 24)
            }
            .padding(.horizontal, 8)
        }
        .frame(width: 200, height: 100)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.toSwiftUIColor(for: color), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5)
    }
} 
