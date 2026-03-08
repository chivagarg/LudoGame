import SwiftUI

// MARK: - Animated number (shared with PawnUnlockModal pattern)

private struct PurchaseAnimatableNumber: View, Animatable {
    var value: Double

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text(NumberFormatter.localizedString(from: NSNumber(value: Int(value)), number: .decimal))
    }
}

// MARK: - Coin purchase modal

/// Shown when the user taps "Unlock Now!" on a locked pawn card.
/// Displays the target pawn, its cost, and the coins-to-buy calculation.
/// On mock purchase:
///   Phase 1 — balance counts UP by the purchased coin amount.
///   Phase 2 — balance counts DOWN by the unlock cost.
/// Then closes and hands off to PawnUnlockModal for the pawn reveal.
struct CoinPurchaseModal: View {
    let pawnName: String
    let currentCoinBalance: Int          // balance at the moment modal opens
    let onDismiss: () -> Void
    /// Called when the full purchase+cashout animation finishes.
    /// Provides the final coin balance so the caller can persist it and show PawnUnlockModal.
    let onPurchaseComplete: (_ finalBalance: Int) -> Void

    private let details: PawnDetails
    private let unlockCost: Int
    private let coinsToBuy: Int
    private let finalBalance: Int        // balance after buy + unlock deduction

    // Animation state
    @State private var animatedBalance: Double
    @State private var phase: PurchasePhase = .preview
    @State private var coinRotation: Double = 0
    @State private var coinScale: CGFloat = 1.0
    @State private var pawnFloat: CGFloat = 0

    private enum PurchasePhase {
        case preview      // showing purchase card, waiting for tap
        case buying       // counting UP
        case spending     // counting DOWN
    }

    init(
        pawnName: String,
        currentCoinBalance: Int,
        onDismiss: @escaping () -> Void,
        onPurchaseComplete: @escaping (_ finalBalance: Int) -> Void
    ) {
        self.pawnName = pawnName
        self.currentCoinBalance = currentCoinBalance
        self.onDismiss = onDismiss
        self.onPurchaseComplete = onPurchaseComplete
        self.details = PawnCatalog.details(for: pawnName)
        self.unlockCost = CoinPurchaseConfig.unlockCost(for: pawnName)
        self.coinsToBuy = CoinPurchaseConfig.coinsToBuy(
            currentBalance: currentCoinBalance, pawnName: pawnName)
        self.finalBalance = currentCoinBalance + CoinPurchaseConfig.coinsToBuy(
            currentBalance: currentCoinBalance, pawnName: pawnName) - CoinPurchaseConfig.unlockCost(for: pawnName)
        self._animatedBalance = State(initialValue: Double(currentCoinBalance))
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.38)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                dismissRow

                // Pawn preview with floating animation
                pawnPreview

                // Pawn name + ability
                titleBlock

                // Coin balance display (animates during purchase)
                coinBalanceRow

                Divider().padding(.horizontal, 8)

                // Purchase info / buy button
                if phase == .preview {
                    purchaseInfoBlock
                        .transition(.opacity)
                } else {
                    phaseLabel
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 20)
            .frame(maxWidth: 540)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.white))
            .shadow(color: .black.opacity(0.16), radius: 18, x: 0, y: 8)
            .padding(.horizontal, 22)
        }
        .onAppear { startPawnFloat() }
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

    private var pawnPreview: some View {
        Image(pawnName)
            .resizable()
            .scaledToFit()
            .frame(width: 160, height: 160)
            .offset(y: pawnFloat)
    }

    private var titleBlock: some View {
        VStack(spacing: 6) {
            Text(details.title)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)

            Text(details.description)
                .boostDescriptionTextStyle()
                .foregroundColor(.black.opacity(0.7))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var coinBalanceRow: some View {
        HStack(spacing: 8) {
            Image("coin")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .scaleEffect(coinScale)
                .rotationEffect(.degrees(coinRotation))

            PurchaseAnimatableNumber(value: animatedBalance)
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundColor(.orange)

            Text("coins")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }

    private var purchaseInfoBlock: some View {
        VStack(spacing: 12) {
            // How many coins needed summary
            let needed = CoinPurchaseConfig.coinsNeeded(
                currentBalance: currentCoinBalance, pawnName: pawnName)
            if needed > 0 {
                Text("You need \(formattedCoins(needed)) more coins to unlock \(details.title).")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }

            // Buy button
            let buyLabel = buyButtonLabel
            Button(action: startMockPurchase) {
                Text(buyLabel)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0x7C/255, green: 0x5C/255, blue: 0xD6/255))
                    )
            }
        }
    }

    private var buyButtonLabel: String {
        if coinsToBuy == 0 {
            // Already has enough coins — direct unlock
            return "Unlock \(details.title) now"
        }
        let price = CoinPurchaseConfig.formattedPrice(
            currentBalance: currentCoinBalance, pawnName: pawnName)
        let formatted = formattedCoins(coinsToBuy)
        return "Buy \(formatted) coins for \(price)"
    }

    private var phaseLabel: some View {
        Text(phase == .buying ? "Topping up coins…" : "Unlocking \(details.title)…")
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundColor(.gray)
            .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private func formattedCoins(_ value: Int) -> String {
        NumberFormatter.localizedString(from: NSNumber(value: value), number: .decimal)
    }

    // MARK: - Animation

    private func startPawnFloat() {
        // Gentle idle float while the user is reading the preview card.
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            pawnFloat = -10
        }
    }

    private func startExcitedHop() {
        // Rapid, high hops — overrides the idle float when the purchase is in flight.
        withAnimation(.easeInOut(duration: 0.18).repeatForever(autoreverses: true)) {
            pawnFloat = -22
        }
    }

    private func startMockPurchase() {
        let topUpAmount = coinsToBuy
        let topUpDuration: Double = topUpAmount > 0 ? 2.0 : 0.0
        let pauseBetweenPhases: Double = 2.0
        let spendDuration: Double = 2.0

        // Switch pawn to excited hop as soon as the purchase starts.
        startExcitedHop()

        // --- Phase 1: buy coins (balance goes UP) ---
        withAnimation(.easeInOut(duration: 0.15)) {
            phase = .buying
        }

        if topUpAmount > 0 {
            // Persist the topped-up balance immediately so game.coins stays live.
            UnlockManager.addCoins(topUpAmount)

            SoundManager.shared.startCoinJangle()

            withAnimation(.linear(duration: topUpDuration)) {
                animatedBalance = Double(currentCoinBalance + topUpAmount)
            }
            withAnimation(.linear(duration: topUpDuration)) {
                coinRotation = 720
            }
            withAnimation(.easeInOut(duration: 0.25).repeatCount(7, autoreverses: true)) {
                coinScale = 1.2
            }
        }

        // --- Phase 2: spend coins to unlock (balance goes DOWN) ---
        // Extra 2-second pause between the top-up finishing and the spend starting.
        DispatchQueue.main.asyncAfter(deadline: .now() + topUpDuration + pauseBetweenPhases) {
            withAnimation(.easeInOut(duration: 0.15)) {
                phase = .spending
            }

            // Deduct and unlock immediately so state is consistent.
            UnlockManager.purchaseUnlockPawn(pawnName)

            if topUpAmount == 0 { SoundManager.shared.startCoinJangle() }

            withAnimation(.linear(duration: spendDuration)) {
                animatedBalance = Double(finalBalance)
            }
            withAnimation(.linear(duration: spendDuration)) {
                coinRotation += 720
            }

            // --- Finish: close modal, hand off to PawnUnlockModal ---
            DispatchQueue.main.asyncAfter(deadline: .now() + spendDuration + 0.15) {
                SoundManager.shared.stopCoinJangle()
                onPurchaseComplete(finalBalance)
            }
        }
    }
}
