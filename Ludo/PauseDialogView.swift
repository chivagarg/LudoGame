import SwiftUI

struct PauseDialogView: View {
    var onResume: () -> Void
    var onRestart: () -> Void
    var onExit: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            dialogButton(label: "Resume", systemImage: "play.fill", color: .blue, action: onResume)
            dialogButton(label: "Restart", systemImage: "arrow.clockwise", color: .orange, action: onRestart)
            dialogButton(label: "Exit Game", systemImage: "rectangle.portrait.and.arrow.right", color: .red, action: onExit)
        }
        .padding(32)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color.white))
        .shadow(radius: 12)
    }

    @ViewBuilder
    private func dialogButton(label: String, systemImage: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .foregroundColor(color)
                    .font(.title)
                Text(label)
                    .font(.title2)
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 12)
    }
} 
