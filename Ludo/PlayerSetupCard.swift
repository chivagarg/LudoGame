import SwiftUI

struct PlayerSetupCard: View {
    @Binding var isAdminMode: Bool
    @Binding var selectedPlayers: Set<PlayerColor>
    @Binding var aiPlayers: Set<PlayerColor>
    var onStart: () -> Void
    var onBack: () -> Void

    @State private var redX: CGFloat = 0
    @State private var redY: CGFloat = 0
    @State private var blueOffsetY: CGFloat = 0
    @State private var blueGone: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            // playful hop animation
            ZStack {
                Image("pawn_blue_marble_filled")
                    .resizable().frame(width: 24, height: 24)
                    .offset(x: 40, y: blueOffsetY)
                    .opacity(blueGone ? 0 : 1)
                Image("pawn_red_marble_filled")
                    .resizable().frame(width: 24, height: 24)
                    .offset(x: redX, y: redY)
            }
            .frame(height: 40)
            PlayerSelectionView(selectedPlayers: $selectedPlayers, aiPlayers: $aiPlayers)

            HStack {
                Button(action: onBack) {
                    Label("Back", systemImage: "chevron.left")
                }
                .padding(.horizontal, 24).padding(.vertical, 8)
                .background(Color.gray.opacity(0.2)).clipShape(Capsule())

                Spacer()

                Button(action: onStart) {
                    Label("Start", systemImage: "play.fill")
                        .font(.title3)
                        .padding(.horizontal, 32).padding(.vertical, 10)
                        .background(selectedPlayers.count < 2 ? Color.gray : PlayerColor.green.primaryColor)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .disabled(selectedPlayers.count < 2)
            }
        }
        .padding(10)
        .onAppear { startHopAnimation() }
    }

    private func startHopAnimation() {
        let hopCount = 6
        let hopDuration: Double = 0.2
        for i in 0..<hopCount {
            let upDelay = Double(i) * hopDuration * 2
            let downDelay = upDelay + hopDuration
            DispatchQueue.main.asyncAfter(deadline: .now() + upDelay) {
                withAnimation(.easeOut(duration: hopDuration)) { redY = -12 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + downDelay) {
                withAnimation(.easeIn(duration: hopDuration)) { redY = 0 }
            }
        }

        let kickDelay = Double(hopCount) * hopDuration * 2 + 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + kickDelay) {
            withAnimation(.easeInOut(duration: 0.3)) {
                redX = 40
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    blueOffsetY = -40
                    blueGone = true
                }
            }
        }
    }
} 
