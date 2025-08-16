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
            selectedAvatars: $selectedAvatars,
            aiPlayers: $aiPlayers,
            avatarOptions: avatarOptions,
            colorForPlayer: colorForPlayer
        )

        ZStack {
            VStack(spacing: 0) {
                headerView
                playerSelectionTable
                avatarSelectionPanel
            }
            .coordinateSpace(name: "PlayerSelectionView")
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(radius: 2)
            .frame(width: 300)
            .overlay(popoverOverlay)
            .onPreferenceChange(PopoverPreferenceKey.self) { anchors in
                self.anchorFrames = anchors
            }
        }
    }
    
    private var headerView: some View {
        Text("Select Players")
            .font(.headline)
            .foregroundColor(.blue)
            .padding(.bottom, 8)
    }
    
    private var playerSelectionTable: some View {
        VStack(spacing: 0) {
            tableHeader
            playerRows
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var tableHeader: some View {
        HStack {
            Text("Player")
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Include")
                .fontWeight(.bold)
            Text("AI")
                .fontWeight(.bold)
                .frame(width: 50)
        }
        .padding(.horizontal)
    }
    
    private var playerRows: some View {
        ForEach(PlayerColor.allCases, id: \.self) { color in
            playerRow(color: color)
        }
    }
    
    private func avatarOptions(for color: PlayerColor) -> [String] {
        switch color {
        case .red:
            return ["pawn_mirchi", "pawn_red_marble_filled", "avatar_alien"]
        case .green:
            return ["pawn_mango_green", "pawn_green_marble_filled", "avatar_alien"]
        case .blue:
            return ["pawn_blue_marble_filled", "avatar_alien"]
        case .yellow:
            return ["pawn_mango", "pawn_yellow_marble_filled", "avatar_alien"]
        }
    }
    
    private func playerRow(color: PlayerColor) -> some View {
        HStack {
            // Pawn image with GeometryReader to find its position
            let avatarName = selectedAvatars[color] ?? "pawn_\(color.rawValue)_marble_filled"
            AvatarIcon(avatarName: avatarName, playerColor: colorForPlayer(color))
                .frame(width: 40, height: 40)
                .background(GeometryReader { geo in
                    Color.clear.preference(key: PopoverPreferenceKey.self, value: [color: geo.frame(in: .named("PlayerSelectionView"))])
                })
                .onTapGesture {
                    if let anchor = self.anchorFrames[color] {
                        self.popoverTarget = (color, anchor)
                    }
                }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { selectedPlayers.contains(color) },
                set: { isSelected in
                    if isSelected {
                        selectedPlayers.insert(color)
                    } else {
                        selectedPlayers.remove(color)
                        aiPlayers.remove(color)
                    }
                }
            ))
            .labelsHidden()
            .tint(colorForPlayer(color))
            
            Toggle("", isOn: Binding(
                get: { aiPlayers.contains(color) },
                set: { isAI in
                    if isAI {
                        aiPlayers.insert(color)
                    } else {
                        aiPlayers.remove(color)
                    }
                }
            ))
            .labelsHidden()
            .frame(width: 50)
            .disabled(!selectedPlayers.contains(color))
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.white)
    }
    
    private func colorForPlayer(_ color: PlayerColor) -> Color {
        return color.primaryColor
    }
    
    @State private var showingAvatarSelection: PlayerColor? = nil

    private func showAvatarSelection(for color: PlayerColor) {
        showingAvatarSelection = color
    }

    private var avatarSelectionPanel: some View {
        if let color = showingAvatarSelection {
            AnyView(
                VStack {
                    ForEach(avatarOptions(for: color), id: \.self) { avatar in
                        Button(action: {
                            selectedAvatars[color] = avatar
                            showingAvatarSelection = nil
                        }) {
                            Image(avatar)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)
            )
        } else {
            AnyView(EmptyView())
        }
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
                            AvatarIcon(avatarName: avatarName, playerColor: colorForPlayer(target.color))
                                .frame(width: 40, height: 40)
                                .onTapGesture {
                                    if avatarName == "avatar_alien" {
                                        aiPlayers.insert(target.color)
                                    } else {
                                        aiPlayers.remove(target.color)
                                    }
                                    selectedAvatars[target.color] = avatarName
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
