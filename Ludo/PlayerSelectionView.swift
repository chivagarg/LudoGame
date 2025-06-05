import SwiftUI

struct PlayerSelectionView: View {
    @Binding var selectedPlayers: Set<PlayerColor>
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            playerSelectionTable
        }
        .padding()
        .background(colorScheme == .dark ? Color.black : Color.white)
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
        .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var tableHeader: some View {
        HStack {
            Text("Player")
                .font(.subheadline)
                .foregroundColor(.green)
            Spacer()
            Text("Status")
                .font(.subheadline)
                .foregroundColor(.yellow)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1))
    }
    
    private var playerRows: some View {
        ForEach(PlayerColor.allCases, id: \.self) { color in
            playerRow(color: color)
        }
    }
    
    private func playerRow(color: PlayerColor) -> some View {
        HStack {
            // Player Pawn
            Circle()
                .fill(colorForPlayer(color))
                .frame(width: 30, height: 30)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
            
            Text(color.rawValue.capitalized)
                .font(.body)
                .foregroundColor(colorForPlayer(color))
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { selectedPlayers.contains(color) },
                set: { isSelected in
                    if isSelected {
                        selectedPlayers.insert(color)
                    } else {
                        selectedPlayers.remove(color)
                    }
                }
            ))
            .labelsHidden()
            .tint(colorForPlayer(color))
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(colorScheme == .dark ? Color.black : Color.white)
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
    PlayerSelectionView(selectedPlayers: .constant(Set(PlayerColor.allCases)))
} 
