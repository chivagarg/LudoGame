import SwiftUI

struct StartGameView: View {
    @Binding var isAdminMode: Bool
    @Binding var selectedPlayers: Set<PlayerColor>
    let onStartGame: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Ludo")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            SettingsTableView(isAdminMode: $isAdminMode)
            
            PlayerSelectionView(selectedPlayers: $selectedPlayers)
            
            Button("Start Game") {
                onStartGame()
            }
            .font(.title2)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(selectedPlayers.count < 2)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.05))
    }
} 
