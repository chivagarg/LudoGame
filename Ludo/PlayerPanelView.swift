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
            
            VStack {
                Text(color.rawValue.capitalized)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(color.toSwiftUIColor(for: color).opacity(0.8))
                
                Text("Score: \(game.scores[color] ?? 0)")
                    .font(.headline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.black)
        }
        .frame(width: 200, height: 100) // Made the panel longer
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.toSwiftUIColor(for: color), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5)
    }
} 
