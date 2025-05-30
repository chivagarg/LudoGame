import SwiftUI

struct ScoringPanelView: View {
    @EnvironmentObject var game: LudoGame
    
    var body: some View {
        HStack(spacing: 20) {
            ForEach(PlayerColor.allCases) { color in
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Text(color.rawValue.capitalized)
                            .font(.headline)
                            .foregroundColor(colorForPlayer(color))
                        if game.hasCompletedGame(color: color) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("COMPLETED")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    Text("\(game.scores[color] ?? 0)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(colorForPlayer(color))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 2)
            }
        }
        .padding(.horizontal)
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
