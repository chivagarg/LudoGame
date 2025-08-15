import SwiftUI

struct PlayerSelectionView: View {
    @Binding var selectedPlayers: Set<PlayerColor>
    @Binding var aiPlayers: Set<PlayerColor>
    @Binding var selectedAvatars: [PlayerColor: String]
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            playerSelectionTable
            avatarSelectionPanel
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
    
    private func avatarOptions(for color: PlayerColor) -> [String] {
        switch color {
        case .red:
            return ["pawn_mirchi", "pawn_red_marble_filled"]
        case .green:
            return ["pawn_mango_green", "pawn_green_marble_filled"]
        case .blue:
            return ["pawn_blue_marble_filled"]
        case .yellow:
            return ["pawn_mango", "pawn_yellow_marble_filled"]
        }
    }
    
    private func playerRow(color: PlayerColor) -> some View {
        HStack {
            // Pawn image
            Image(selectedAvatars[color] ?? "pawn_\(color.rawValue)_marble_filled")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .onTapGesture {
                    showAvatarSelection(for: color)
                }
            
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
        return color.primaryColor
    }
    
    @State private var showingAvatarSelection: PlayerColor? = nil

    private func showAvatarSelection(for color: PlayerColor) {
        showingAvatarSelection = color
    }

    private var avatarSelectionPanel: some View {
        if let color = showingAvatarSelection {
            AnyView(
                VStack {
                    ForEach(avatarOptions(for: color), id: \.self) { avatar in
                        Button(action: {
                            selectedAvatars[color] = avatar
                            showingAvatarSelection = nil
                        }) {
                            Image(avatar)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)
            )
        } else {
            AnyView(EmptyView())
        }
    }
}

#Preview {
    PlayerSelectionView(selectedPlayers: .constant(Set(PlayerColor.allCases)), aiPlayers: .constant([]), selectedAvatars: .constant([:]))
} 
