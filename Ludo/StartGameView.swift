import SwiftUI

struct StartGameView: View {
    @EnvironmentObject private var game: LudoGame
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
                    let cardWidth = min(geo.size.width * 0.98, 1180)
                    let sidePadding = max(20.0, cardWidth * 0.09)
                    let contentScale = max(0.62, min(1.0, cardWidth / 760.0))
                    let heroTitleSize = min(max(24, cardWidth * 0.07), 56)
                    let topBarIconSize = min(max(24, geo.size.width * 0.045), 34)
                    let topBarPadding = min(max(8, geo.size.width * 0.018), 12)
                    let topBarCornerRadius = min(max(10, geo.size.width * 0.02), 14)

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
                                                .minimumScaleFactor(0.7)
                                                .lineLimit(1)
                                            
                                            Text("Get 5 mirchis to hop backwards.\nCatch your opponents before\nthey catch you.")
                                                .font(isCompact ? .callout : .body)
                                                .foregroundColor(.black.opacity(0.7))
                                                .lineLimit(3)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .padding(.bottom, 12)
                                            
                                            MirchiPrimaryButton(title: "Play now!") {
                                                selectedMode = .mirchi
                                                withAnimation { step = 1 }
                                            }
                                        }
                                        .scaleEffect(contentScale, anchor: .leading)
                                        .frame(maxWidth: cardWidth * 0.46, alignment: .leading)
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
                                        .font(.system(size: topBarIconSize, weight: .regular))
                                    Text("Exit")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(PlayerColor.red.primaryColor)
                                .padding(topBarPadding)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: topBarCornerRadius, style: .continuous))
                            }
                            
                            Spacer()

                            HStack(spacing: 10) {
                                coinBalancePill(iconSize: topBarIconSize, padding: topBarPadding, cornerRadius: topBarCornerRadius)

                                // Settings button
                                Button(action: { showSettings = true }) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: topBarIconSize, weight: .regular))
                                        .foregroundColor(.gray)
                                        .padding(topBarPadding)
                                        .background(.ultraThinMaterial, in: Circle())
                                }
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
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

    @ViewBuilder
    private func coinBalancePill(iconSize: CGFloat, padding: CGFloat, cornerRadius: CGFloat) -> some View {
        HStack(spacing: 8) {
            Image("coin")
                .resizable()
                .scaledToFit()
                .frame(width: iconSize * 0.95, height: iconSize * 0.95)

            Text("\(game.coins)")
                .font(.system(size: max(14, iconSize * 0.72), weight: .semibold))
                .foregroundColor(.black.opacity(0.85))
                .lineLimit(1)
        }
        .padding(.vertical, max(6, padding * 0.55))
        .padding(.horizontal, max(10, padding * 0.95))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
} 
 