import SwiftUI

struct PlayerSelectionView: View {
    @Binding var selectedPlayers: Set<PlayerColor>
    @Binding var aiPlayers: Set<PlayerColor>
    @Binding var selectedAvatars: [PlayerColor: String]
    
    // State for the popover
    @State private var popoverTarget: (color: PlayerColor, anchor: CGRect)? = nil
    @State private var anchorFrames: [PlayerColor: CGRect] = [:]

    var body: some View {
        let popoverOverlay = AvatarHorizontalPopover(
            target: $popoverTarget,
            selectedPlayers: $selectedPlayers,
            selectedAvatars: $selectedAvatars,
            aiPlayers: $aiPlayers,
            avatarOptions: avatarOptions,
            colorForPlayer: colorForPlayer
        )

        ZStack {
            VStack(spacing: 0) {
                playerSelectionTable
            }
            .coordinateSpace(name: "PlayerSelectionView")
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 6)
            )
            .shadow(radius: 2)
            .frame(width: 300)
            .overlay(popoverOverlay)
            .onPreferenceChange(PopoverPreferenceKey.self) { anchors in
                self.anchorFrames = anchors
            }
        }
        .onAppear {
            resetPlayerSelection()
        }
    }
    
    private func resetPlayerSelection() {
        selectedPlayers = Set(PlayerColor.allCases)
        aiPlayers.removeAll()
        selectedAvatars = PlayerColor.allCases.reduce(into: [:]) { result, color in
            result[color] = PawnAssets.defaultMarble(for: color)
        }
    }

    private var playerSelectionTable: some View {
        VStack(spacing: 0) {
            ForEach(Array(PlayerColor.allCases.enumerated()), id: \.element) { index, color in
                PlayerRowView(
                    color: color,
                    playerIndex: index + 1,
                    selectedPlayers: $selectedPlayers,
                    aiPlayers: $aiPlayers,
                    selectedAvatars: $selectedAvatars,
                    popoverTarget: $popoverTarget,
                    anchorFrames: $anchorFrames,
                    colorForPlayer: colorForPlayer
                )
            }
        }
    }
    
    private func avatarOptions(for color: PlayerColor) -> [String] {
        var options: [String] = []
        switch color {
        case .red:
            options = [PawnAssets.redMirchi, PawnAssets.redMarble, PawnAssets.alien]
        case .green:
            options = [PawnAssets.greenMango, PawnAssets.greenCapsicum, PawnAssets.greenMarble, PawnAssets.alien]
        case .blue:
            options = [PawnAssets.blueAubergine, PawnAssets.blueMarble, PawnAssets.alien]
        case .yellow:
            options = [PawnAssets.yellowMango, PawnAssets.yellowMarble, PawnAssets.alien]
        }
        options.append("unselect")
        return options
    }
    
    private func colorForPlayer(_ color: PlayerColor) -> Color {
        return color.primaryColor
    }
}

fileprivate struct PlayerRowView: View {
    let color: PlayerColor
    let playerIndex: Int
    @Binding var selectedPlayers: Set<PlayerColor>
    @Binding var aiPlayers: Set<PlayerColor>
    @Binding var selectedAvatars: [PlayerColor: String]
    @Binding var popoverTarget: (color: PlayerColor, anchor: CGRect)?
    @Binding var anchorFrames: [PlayerColor: CGRect]
    let colorForPlayer: (PlayerColor) -> Color

    var body: some View {
        let isEnabled = selectedPlayers.contains(color)
        let isAI = aiPlayers.contains(color)
        
        HStack {
            Text(isAI ? "AI Bot" : "Player \(playerIndex)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(isEnabled ? color.primaryColor : .gray)

            Spacer()

            // Pawn image with GeometryReader to find its position
            let avatarName = selectedAvatars[color] ?? PawnAssets.defaultMarble(for: color)
            ZStack(alignment: .bottomTrailing) {
                AvatarIcon(avatarName: avatarName, playerColor: colorForPlayer(color))
                
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.title3)
                    .foregroundColor(color.primaryColor)
                    .background(Circle().fill(Color.white).scaleEffect(1.2))
                    .shadow(radius: 2)
            }
            .frame(width: 60, height: 60)
            .background(GeometryReader { geo in
                Color.clear.preference(key: PopoverPreferenceKey.self, value: [color: geo.frame(in: .named("PlayerSelectionView"))])
            })
                .onTapGesture {
                    if let anchor = self.anchorFrames[color] {
                        self.popoverTarget = (color, anchor)
                    }
                }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .opacity(isEnabled ? 1.0 : 0.7)
    }
}

// Preference key to communicate pawn view frames up the hierarchy
fileprivate struct PopoverPreferenceKey: PreferenceKey {
    typealias Value = [PlayerColor: CGRect]
    static var defaultValue: Value = [:]
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

public struct AvatarIcon: View {
    let avatarName: String
    let playerColor: Color

    public init(avatarName: String, playerColor: Color) {
        self.avatarName = avatarName
        self.playerColor = playerColor
    }

    public var body: some View {
        if avatarName == "avatar_alien" {
            Image(avatarName)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(playerColor)
        } else if avatarName == "unselect" {
            Image(avatarName)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Image(avatarName)
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
}

// The new horizontal popover view
fileprivate struct AvatarHorizontalPopover: View {
    @Binding var target: (color: PlayerColor, anchor: CGRect)?
    @Binding var selectedPlayers: Set<PlayerColor>
    @Binding var selectedAvatars: [PlayerColor: String]
    @Binding var aiPlayers: Set<PlayerColor>
    
    let avatarOptions: (PlayerColor) -> [String]
    let colorForPlayer: (PlayerColor) -> Color
    
    var body: some View {
        if let target = target {
            let options = avatarOptions(target.color)
            ZStack {
                // Background dismiss layer
                Color.black.opacity(0.01)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture { self.target = nil }
                
                VStack(spacing: 0) {
                    HStack(spacing: 15) {
                        ForEach(options, id: \.self) { avatarName in
                            let locked = UnlockManager.isPawnLocked(avatarName)
                            ZStack {
                                AvatarIcon(avatarName: avatarName, playerColor: colorForPlayer(target.color))
                                    .grayscale(locked ? 1.0 : 0.0)
                                    .opacity(locked ? 0.5 : 1.0)

                                if locked {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.white)
                                        .font(.title)
                                        .shadow(radius: 2)
                                }
                            }
                            .frame(width: 50, height: 50)
                            .onTapGesture {
                                guard !locked else { return }
                                
                                if avatarName == "unselect" {
                                    selectedPlayers.remove(target.color)
                                    aiPlayers.remove(target.color)
                                } else if avatarName == "avatar_alien" {
                                    selectedPlayers.insert(target.color)
                                    aiPlayers.insert(target.color)
                                    selectedAvatars[target.color] = avatarName
                                } else {
                                    selectedPlayers.insert(target.color)
                                    aiPlayers.remove(target.color)
                                    selectedAvatars[target.color] = avatarName
                                }
                                self.target = nil // Dismiss
                            }
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(12)
                    
                    // Chevron pointing down
                    Chevron()
                        .fill(Color.black.opacity(0.8))
                        .frame(width: 20, height: 10)
                }
                .position(x: target.anchor.midX + 20, y: target.anchor.minY - 40)
            }
        }
    }
}

// Custom shape for the chevron
fileprivate struct Chevron: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}


#Preview {
    PlayerSelectionView(selectedPlayers: .constant(Set(PlayerColor.allCases)), aiPlayers: .constant([]), selectedAvatars: .constant([:]))
} 
