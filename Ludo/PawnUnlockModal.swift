import SwiftUI

// MARK: - Animated number counter

/// Smoothly counts between values by conforming to Animatable.
/// SwiftUI interpolates `animatableData` each frame, so the displayed
/// integer visually counts up/down during a `withAnimation` block.
private struct AnimatableNumber: View, Animatable {
    var value: Double

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text(NumberFormatter.localizedString(from: NSNumber(value: Int(value)), number: .decimal))
    }
}

// MARK: - Pawn unlock modal

struct PawnUnlockModal: View {
    let pawnName: String
    let unlockCost: Int
    let coinBalance: Int   // post-deduction balance (coins already spent)
    /// When `true`, skips the coin-drain animation and jumps straight to the pawn reveal.
    /// Use this when coming from `CoinPurchaseModal`, which already showed the cashout.
    var skipCashout: Bool = false
    let onDismiss: () -> Void
    let onPlayNow: () -> Void

    private let details: PawnDetails

    @State private var animatedBalance: Double
    @State private var revealPawn: Bool = false
    @State private var pawnScale: CGFloat = 0.2
    @State private var showcaseTilt: Double = 0
    @State private var coinRotation: Double = 0
    @State private var coinScale: CGFloat = 1.0

    init(
        pawnName: String,
        unlockCost: Int,
        coinBalance: Int,
        skipCashout: Bool = false,
        onDismiss: @escaping () -> Void,
        onPlayNow: @escaping () -> Void
    ) {
        self.pawnName = pawnName
        self.unlockCost = unlockCost
        self.coinBalance = coinBalance
        self.skipCashout = skipCashout
        self.onDismiss = onDismiss
        self.onPlayNow = onPlayNow
        // Start at the pre-deduction balance, drain to the post-deduction balance
        self._animatedBalance = State(initialValue: Double(coinBalance + unlockCost))
        self.details = PawnCatalog.details(for: pawnName)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.38)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                dismissRow
                titleBlock

                // Animated center section
                ZStack {
                    cashoutCounter
                    pawnReveal
                }
                .frame(height: 240)

                if revealPawn {
                    Text("Find \(details.title) in the pawn selection in your next game!")
                        .boostDescriptionTextStyle()
                        .foregroundColor(.black.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 420)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                }

                playNowButton
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 20)
            .frame(maxWidth: 540)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.white))
            .shadow(color: .black.opacity(0.16), radius: 18, x: 0, y: 8)
            .padding(.horizontal, 22)
        }
        .onAppear { startCashoutAnimation() }
        .onDisappear { SoundManager.shared.stopCoinJangle() }
    }

    // MARK: - Sub-views

    private var dismissRow: some View {
        HStack {
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 26, weight: .regular))
                    .foregroundColor(.black.opacity(0.75))
            }
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 8) {
            Text("You've unlocked \(details.title)!")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            Text(details.description)
                .boostDescriptionTextStyle()
                .foregroundColor(.black.opacity(0.7))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Phase 0 — spinning coin + balance draining to post-deduction amount.
    private var cashoutCounter: some View {
        VStack(spacing: 10) {
            Image("coin")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .rotationEffect(.degrees(coinRotation))
                .scaleEffect(coinScale)

            AnimatableNumber(value: animatedBalance)
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundColor(.orange)

            Text("coins")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.gray)
        }
        .opacity(revealPawn ? 0 : 1)
        .animation(.easeOut(duration: 0.3), value: revealPawn)
    }

    /// Phase 1 — pawn bounces in.
    private var pawnReveal: some View {
        HStack(spacing: 16) {
            Image(pawnName)
                .resizable()
                .scaledToFit()
                .frame(width: 190, height: 190)
                .rotationEffect(.degrees(showcaseTilt))
                .shadow(color: .black.opacity(0.14), radius: 8, x: 0, y: 5)

            if let boostAsset = boostAssetName {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.96))
                        .overlay(
                            Circle()
                                .stroke(Color.purple.opacity(0.35), lineWidth: 3)
                        )
                        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
                        .frame(width: 90, height: 90)

                    Image(boostAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 54, height: 54)
                }
                .rotationEffect(.degrees(-showcaseTilt))
            }
        }
        .scaleEffect(pawnScale)
        .opacity(revealPawn ? 1 : 0)
        .animation(.easeIn(duration: 0.2), value: revealPawn)
    }

    private var boostAssetName: String? {
        guard let ability = BoostRegistry.ability(for: pawnName) else { return nil }
        switch ability.kind {
        case .rerollToSix: return PawnAssets.boostDice
        case .extraBackwardMove: return PawnAssets.boostMirchi
        case .safeZone: return PawnAssets.boostShield
        case .trap: return PawnAssets.boostTrap
        }
    }

    private var playNowButton: some View {
        Button("Play now") {
            onPlayNow()
        }
        .font(.system(size: 19, weight: .medium))
        .foregroundColor(.white)
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0x7C/255, green: 0x5C/255, blue: 0xD6/255))
        )
        .padding(.top, 4)
        .opacity(revealPawn ? 1 : 0)
        .animation(.easeIn(duration: 0.3), value: revealPawn)
    }

    // MARK: - Animation

    private func startCashoutAnimation() {
        if skipCashout {
            // Purchase modal already showed coins going up/down — jump straight to reveal.
            revealPawn = true
            SoundManager.shared.playPawnReachedHomeSound()
            withAnimation(.spring(response: 0.48, dampingFraction: 0.52)) {
                pawnScale = 1.0
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                showcaseTilt = 7
            }
            return
        }

        SoundManager.shared.startCoinJangle()

        // Coin spins three full turns over the drain duration
        withAnimation(.linear(duration: 3.0)) {
            coinRotation = 1080
        }
        // Coin pulses steadily during the drain
        withAnimation(.easeInOut(duration: 0.3).repeatCount(9, autoreverses: true)) {
            coinScale = 1.18
        }
        // Balance drains from (coinBalance + unlockCost) → coinBalance
        withAnimation(.linear(duration: 3.0)) {
            animatedBalance = Double(coinBalance)
        }
        // After the drain completes, stop the coins, reveal the pawn, play victory
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) {
            SoundManager.shared.stopCoinJangle()
            SoundManager.shared.playPawnReachedHomeSound()
            withAnimation(.easeInOut(duration: 0.2)) {
                revealPawn = true
            }
            withAnimation(.spring(response: 0.48, dampingFraction: 0.52)) {
                pawnScale = 1.0
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                showcaseTilt = 7
            }
        }
    }
}
