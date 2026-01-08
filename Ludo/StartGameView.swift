import SwiftUI

struct StartGameView: View {
    @Binding var isAdminMode: Bool
    @Binding var selectedPlayers: Set<PlayerColor>
    @Binding var aiPlayers: Set<PlayerColor>
    @Binding var selectedMode: GameMode
    let onStartGame: () -> Void

    // Decorative dice for the header - REMOVED
    
    @State private var step: Int = 0 // 0 = mode select, 1 = setup players
    @State private var showSettings: Bool = false
    
    var body: some View {
        ZStack {
            // Light purple background for the border
            Color(red: 249/255, green: 247/255, blue: 252/255).ignoresSafeArea()
            
            if step == 0 {
                VStack {
                    // Top Bar
                    HStack {
                        // Exit button
                        Button(action: { exit(0) }) {
                            VStack(spacing: 2) {
                                Image(systemName: "door.left.hand.open")
                                    .font(.largeTitle)
                                    Text("Exit")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                            }
                            .foregroundColor(PlayerColor.red.primaryColor)
                            .padding(10)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        
                        Spacer()
                        
                        // Settings button
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                                .padding(10)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    Spacer()
                    
                    // Homepage Image with Overlay
                    Image("homepage-v0")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .overlay(
                            HStack {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("It's time to play")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black)
                                    
                                    Text("Ludo Mirchi!")
                                        .font(.system(size: 60, weight: .black))
                                        .foregroundColor(.black)
                                    
                                    Text("Get 5 mirchis to hop backwards.\nCatch your opponents before\nthey catch you.")
                                        .font(.body)
                                        .foregroundColor(.black.opacity(0.7))
                                        .fixedSize(horizontal: false, vertical: true)
                                        .padding(.bottom, 16)
                                    
                                    Button(action: {
                                        selectedMode = .mirchi
                                        withAnimation { step = 1 }
                                    }) {
                                        Text("Play now!")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .padding(.vertical, 14)
                                            .padding(.horizontal, 32)
                                            .background(Color(red: 0x92/255, green: 0x5F/255, blue: 0xF0/255))
                                            .cornerRadius(12)
                                    }
                                }
                                .padding(.leading, 60) // Adjust based on image content layout
                                .padding(.vertical)
                                
                                Spacer() // Push content to left
                            }
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal)
                    
                    // Progress Gauge
                    let progress = UnlockManager.getCurrentProgress()
                    let nextUnlock = UnlockManager.getNextUnlockablePawn()
                    ProgressGaugeView(currentValue: progress.current, maxValue: progress.max, nextUnlockablePawn: nextUnlock)
                        .padding(.bottom, 20)
                        .padding(.horizontal)
                }
                .transition(.opacity)
            } else {
                PlayerSetupCard(isAdminMode: $isAdminMode,
                                selectedPlayers: $selectedPlayers,
                                aiPlayers: $aiPlayers,
                                onStart: onStartGame,
                                onBack: { withAnimation { step = 0 } })
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $showSettings) {
            if #available(iOS 16.0, *) {
                SettingsTableView(isAdminMode: $isAdminMode)
                    .presentationDetents([.medium])
            } else {
                SettingsTableView(isAdminMode: $isAdminMode)
            }
        }
    }
} 
 