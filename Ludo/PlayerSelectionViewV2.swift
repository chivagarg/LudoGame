import SwiftUI

struct PlayerSelectionViewV2: View {
    @Binding var isAdminMode: Bool
    @Binding var selectedPlayers: Set<PlayerColor>
    @Binding var aiPlayers: Set<PlayerColor>
    var onStart: () -> Void
    var onBack: () -> Void

    @EnvironmentObject private var game: LudoGame
    
    @State private var playerCount: Int = 4
    @State private var playerNames: [PlayerColor: String] = [:]
    @State private var isRobot: [PlayerColor: Bool] = [:]
    @State private var selectedAvatars: [PlayerColor: String] = Dictionary(
        uniqueKeysWithValues: PlayerColor.allCases.map { color in
            (color, PawnAssets.defaultMarble(for: color))
        }
    )
    @State private var selectedPlayerColor: PlayerColor = .red
    
    var activeColors: [PlayerColor] {
        switch playerCount {
        case 2: return [.red, .yellow]
        case 3: return [.red, .green, .yellow]
        default: return [.red, .green, .yellow, .blue]
        }
    }

    private var selectedPlayerDisplayName: String {
        let raw = (playerNames[selectedPlayerColor] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !raw.isEmpty { return raw }
        return selectedPlayerColor.rawValue.capitalized
    }

    private func avatarOptions(for color: PlayerColor) -> [String] {
        switch color {
        case .red:
            return [PawnAssets.redMarble, PawnAssets.redTomato, PawnAssets.redAnar]
        case .green:
            return [PawnAssets.greenMarble, PawnAssets.greenCapsicum, PawnAssets.greenWatermelon]
        case .yellow:
            return [PawnAssets.yellowMarble, PawnAssets.yellowMango, PawnAssets.yellowPineapple]
        case .blue:
            return [PawnAssets.blueMarble, PawnAssets.blueAubergine, PawnAssets.blueJamun]
        }
    }

    private var selectedAvatarNameForSelectedPlayer: String {
        selectedAvatars[selectedPlayerColor] ?? PawnAssets.defaultMarble(for: selectedPlayerColor)
    }
    
    private func getPawnDetails(for avatarName: String) -> (title: String, description: String, hasBoost: Bool) {
        if avatarName == PawnAssets.redTomato {
            return ("Lal Tomato", "Gain an extra hop backwards (total of 6) for the duration of your game.", true)
        } else if avatarName == PawnAssets.redAnar {
            return ("Anar Kali", "Gain 2 extra hop backwards (total of 6) for the duration of your game.", true)
        } else if avatarName == PawnAssets.yellowMango {
            return ("Mango Tango", "Roll a 6 any time!", true)
        } else if avatarName == PawnAssets.yellowPineapple {
            return ("Pina Anna", "Roll a 6 any time, twice!", true)
        } else if avatarName == PawnAssets.greenCapsicum {
            return ("Shima Shield", "Place an extra safe zone on any empty space to protect pawns from capture", true)
        } else if avatarName == PawnAssets.greenWatermelon {
            return ("Tarboozii", "Place 2 extra safe zones on any empty space to protect pawns from capture.", true)
        } else if avatarName == PawnAssets.blueAubergine {
            return ("Bombergine", "Deploy a single trap to send opponents home, but beware, you could land on it too!", true)
        } else if avatarName == PawnAssets.blueJamun {
            return ("Jamun", "Deploy 2 traps to send opponents home, but beware, you could land on it too!", true)
        } else {
            let colorName = avatarName.contains("red") ? "Red" :
                            avatarName.contains("yellow") ? "Yellow" :
                            avatarName.contains("green") ? "Green" : "Blue"
            return ("Classic \(colorName)", "", false)
        }
    }

    @ViewBuilder
    private func pawnBoostSymbols(for avatarName: String, scale: CGFloat = 1.0) -> some View {
        if let ability = BoostRegistry.ability(for: avatarName) {
            let boostsRemaining = max(1, PawnAssets.boostUses(for: avatarName))
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)

                    if ability.kind == .rerollToSix {
                        Image(systemName: "die.face.6.fill")
                            .font(.system(size: 34 * scale))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 0.8, green: 0.6, blue: 0.0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: .orange.opacity(0.4), radius: 1, x: 1, y: 1)
                    } else if ability.kind == .extraBackwardMove {
                        HStack(spacing: 2) {
                            Text("+1")
                                .font(.system(size: 22 * scale, weight: .heavy, design: .rounded))
                                .foregroundColor(.red)

                            Image(PawnAssets.mirchiIndicator)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 18 * scale, height: 18 * scale)
                        }
                    } else {
                        Image(systemName: ability.iconSystemName)
                            .font(.system(size: 26 * scale, weight: .heavy))
                            .foregroundColor(Color.purple.opacity(0.7))
                    }
                }
                .frame(width: 56 * scale, height: 56 * scale)

                Text("\(boostsRemaining)")
                    .font(.system(size: 18 * scale, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(minWidth: 60 * scale)
                    .padding(.vertical, 6 * scale)
                    .background(Capsule().fill(Color.white))
            }
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("pawn-selection-background-v0")
                    .resizable()
                    .scaledToFill()
                    // Overscan slightly to hide any transparent edge pixels in the asset.
                    .frame(width: geo.size.width * 1.08, height: geo.size.height * 1.08)
                    .clipped()

                backButtonOverlay
                responsiveContent(in: geo)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
    }

    private var backButtonOverlay: some View {
        VStack {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                }
                .padding()
                Spacer()
            }
            Spacer()
        }
        .zIndex(1)
    }

    private struct LayoutMetrics {
        let sideMargin: CGFloat
        let modalWidth: CGFloat
        let spacing: CGFloat
        let leftWidth: CGFloat
        let rightWidth: CGFloat
        let rowCompact: Bool
        let cardHorizontalPadding: CGFloat
        let cardVerticalPadding: CGFloat
        let rowAvatarSize: CGFloat
        let rightTitleSize: CGFloat
        let rightDescriptionSize: CGFloat
        let rightImagePadding: CGFloat
    }

    private func metrics(for geo: GeometryProxy) -> LayoutMetrics {
        // Keep symmetric side margins, but avoid over-constraining compact iPads.
        let sideMargin: CGFloat = geo.size.width < 900 ? 24 : 32
        
        let modalWidth = geo.size.width - (sideMargin * 2)
        let spacing: CGFloat = 20
        let available = max(0, modalWidth - spacing)
        
        let isCompactScreen = geo.size.width < 900
        
        // Calculate Left Width
        let leftWidth: CGFloat
        if isCompactScreen {
            // On compact screens, prioritize right-panel visibility.
            leftWidth = min(available * 0.46, 330)
        } else {
            // On larger screens, left can take up to 55%
            leftWidth = min(available * 0.55, 460)
        }
        
        // Ensure min width for usability
        let finalLeftWidth = max(leftWidth, 230)
        
        // Right width is just whatever is left (used for font scaling calcs only)
        let rightWidth = max(0, available - finalLeftWidth)

        let rowCompact = finalLeftWidth < 420 // Aggressive compact mode for rows

        let result = LayoutMetrics(
            sideMargin: sideMargin,
            modalWidth: modalWidth,
            spacing: spacing,
            leftWidth: finalLeftWidth,
            rightWidth: rightWidth,
            rowCompact: rowCompact,
            cardHorizontalPadding: rowCompact ? 16.0 : 24.0,
            cardVerticalPadding: rowCompact ? 16.0 : 24.0,
            rowAvatarSize: rowCompact ? 44.0 : 56.0,
            rightTitleSize: min(max(20, rightWidth * 0.08), 38),
            rightDescriptionSize: min(max(13, rightWidth * 0.05), 20),
            rightImagePadding: min(max(4, rightWidth * 0.04), 24)
        )

#if DEBUG
        print(
            """
            [PlayerSelectionViewV2.metrics]
            geo.size=\(geo.size), safeArea=\(geo.safeAreaInsets)
            isCompactScreen=\(isCompactScreen), rowCompact=\(rowCompact)
            sideMargin=\(result.sideMargin), modalWidth=\(result.modalWidth), spacing=\(result.spacing), available=\(available)
            leftWidth=\(result.leftWidth), rightWidth=\(result.rightWidth)
            cardPaddingH=\(result.cardHorizontalPadding), cardPaddingV=\(result.cardVerticalPadding), rowAvatar=\(result.rowAvatarSize)
            rightTitleSize=\(result.rightTitleSize), rightDescriptionSize=\(result.rightDescriptionSize), rightImagePadding=\(result.rightImagePadding)
            """
        )
#endif

        return result
    }
    @ViewBuilder
    private func responsiveContent(in geo: GeometryProxy) -> some View {
        let m = metrics(for: geo)
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                HStack(alignment: .top, spacing: m.spacing) {
                    leftColumn(metrics: m)
                    rightColumn(metrics: m)
                }
                .frame(width: m.modalWidth, alignment: .center)
                .frame(maxWidth: .infinity, alignment: .center)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
#if DEBUG
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            let f = proxy.frame(in: .global)
                            print("[PlayerSelectionViewV2.debug] CenterContainer frame=\(f), size=\(proxy.size), screenWidth=\(geo.size.width)")
                        }
                        .onChange(of: proxy.size) { _ in
                            let f = proxy.frame(in: .global)
                            print("[PlayerSelectionViewV2.debug] CenterContainer changed frame=\(f), size=\(proxy.size), screenWidth=\(geo.size.width)")
                        }
                }
            )
#endif

            MirchiPrimaryButton(title: "Start game") {
                let active = Set(activeColors)
                selectedPlayers = active
                aiPlayers = Set(activeColors.filter { isRobot[$0] ?? false })
                game.selectedAvatars = selectedAvatars
                onStart()
            }
            .padding(.bottom, max(12, geo.safeAreaInsets.bottom))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func leftColumn(metrics m: LayoutMetrics) -> some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Game options")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                HStack(spacing: 0) {
                    ForEach([4, 3, 2], id: \.self) { count in
                        Button(action: {
                            withAnimation { playerCount = count }
                        }) {
                            Text("\(count) Players")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(playerCount == count ? Color(red: 0x5F/255, green: 0x25/255, blue: 0x9F/255) : Color.white)
                                .foregroundColor(playerCount == count ? .white : .purple)
                        }
                    }
                }
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.purple.opacity(0.3), lineWidth: 1))

                Text("Select your pawns")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)

                VStack(spacing: 12) {
                    ForEach(activeColors, id: \.self) { color in
                        playerRow(color: color, metrics: m)
                    }
                }
            }
            .padding(.horizontal, m.cardHorizontalPadding)
            .padding(.vertical, m.cardVerticalPadding)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 16) {
                Text("\(selectedPlayerDisplayName) pawn")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                HStack {
                    Text("Pawns")
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.purple)
                }

                let options = avatarOptions(for: selectedPlayerColor)
                HStack(spacing: 16) {
                    ForEach(options, id: \.self) { avatarName in
                        let isSelected = (selectedAvatars[selectedPlayerColor] ?? PawnAssets.defaultMarble(for: selectedPlayerColor)) == avatarName
                        Button {
                            selectedAvatars[selectedPlayerColor] = avatarName
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.9))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(isSelected ? Color.purple.opacity(0.7) : Color.purple.opacity(0.15), lineWidth: isSelected ? 3 : 1)
                                    )

                                Image(avatarName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .padding(10)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(width: m.rowCompact ? 68 : 80, height: m.rowCompact ? 68 : 80)
                    }
                    Spacer(minLength: 0)
                }
                .frame(height: m.rowCompact ? 120 : 150)
            }
            .padding(.horizontal, m.cardHorizontalPadding)
            .padding(.vertical, m.cardVerticalPadding)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .onChange(of: playerCount) { _ in
            if !activeColors.contains(selectedPlayerColor) {
                selectedPlayerColor = activeColors.first ?? .red
            }
        }
        .frame(width: m.leftWidth)
    }

    @ViewBuilder
    private func playerRow(color: PlayerColor, metrics m: LayoutMetrics) -> some View {
        HStack(spacing: m.rowCompact ? 8 : 10) {
            let avatarName = selectedAvatars[color] ?? PawnAssets.defaultMarble(for: color)
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple.opacity(0.35), lineWidth: 2)
                    )

                Image(avatarName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(6)
            }
            .frame(width: m.rowAvatarSize, height: m.rowAvatarSize)

            TextField(color.rawValue.capitalized, text: Binding(
                get: { playerNames[color] ?? "" },
                set: { playerNames[color] = $0 }
            ))
            .frame(minWidth: m.rowCompact ? 88 : 140, maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.purple.opacity(0.2), lineWidth: 1))
            .foregroundColor(.black)
            .lineLimit(1)
            .minimumScaleFactor(0.9)

            Spacer(minLength: 8)

            Group {
                if m.rowCompact {
                    VStack(spacing: 4) {
                        Text("Robot")
                            .font(.caption)
                            .foregroundColor(.black.opacity(0.7))
                        Toggle("", isOn: Binding(
                            get: { isRobot[color] ?? false },
                            set: { isRobot[color] = $0 }
                        ))
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: .purple))
                        .frame(width: 52)
                    }
                } else {
                    HStack(spacing: 8) {
                        Toggle("", isOn: Binding(
                            get: { isRobot[color] ?? false },
                            set: { isRobot[color] = $0 }
                        ))
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: .purple))

                        Text("Robot")
                            .font(.subheadline)
                            .foregroundColor(.black.opacity(0.7))
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded {
            selectedPlayerColor = color
        })
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .background(selectedPlayerColor == color ? Color.purple.opacity(0.06) : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(selectedPlayerColor == color ? Color.purple.opacity(0.35) : Color.clear, lineWidth: 2)
        )
        .cornerRadius(10)
    }

    @ViewBuilder
    private func rightColumn(metrics m: LayoutMetrics) -> some View {
        // Reserve an internal gutter so right-side content never hugs/clips the screen edge.
        let rightContentWidth = max(170, m.rightWidth - 48)
        let rightScale = max(0.46, min(1.0, rightContentWidth / 360.0))
        let isTightRightPanel = m.rowCompact || rightContentWidth < 420

        VStack(spacing: 0) {
            let details = getPawnDetails(for: selectedAvatarNameForSelectedPlayer)
            let isBoostedPawn = details.hasBoost
            let imageWidthFactor: CGFloat = isBoostedPawn ? (isTightRightPanel ? 0.60 : 0.72) : (isTightRightPanel ? 0.72 : 0.86)
            let titleScale: CGFloat = isBoostedPawn ? 0.78 : 0.92
            let descriptionScale: CGFloat = isBoostedPawn ? 0.76 : 0.9
            let boostSymbolScale: CGFloat = 0.78

            Image(selectedAvatarNameForSelectedPlayer)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: rightContentWidth * imageWidthFactor)
                .padding(m.rightImagePadding)
                .shadow(color: .black.opacity(0.18), radius: isBoostedPawn ? 10 : 16, x: 0, y: 8)
                // Force image to fit within available width
                .frame(maxWidth: .infinity, alignment: .center)
#if DEBUG
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear {
                                let f = proxy.frame(in: .global)
                                print("[PlayerSelectionViewV2.debug] PawnImage frame=\(f), size=\(proxy.size)")
                            }
                            .onChange(of: proxy.size) { _ in
                                let f = proxy.frame(in: .global)
                                print("[PlayerSelectionViewV2.debug] PawnImage changed frame=\(f), size=\(proxy.size)")
                            }
                    }
                )
#endif

            VStack(spacing: 12) {
                Text(details.title)
                    .font(.system(size: m.rightTitleSize * rightScale * titleScale, weight: .black, design: .rounded))
                    .foregroundColor(.black)
                    .minimumScaleFactor(0.6)
                    .lineLimit(3)
                    .allowsTightening(true)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if details.hasBoost {
                    let detailsRowWidth = rightContentWidth * 0.96
                    let symbolColumnWidth: CGFloat = 92
                    let descriptionColumnWidth = max(120, detailsRowWidth - symbolColumnWidth - 10)

                    HStack(alignment: .top, spacing: 10) {
                        Text(details.description)
                            .font(.system(size: m.rightDescriptionSize * rightScale * descriptionScale * 1.45, weight: .bold, design: .rounded))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .minimumScaleFactor(0.6)
                            .lineLimit(nil)
                            .frame(width: descriptionColumnWidth, alignment: .leading)
                            .layoutPriority(1)

                        pawnBoostSymbols(for: selectedAvatarNameForSelectedPlayer, scale: boostSymbolScale)
                            .fixedSize(horizontal: true, vertical: true)
                            .frame(width: symbolColumnWidth, alignment: .trailing)
                            .layoutPriority(2)
                    }
                    .frame(width: detailsRowWidth, alignment: .leading)
                    .padding(.top, 12)
                }
            }
            .padding(.horizontal, 10)
            .frame(width: rightContentWidth * 0.96, alignment: .center)

            Spacer(minLength: 0)
        }
        .frame(width: rightContentWidth, alignment: .top)
        .padding(.trailing, 8)
        .frame(maxHeight: .infinity, alignment: .top)
#if DEBUG
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        let f = proxy.frame(in: .global)
                        print("[PlayerSelectionViewV2.debug] RightColumn frame=\(f), size=\(proxy.size)")
                    }
                    .onChange(of: proxy.size) { _ in
                        let f = proxy.frame(in: .global)
                        print("[PlayerSelectionViewV2.debug] RightColumn changed frame=\(f), size=\(proxy.size)")
                    }
            }
        )
#endif
    }
}

