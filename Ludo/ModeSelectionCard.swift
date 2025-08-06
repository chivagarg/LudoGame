import SwiftUI

struct ModeSelectionCard: View {
    var onSelect: (GameMode) -> Void

    @State private var bubbleAnimation: Bool = false

    var body: some View {
        ZStack {
            // floating color bubbles
            Circle()
                .fill(PlayerColor.red.primaryColor.opacity(0.15))
                .frame(width: 140)
                .offset(x: bubbleAnimation ? -120 : -80, y: bubbleAnimation ? -80 : -40)
                .blur(radius: 8)
            Circle()
                .fill(PlayerColor.green.primaryColor.opacity(0.15))
                .frame(width: 100)
                .offset(x: bubbleAnimation ? 90 : 120, y: bubbleAnimation ? -60 : -20)
                .blur(radius: 10)
            Circle()
                .fill(PlayerColor.yellow.primaryColor.opacity(0.15))
                .frame(width: 120)
                .offset(x: bubbleAnimation ? -90 : -110, y: bubbleAnimation ? 70 : 110)
                .blur(radius: 12)

            HStack(spacing: 24) {
            modePanel(title: "Classic", subtitle: "Standard rules", color: PlayerColor.green.secondaryColor.opacity(0.6), mode: .classic)
            modePanel(title: "Mirchi", subtitle: "Backward moves!", color: PlayerColor.red.primaryColor.opacity(0.6), mode: .mirchi)
            }
        }
        .onAppear { withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) { bubbleAnimation.toggle() } }
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func modePanel(title: String, subtitle: String, color: Color, mode: GameMode) -> some View {
        let press = Binding<Bool>(
            get: { false },
            set: { isPressed in
                if isPressed {
                    withAnimation(.spring()) {}
                }
            })
        Button(action: { onSelect(mode) }) {
            VStack(spacing: 12) {
                // Icon
                if mode == .classic {
                    Image("pawn_green_marble_filled")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .shadow(radius: 2)
                } else {
                    Image("mirchi")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .shadow(radius: 2)
                }

                // Title
                Text(title)
                    .font(.title3).bold()
                    .foregroundColor(.black)
                // Subtitle
                Text(subtitle)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.black.opacity(0.7))
            }
            .padding(20)
            .frame(width: 230, height: 260)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(color, lineWidth: 6)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(press.wrappedValue ? 0.95 : 1.0)
    }
} 
