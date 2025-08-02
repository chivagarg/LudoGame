import SwiftUI

struct PlayerSelectionView: View {
    @Binding var selectedPlayers: Set<PlayerColor>
    @Binding var aiPlayers: Set<PlayerColor>
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            playerSelectionTable
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 2)
        .frame(width: 300)
    }
    
    private var headerView: some View {
        Text("Select Players")
            .font(.headline)
            .foregroundColor(.blue)
            .padding(.bottom, 8)
    }
    
    private var playerSelectionTable: some View {
        VStack(spacing: 0) {
            tableHeader
            playerRows
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var tableHeader: some View {
        HStack {
            Text("Player")
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Include")
                .fontWeight(.bold)
            Text("AI")
                .fontWeight(.bold)
                .frame(width: 50)
        }
        .padding(.horizontal)
    }
    
    private var playerRows: some View {
        ForEach(PlayerColor.allCases, id: \.self) { color in
            playerRow(color: color)
        }
    }
    
    private func playerRow(color: PlayerColor) -> some View {
        HStack {
            // Pawn image
            Image("pawn_\(color.rawValue)_marble_filled")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { selectedPlayers.contains(color) },
                set: { isSelected in
                    if isSelected {
                        selectedPlayers.insert(color)
                    } else {
                        selectedPlayers.remove(color)
                        aiPlayers.remove(color)
                    }
                }
            ))
            .labelsHidden()
            .tint(colorForPlayer(color))
            
            Toggle("", isOn: Binding(
                get: { aiPlayers.contains(color) },
                set: { isAI in
                    if isAI {
                        aiPlayers.insert(color)
                    } else {
                        aiPlayers.remove(color)
                    }
                }
            ))
            .labelsHidden()
            .frame(width: 50)
            .disabled(!selectedPlayers.contains(color))
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.white)
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

#Preview {
    PlayerSelectionView(selectedPlayers: .constant(Set(PlayerColor.allCases)), aiPlayers: .constant([]))
} 
