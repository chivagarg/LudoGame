import SwiftUI

struct PlayerSelectionViewV2: View {
    @Binding var isAdminMode: Bool
    @Binding var selectedPlayers: Set<PlayerColor>
    @Binding var aiPlayers: Set<PlayerColor>
    var onStart: () -> Void
    var onBack: () -> Void
    
    @State private var playerCount: Int = 2
    @State private var playerNames: [PlayerColor: String] = [:]
    @State private var isRobot: [PlayerColor: Bool] = [:]
    
    var activeColors: [PlayerColor] {
        switch playerCount {
        case 2: return [.red, .yellow]
        case 3: return [.red, .green, .yellow]
        default: return [.red, .green, .yellow, .blue]
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
                HStack(alignment: .center, spacing: 20) {
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
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(color.primaryColor)
                                            .frame(width: 40, height: 40)
                                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black.opacity(0.1), lineWidth: 1))
                                        
                                        TextField("Player", text: Binding(
                                            get: { playerNames[color] ?? "Player" },
                                            set: { playerNames[color] = $0 }
                                        ))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.white)
                                        .cornerRadius(8)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.purple.opacity(0.2), lineWidth: 1))
                                        .foregroundColor(.black)
                                        
                                        Toggle("Robot", isOn: Binding(
                                            get: { isRobot[color] ?? false },
                                            set: { isRobot[color] = $0 }
                                        ))
                                        .labelsHidden()
                                        .toggleStyle(SwitchToggleStyle(tint: .purple))
                                    }
                                }
                            }
                        }
                        .padding(24)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        // Section 2: Pawn Selection Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("[Player 1] pawn")
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
                                Text("Accessories")
                                    .foregroundColor(.gray)
                            }
                            
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 150)
                                .overlay(Text("Pawn Grid Placeholder").foregroundColor(.gray))
                        }
                        .padding(24)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .frame(height: 280) // Fixed height for Pawn Selection
                    }
                    .frame(width: geo.size.width * 0.45) // 45% width for Left Column
                    
                    // Right Column (Section 3): Large Pawn Display
                    ZStack {
                        Image("pawn_red_marble_filled")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(40)
                            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                    }
                    .frame(maxHeight: .infinity)
                }
                .padding(40)
                .frame(width: geo.size.width * 0.9)
                .position(x: geo.size.width / 2, y: geo.size.height / 2) // Explicit centering
            }
            .ignoresSafeArea()
        }
    }
}

