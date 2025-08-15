import SwiftUI

struct PawnView: View {
    @EnvironmentObject var game: LudoGame
    let pawn: PawnState
    let size: CGFloat
    
    @State private var isAnimating = false
    
    private var isEligible: Bool {
        // A pawn is eligible only if it belongs to the current player AND its ID is in the set.
        return pawn.color == game.currentPlayer && game.eligiblePawns.contains(pawn.id)
    }

    var body: some View {
        let avatarName = game.selectedAvatar(for: pawn.color)
        let isMango = avatarName.contains("mango")
        let isMirchi = avatarName.contains("mirchi")

        Image(avatarName)
            .renderingMode(.original)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .scaleEffect(isMirchi ? 1.25 : 1.0)
            .offset(x: isMango ? size * 0.1 : 0, y: isMango ? -size * 0.15 : 0)
            .shadow(color: .black.opacity(0.2), radius: size / 10, x: 0, y: size / 10) // Soft, ambient shadow
            .shadow(color: .black.opacity(0.5), radius: size / 40, x: 0, y: size / 40) // Sharp, contact shadow
            .scaleEffect(isAnimating ? 1.2 : 1.0)
            .onAppear {
                updateAnimation(for: isEligible)
            }
            .onChange(of: isEligible) { newValue in
                updateAnimation(for: newValue)
            }
    }
    
    private func updateAnimation(for isNowEligible: Bool) {
        if isNowEligible {
            // Guard against starting an animation that's already running
            guard !isAnimating else { return }
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        } else {
            // Guard against stopping an animation that's already stopped
            guard isAnimating else { return }
            withAnimation(.spring(duration: 0.3)) {
                isAnimating = false
            }
        }
    }
} 
