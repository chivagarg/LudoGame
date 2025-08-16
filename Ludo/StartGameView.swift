import SwiftUI

struct StartGameView: View {
    @Binding var isAdminMode: Bool
    @Binding var selectedPlayers: Set<PlayerColor>
    @Binding var aiPlayers: Set<PlayerColor>
    @Binding var selectedMode: GameMode
    let onStartGame: () -> Void

    // Decorative dice for the header
    private let diceImages = ["die.face.1", "die.face.2", "die.face.3", "die.face.4", "die.face.5", "die.face.6"]

    @State private var step: Int = 0 // 0 = mode select, 1 = setup players
    @State private var diceRoll: Bool = false
    
    var body: some View {
        ZStack {
            // Colorful animated bubbles backdrop
            GeometryReader { geo in
                ZStack {
                    ForEach(0..<12, id: \ .self) { i in
                        let colors: [Color] = [PlayerColor.red.primaryColor.opacity(0.25),
                                               PlayerColor.green.primaryColor.opacity(0.25),
                                               PlayerColor.yellow.primaryColor.opacity(0.25),
                                               PlayerColor.blue.primaryColor.opacity(0.25)]
                        let size = CGFloat(Int.random(in: 140...260))
                        Circle()
                            .fill(colors[i % colors.count])
                            .frame(width: size, height: size)
                            .position(x: CGFloat.random(in: 0...geo.size.width),
                                      y: CGFloat.random(in: 0...geo.size.height))
                            .animation(.easeInOut(duration: Double.random(in: 6...10)).repeatForever(autoreverses: true), value: diceRoll)
                    }
                }
            }
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
                        .foregroundColor(PlayerColor.red.primaryColor)
                        .padding(10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding([.top, .leading], 16)
                    Spacer()
                }
                Spacer()
            }

            VStack(spacing: 24) {
                // Spinning dice row
                HStack(spacing: 20) {
                    let palette: [Color] = [.red, .green, .yellow, .blue]
                    ForEach(0..<diceImages.count, id: \ .self) { idx in
                        Image(systemName: diceImages[idx])
                            .font(.system(size: 48))
                            .foregroundColor(palette[idx % palette.count])
                    }
                }
                // Colorful title
                HStack(spacing: 0) {
                    let title = Array("LUDO MIRCHI")
                    let palette: [Color] = [.red, .green, .yellow, .blue]
                    ForEach(title.indices, id: \ .self) { idx in
                        let ch = String(title[idx])
                        ZStack {
                            // 4-way outline
                            Text(ch)
                                .font(.system(size: 72, weight: .heavy))
                                .foregroundColor(.black)
                                .offset(x: 2, y: 2)
                            Text(ch)
                                .font(.system(size: 72, weight: .heavy))
                                .foregroundColor(.black)
                                .offset(x: -2, y: -2)
                            Text(ch)
                                .font(.system(size: 72, weight: .heavy))
                                .foregroundColor(.black)
                                .offset(x: -2, y: 2)
                            Text(ch)
                                .font(.system(size: 72, weight: .heavy))
                                .foregroundColor(.black)
                                .offset(x: 2, y: -2)
                            // center fill
                            Text(ch)
                                .font(.system(size: 72, weight: .heavy))
                                .foregroundColor(palette[idx % palette.count])
                        }
                    }
                }

                Group {
                    if step == 0 {
                        VStack(spacing: 30) {
                            ModeSelectionCard { mode in
                                selectedMode = mode
                                withAnimation { step = 1 }
                            }
                            let progress = UnlockManager.getCurrentProgress()
                            let nextUnlock = UnlockManager.getNextUnlockablePawn()
                            ProgressGaugeView(currentValue: progress.current, maxValue: progress.max, nextUnlockablePawn: nextUnlock)
#if DEBUG
                            SettingsTableView(isAdminMode: $isAdminMode)
#endif
                        }
                    } else {
                        PlayerSetupCard(isAdminMode: $isAdminMode,
                                        selectedPlayers: $selectedPlayers,
                                        aiPlayers: $aiPlayers,
                                        onStart: onStartGame,
                                        onBack: { withAnimation { step = 0 } })
                    }
                }
                .padding(10)
            }
            .padding()
            .onAppear { diceRoll = true }
        }
    }
} 
 