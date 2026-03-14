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
/// Displays the target pawn and direct purchase CTA.
/// Temporary mock behavior: tapping buy instantly unlocks the pawn.
struct CoinPurchaseModal: View {
    let pawnName: String
    let currentCoinBalance: Int          // balance at the moment modal opens
    let onDismiss: () -> Void
    /// Called when direct mock unlock completes.
    let onPurchaseComplete: () -> Void

    private let details: PawnDetails
    private let unlockCost: Int

    // Animation state
    @State private var animatedBalance: Double
    @State private var phase: PurchasePhase = .preview
    @State private var pawnFloat: CGFloat = 0

    private enum PurchasePhase {
        case preview      // showing purchase card, waiting for tap
        case unlocking
    }

    init(
        pawnName: String,
        currentCoinBalance: Int,
        onDismiss: @escaping () -> Void,
        onPurchaseComplete: @escaping () -> Void
    ) {
        self.pawnName = pawnName
        self.currentCoinBalance = currentCoinBalance
        self.onDismiss = onDismiss
        self.onPurchaseComplete = onPurchaseComplete
        self.details = PawnCatalog.details(for: pawnName)
        self.unlockCost = CoinPurchaseConfig.unlockCost(for: pawnName)
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
                neededCoinsLine

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

            PurchaseAnimatableNumber(value: animatedBalance)
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundColor(.orange)

            Text(GameCopy.Common.coins)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }

    private var purchaseInfoBlock: some View {
        VStack(spacing: 12) {
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

    private var neededCoinsLine: some View {
        let needed = max(0, unlockCost - currentCoinBalance)
        return Text(GameCopy.CoinPurchaseModal.neededCoins(formattedCoins(needed)))
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.gray)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 460)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var buyButtonLabel: String {
        let price = CoinPurchaseConfig.formattedDirectUnlockPrice(pawnName: pawnName)
        return GameCopy.CoinPurchaseModal.buyAndUnlockNow(price: price)
    }

    private var phaseLabel: some View {
        Text(GameCopy.CoinPurchaseModal.unlocking(details.title))
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundColor(.gray)
            .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private func formattedCoins(_ value: Int) -> String {
        NumberFormatter.localizedString(from: NSNumber(value: max(0, value)), number: .decimal)
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
        // Switch pawn to excited hop as soon as the purchase starts.
        startExcitedHop()
        withAnimation(.easeInOut(duration: 0.15)) {
            phase = .unlocking
        }

        // Temporary mock payment: unlock immediately, no coin top-up/cashout flow.
        UnlockManager.unlockPawn(pawnName)
        onPurchaseComplete()
    }
}
