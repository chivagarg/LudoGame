import SwiftUI

struct PawnView: View {
    let pawn: PawnState
    let size: CGFloat
    let currentPlayer: PlayerColor

    private var pawnColor: Color {
        switch pawn.color {
        case .red: return .red
        case .green: return .green
        case .yellow: return .yellow
        case .blue: return .blue
        }
    }

    private var isCurrentPlayer: Bool {
        pawn.color == currentPlayer
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(pawnColor)
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)

            Circle()
                .stroke(Color.white.opacity(0.8), lineWidth: size * 0.05)
                .frame(width: size * 0.6, height: size * 0.6)
        }
    }
} 
