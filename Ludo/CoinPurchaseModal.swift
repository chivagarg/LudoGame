import SwiftUI

// MARK: - Animated number (shared with PackUnlockModal pattern)

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

// MARK: - Coin purchase modal (mock IAP unlocks a whole pack)

/// Shown when the user taps "Unlock Now!" on a locked pack card or pawn tile.
/// Temporary mock behavior: tapping buy instantly unlocks all four pawns in the pack (no coins spent).
struct CoinPurchaseModal: View {
    let pack: PawnPack
    let currentCoinBalance: Int
    let onDismiss: () -> Void
    let onPurchaseComplete: () -> Void

    private let unlockCost: Int

    @State private var animatedBalance: Double
    @State private var phase: PurchasePhase = .preview
    @State private var previewFloat: CGFloat = 0

    private enum PurchasePhase {
        case preview
        case unlocking
    }

    init(
        pack: PawnPack,
        currentCoinBalance: Int,
        onDismiss: @escaping () -> Void,
        onPurchaseComplete: @escaping () -> Void
    ) {
        self.pack = pack
        self.currentCoinBalance = currentCoinBalance
        self.onDismiss = onDismiss
        self.onPurchaseComplete = onPurchaseComplete
        self.unlockCost = pack.coinCost
        self._animatedBalance = State(initialValue: Double(currentCoinBalance))
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.38)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                dismissRow

                packPreview

                titleBlock

                coinBalanceRow
                neededCoinsLine

                Divider().padding(.horizontal, 8)

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
        .onAppear { startPreviewFloat() }
        .onDisappear { SoundManager.shared.stopCoinJangle() }
    }

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

    private var packPreview: some View {
        RotatingPackPawnPreview(pack: pack)
            .frame(width: 160, height: 160)
            .offset(y: previewFloat)
    }

    private var titleBlock: some View {
        VStack(spacing: 10) {
            Text(pack.displayName)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)

            Text(GameCopy.CoinPurchaseModal.packIncludesFourPawns)
                .boostDescriptionTextStyle()
                .foregroundColor(.black.opacity(0.7))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
                .fixedSize(horizontal: false, vertical: true)

            PackPawnCatalogListCard(pawnAssetNames: pack.pawnAssetNames, maxHeight: 300)
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
            Button(action: startMockPurchase) {
                Text(GameCopy.CoinPurchaseModal.buyPackNow(price: pack.formattedMockIAPPrice))
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
        return Text(GameCopy.CoinPurchaseModal.neededCoinsForPack(formattedCoins(needed)))
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.gray)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 460)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var phaseLabel: some View {
        Text(GameCopy.CoinPurchaseModal.unlockingPack(pack.displayName))
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundColor(.gray)
            .padding(.vertical, 8)
    }

    private func formattedCoins(_ value: Int) -> String {
        NumberFormatter.localizedString(from: NSNumber(value: max(0, value)), number: .decimal)
    }

    private func startPreviewFloat() {
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
            previewFloat = -10
        }
    }

    private func startExcitedHop() {
        withAnimation(.easeInOut(duration: 0.18).repeatForever(autoreverses: true)) {
            previewFloat = -22
        }
    }

    private func startMockPurchase() {
        guard !UnlockManager.isPackUnlocked(pack) else {
            onDismiss()
            return
        }
        startExcitedHop()
        withAnimation(.easeInOut(duration: 0.15)) {
            phase = .unlocking
        }
        _ = UnlockManager.unlockPackViaIAPMock(pack)
        onPurchaseComplete()
    }
}
