import SwiftUI

private struct ModalHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

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
    @State private var modalHeight: CGFloat = 600
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
    private func pawnBoostSymbols(for avatarName: String) -> some View {
        if let ability = BoostRegistry.ability(for: avatarName) {
            let boostsRemaining = max(1, PawnAssets.boostUses(for: avatarName))
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)

                    if ability.kind == .rerollToSix {
                        Image(systemName: "die.face.6.fill")
                            .font(.system(size: 34))
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
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundColor(.red)

                            Image(PawnAssets.mirchiIndicator)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 18, height: 18)
                        }
                    } else {
                        Image(systemName: ability.iconSystemName)
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundColor(Color.purple.opacity(0.7))
                    }
                }
                .frame(width: 56, height: 56)

                Text("\(boostsRemaining)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(minWidth: 60)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white))
            }
        }
    }

    var body: some View {
        ZStack {
            // Background
            Image("pawn-selection-background-v0")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            // Back Button
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

            // Content - Modal Style
            GeometryReader { geo in
                HStack(alignment: .top, spacing: 20) {
                    // Left Column: Game Options + Pawn Selection
                    VStack(spacing: 20) {
                        // Section 1: Game Options Card
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Game options")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            
                            // Player Count Selector
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
                            
                            // Player Rows
                            VStack(spacing: 12) {
                                ForEach(activeColors, id: \.self) { color in
                                    HStack {
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
                                        .frame(width: 56, height: 56)
                                        
                                        TextField(color.rawValue.capitalized, text: Binding(
                                            get: { playerNames[color] ?? "" },
                                            set: { playerNames[color] = $0 }
                                        ))
                                        .frame(width: 170)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.white)
                                        .cornerRadius(8)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.purple.opacity(0.2), lineWidth: 1))
                                        .foregroundColor(.black)
                                        
                                        Spacer(minLength: 8)
                                        
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
                            }
                        }
                        .padding(24)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        // Section 2: Pawn Selection Card
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
                                    .frame(width: 80, height: 80)
                                }
                                Spacer(minLength: 0)
                            }
                            .frame(height: 150)
                        }
                        .padding(24)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .frame(height: 280) // Fixed height for Pawn Selection
                        
                        MirchiPrimaryButton(title: "Start game") {
                            // Sync bindings based on the current rows.
                            let active = Set(activeColors)
                            selectedPlayers = active
                            aiPlayers = Set(activeColors.filter { isRobot[$0] ?? false })
                            // Mirror PlayerSetupCard behavior: persist avatar choices into the game before starting.
                            game.selectedAvatars = selectedAvatars
                            onStart()
                        }
                    }
                    .onChange(of: playerCount) { _ in
                        // If the selected row disappears (e.g. switching to 2 players), pick the first active row.
                        if !activeColors.contains(selectedPlayerColor) {
                            selectedPlayerColor = activeColors.first ?? .red
                        }
                    }
                    .frame(width: geo.size.width * 0.45) // 45% width for Left Column
                    
                    // Right Column (Section 3): Large Pawn Display
                    VStack(spacing: 0) {
                        Image(selectedAvatarNameForSelectedPlayer)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(40)
                            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                        
                        let details = getPawnDetails(for: selectedAvatarNameForSelectedPlayer)
                        
                        VStack(spacing: 12) {
                            Text(details.title)
                                .font(.system(size: 44, weight: .black, design: .rounded))
                                .foregroundColor(.black)
                            
                            if details.hasBoost {
                                HStack(spacing: 16) {
                                    pawnBoostSymbols(for: selectedAvatarNameForSelectedPlayer)
                                    Text(details.description)
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(.gray)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.top, 12)
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 0)
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                }
                .padding(40)
                .background(
                    GeometryReader { g in
                        Color.clear.preference(key: ModalHeightPreferenceKey.self, value: g.size.height)
                    }
                )
                .onPreferenceChange(ModalHeightPreferenceKey.self) { h in
                    // Avoid 0 during initial layout passes.
                    if h > 0 { modalHeight = h }
                }
                .frame(width: geo.size.width * 0.9)
                // Keep the TOP of the modal fixed so the Game Options card "expands downward".
                .position(
                    x: geo.size.width / 2,
                    y: max(24, (geo.size.height * 0.12) - 40) + (modalHeight / 2)
                )
            }
            .ignoresSafeArea()
        }
    }
}

