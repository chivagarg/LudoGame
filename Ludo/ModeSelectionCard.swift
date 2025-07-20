import SwiftUI

struct ModeSelectionCard: View {
    var onSelect: (GameMode) -> Void

    var body: some View {
        HStack(spacing: 24) {
            modePanel(title: "Classic", subtitle: "Standard rules", color: .blue, mode: .classic)
            modePanel(title: "Mirchi", subtitle: "Backward moves!", color: .orange, mode: .mirchi)
        }
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func modePanel(title: String, subtitle: String, color: Color, mode: GameMode) -> some View {
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
    }
} 
