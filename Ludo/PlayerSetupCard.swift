import SwiftUI

struct PlayerSetupCard: View {
    @Binding var isAdminMode: Bool
    @Binding var selectedPlayers: Set<PlayerColor>
    @Binding var aiPlayers: Set<PlayerColor>
    var onStart: () -> Void
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            PlayerSelectionView(selectedPlayers: $selectedPlayers, aiPlayers: $aiPlayers)

            HStack {
                Button(action: onBack) {
                    Label("Back", systemImage: "chevron.left")
                }
                .padding(.horizontal, 24).padding(.vertical, 8)
                .background(Color.gray.opacity(0.2)).clipShape(Capsule())

                Spacer()

                Button(action: onStart) {
                    Label("Start", systemImage: "play.fill")
                        .font(.title3)
                        .padding(.horizontal, 32).padding(.vertical, 10)
                        .background(selectedPlayers.count < 2 ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .disabled(selectedPlayers.count < 2)
            }
        }
        .padding(10)
    }
} 
