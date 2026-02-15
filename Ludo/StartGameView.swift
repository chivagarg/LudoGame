import SwiftUI

struct StartGameView: View {
    @Binding var isAdminMode: Bool
    @Binding var selectedPlayers: Set<PlayerColor>
    @Binding var aiPlayers: Set<PlayerColor>
    @Binding var selectedMode: GameMode
    let onStartGame: () -> Void

    // Decorative dice for the header - REMOVED

    @State private var step: Int = 0 // 0 = homepage, 1 = player selection (v2)
    @State private var showSettings: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Light purple background for the border
                Color(red: 249/255, green: 247/255, blue: 252/255).ignoresSafeArea()
                
                if step == 0 {
                    let isCompact = geo.size.width < 900
                    let heroTitleSize = min(max(34, geo.size.width * 0.07), 60)
                    let cardWidth = min(geo.size.width * 0.98, 1180)
                    let sidePadding = max(20.0, cardWidth * 0.09)

                    ZStack(alignment: .top) {
                        // Hero card centered in the full screen space.
                        HStack {
                            Spacer(minLength: 0)
                            Image("homepage-v0")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .overlay(
                                    HStack {
                                        VStack(alignment: .leading, spacing: isCompact ? 8 : 10) {
                                            Text("It's time to play")
                                                .font(isCompact ? .headline : .title3)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.black)
                                            
                                            Text("Ludo Mirchi!")
                                                .font(.system(size: heroTitleSize, weight: .black))
                                                .foregroundColor(.black)
                                                .minimumScaleFactor(0.8)
                                                .lineLimit(1)
                                            
                                            Text("Get 5 mirchis to hop backwards.\nCatch your opponents before\nthey catch you.")
                                                .font(isCompact ? .callout : .body)
                                                .foregroundColor(.black.opacity(0.7))
                                                .fixedSize(horizontal: false, vertical: true)
                                                .padding(.bottom, 12)
                                            
                                            MirchiPrimaryButton(title: "Play now!") {
                                                selectedMode = .mirchi
                                                withAnimation { step = 1 }
                                            }
                                        }
                                        .padding(.leading, sidePadding)
                                        .padding(.vertical, isCompact ? 16 : 24)
                                        
                                        Spacer()
                                    }
                                )
                                .frame(width: cardWidth)
                                .padding(.horizontal, 12)
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        // Top Bar overlay (excluded from centering calculations)
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
                    }
                    .transition(.opacity)
                } else if step == 1 {
                PlayerSelectionViewV2(isAdminMode: $isAdminMode,
                                        selectedPlayers: $selectedPlayers,
                                        aiPlayers: $aiPlayers,
                                        onStart: onStartGame,
                                        onBack: { withAnimation { step = 0 } })
                .transition(.opacity)
                }
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
 