import SwiftUI

struct PauseDialogView: View {
    var onResume: () -> Void
    var onRestart: () -> Void
    var onExit: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            dialogButton(label: "Resume", systemImage: "play.fill", color: .blue, action: onResume)
            dialogButton(label: "Restart", systemImage: "arrow.clockwise", color: .orange, action: onRestart)
            dialogButton(label: "Exit Game", systemImage: "rectangle.portrait.and.arrow.right", color: .red, action: onExit)
        }
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
        .shadow(radius: 8)
    }

    @ViewBuilder
    private func dialogButton(label: String, systemImage: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(color)
                    .font(.title2)
                Text(label)
                    .font(.title3)
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 8)
    }
} 
