import SwiftUI

struct GameOverView: View {
    @EnvironmentObject var game: LudoGame
    @Binding var selectedPlayers: Set<PlayerColor>
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Game Over!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                ForEach(Array(game.finalRankings.enumerated()), id: \.element) { index, color in
                    HStack {
                        Text("\(index + 1).")
                            .font(.title2)
                            .foregroundColor(.gray)
                            .frame(width: 40, alignment: .leading)
                        
                        Text(color.rawValue.capitalized)
                            .font(.title2)
                            .foregroundColor(colorForPlayer(color))
                        
                        Spacer()
                        
                        Text("\(game.scores[color] ?? 0) pts")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(colorForPlayer(color))
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 2)
                }
            }
            .padding()
            
            Button("Play Again") {
                game.startGame(selectedPlayers: selectedPlayers)
            }
            .font(.title2)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(20)
    }
    
    private func colorForPlayer(_ color: PlayerColor) -> Color {
        switch color {
        case .red: return .red
        case .green: return .green
        case .yellow: return .yellow
        case .blue: return .blue
        }
    }
} 
