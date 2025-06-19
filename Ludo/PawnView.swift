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
            .shadow(color: .black.opacity(0.3), radius: size / 15, x: 0, y: size / 15)
    }
} 
