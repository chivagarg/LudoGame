import SwiftUI

struct PawnView: View {
    let pawn: PawnState
    let size: CGFloat
    let currentPlayer: PlayerColor

    var body: some View {
        Image("pawn_\(pawn.color.rawValue)")
            .renderingMode(.original)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.2), radius: size / 10, x: 0, y: size / 10) // Soft, ambient shadow
            .shadow(color: .black.opacity(0.5), radius: size / 40, x: 0, y: size / 40) // Sharp, contact shadow
    }
} 
