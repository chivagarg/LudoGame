import SwiftUI

struct StartGameView: View {
    @Binding var isAdminMode: Bool
    @Binding var selectedPlayers: Set<PlayerColor>
    @Binding var aiPlayers: Set<PlayerColor>
    @Binding var selectedMode: GameMode
    let onStartGame: () -> Void

    // Decorative dice for the header
    private let diceImages = ["die.face.1", "die.face.2", "die.face.3", "die.face.4", "die.face.5", "die.face.6"]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(red:0.96, green:0.98, blue:1.0), Color(red:0.85, green:0.93, blue:1.0)]),
                startPoint: .top,
                endPoint: .bottom)
                .ignoresSafeArea()

            // Exit button
            VStack {
                HStack {
                    Button(action: { exit(0) }) {
                        VStack(spacing: 2) {
                            Image(systemName: "door.left.hand.open")
                                .font(.largeTitle)
                            Text("Exit")
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.red)
                        .padding(10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding([.top, .leading], 16)
                    Spacer()
                }
                Spacer()
            }

            VStack(spacing: 24) {
                // Header with title & dice
                HStack(spacing: 8) {
                    ForEach(diceImages.shuffled().prefix(3), id: \ .self) { img in
                        Image(systemName: img)
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                Text("LUDO")
                    .font(.system(size: 48, weight: .heavy))
                    .foregroundStyle(.blue)
                    .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)

                // Glassmorphic card containing controls
                VStack(spacing: 28) {
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
                        .pickerStyle(.segmented)
                    }

                    PlayerSelectionView(selectedPlayers: $selectedPlayers, aiPlayers: $aiPlayers)

                    Button(action: onStartGame) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text("Start Game")
                        }
                        .font(.title2)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(selectedPlayers.count < 2 ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .shadow(radius: 4)
                    }
                    .disabled(selectedPlayers.count < 2)
                }
                .padding(30)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .shadow(radius: 10)
            }
            .padding()
        }
    }
} 
 