import SwiftUI

struct ModeSelectionCard: View {
    var onSelect: (GameMode) -> Void

    @State private var bubbleAnimation: Bool = false

    var body: some View {
        ZStack {
            // floating color bubbles
            Circle()
                .fill(Color.red.opacity(0.15))
                .frame(width: 140)
                .offset(x: bubbleAnimation ? -120 : -80, y: bubbleAnimation ? -80 : -40)
                .blur(radius: 8)
            Circle()
                .fill(Color.green.opacity(0.15))
                .frame(width: 100)
                .offset(x: bubbleAnimation ? 90 : 120, y: bubbleAnimation ? -60 : -20)
                .blur(radius: 10)
            Circle()
                .fill(Color.yellow.opacity(0.15))
                .frame(width: 120)
                .offset(x: bubbleAnimation ? -90 : -110, y: bubbleAnimation ? 70 : 110)
                .blur(radius: 12)

            HStack(spacing: 24) {
            modePanel(title: "Classic", subtitle: "Standard rules", color: .blue, mode: .classic)
            modePanel(title: "Mirchi", subtitle: "Backward moves!", color: .orange, mode: .mirchi)
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
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2).bold()
                    .foregroundColor(color)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 120, height: 120)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(color, lineWidth: 3)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(press.wrappedValue ? 0.95 : 1.0)
    }
} 
