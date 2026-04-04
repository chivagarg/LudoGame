import SwiftUI

struct PawnView: View {
    @EnvironmentObject var game: LudoGame
    let pawn: PawnState
    let size: CGFloat
    
    @State private var isAnimating = false
    
    /// Pulse when this pawn may be chosen for the current roll. With Mirchi backward arrow on, path pawns only pulse
    /// if `isValidBackwardMove` is true. Pawns still in **starting home** can't move backward; if the roll allows
    /// leaving home (e.g. 6), keep pulsing so turning Mirchi off still matches visible affordance.
    /// Extra backward-move boost armed: only pawns that can legally move backward with this roll (boost path).
    private var isEligible: Bool {
        guard pawn.color == game.currentPlayer else { return false }
        guard game.eligiblePawns.contains(pawn.id) else { return false }

        if game.boostAbility(for: game.currentPlayer)?.kind == .extraBackwardMove,
           game.getBoostState(for: game.currentPlayer) == .armed {
            return game.isValidBackwardMove(color: pawn.color, pawnId: pawn.id, isBoost: true)
        }

        if game.gameMode == .mirchi, game.mirchiArrowActivated[game.currentPlayer] == true {
            if game.isValidBackwardMove(color: pawn.color, pawnId: pawn.id) {
                return true
            }
            if pawn.positionIndex == nil, game.diceValue == GameConstants.sixDiceRoll {
                return true
            }
            return false
        }
        return true
    }

    var body: some View {
        let avatarName = game.selectedAvatar(for: pawn.color)

        AvatarIcon(avatarName: avatarName, playerColor: pawn.color.primaryColor)
            .frame(width: size, height: size)
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
