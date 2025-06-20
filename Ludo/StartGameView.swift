import SwiftUI

struct StartGameView: View {
    @Binding var isAdminMode: Bool
    @Binding var selectedPlayers: Set<PlayerColor>
    @Binding var aiPlayers: Set<PlayerColor>
    @Binding var selectedMode: GameMode
    let onStartGame: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Ludo")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            SettingsTableView(isAdminMode: $isAdminMode)
            
            VStack {
                Text("Game Mode")
                    .font(.headline)
                    .foregroundColor(.blue)
                Picker("Game Mode", selection: $selectedMode) {
                    ForEach(GameMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(.vertical)
            .frame(width: 300)
            
            PlayerSelectionView(selectedPlayers: $selectedPlayers, aiPlayers: $aiPlayers)
            
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
