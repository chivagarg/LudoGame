import SwiftUI

// MARK: - Rotating preview (cycles through the four pawns in a pack)

struct RotatingPackPawnPreview: View {
    let pack: PawnPack
    private let names: [String]

    @State private var index = 0

    init(pack: PawnPack) {
        self.pack = pack
        self.names = pack.pawnAssetNames
    }

    var body: some View {
        ZStack {
            ForEach(names.indices, id: \.self) { i in
                Image(names[i])
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(6)
                    .opacity(i == index ? 1 : 0)
                    .scaleEffect(i == index ? 1 : 0.92)
                    .animation(.easeInOut(duration: 0.38), value: index)
            }
        }
        .onReceive(Timer.publish(every: 1.65, on: .main, in: .common).autoconnect()) { _ in
            guard !names.isEmpty else { return }
            index = (index + 1) % names.count
        }
    }
}

// MARK: - Pawn + long description rows (same copy as `PawnUnlockModal` / `PawnCatalog.details`)

/// Pawn artwork on the left, name + full `PawnCatalog` description on the right — shared by purchase and pack-unlock modals.
struct PackPawnCatalogRows: View {
    let pawnAssetNames: [String]

    private let iconSide: CGFloat = 44
    private let iconColumnWidth: CGFloat = 52
    private let rowSpacing: CGFloat = 16

    var body: some View {
        VStack(alignment: .leading, spacing: rowSpacing) {
            ForEach(pawnAssetNames, id: \.self) { name in
                packRow(for: name)
            }
        }
        .frame(maxWidth: 420, alignment: .leading)
    }

    @ViewBuilder
    private func packRow(for name: String) -> some View {
        let d = PawnCatalog.details(for: name)
        let desc = d.description.trimmingCharacters(in: .whitespacesAndNewlines)

        HStack(alignment: .top, spacing: 12) {
            Image(name)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSide, height: iconSide)
                .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                .frame(width: iconColumnWidth, alignment: .center)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                Text(d.title)
                    .pawnNameTextStyle()
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if !desc.isEmpty {
                    Text(d.description)
                        .boostDescriptionTextStyle()
                        .foregroundColor(.black.opacity(0.72))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// Scrollable pack roster with one rounded panel (fill + stroke) — purchase + pack-unlock modals.
struct PackPawnCatalogListCard: View {
    let pawnAssetNames: [String]
    var maxHeight: CGFloat = 300

    private let cornerRadius: CGFloat = 14
    private let innerPadding: CGFloat = 14

    private var cardFill: Color {
        Color(red: 0x7C/255, green: 0x5C/255, blue: 0xD6/255).opacity(0.07)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            PackPawnCatalogRows(pawnAssetNames: pawnAssetNames)
                .padding(innerPadding)
        }
        .frame(maxHeight: maxHeight)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Animated number (shared pattern with PawnUnlockModal)

private struct PackAnimatableNumber: View, Animatable {
    var value: Double

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text(NumberFormatter.localizedString(from: NSNumber(value: Int(value)), number: .decimal))
    }
}

// MARK: - Four-pawn celebration cluster

private struct PackPawnCelebrationCluster: View {
    let pawnNames: [String]

    @State private var scales: [CGFloat] = [0.18, 0.18, 0.18, 0.18]

    private struct BlossomSlot {
        let x: CGFloat
        let y: CGFloat
        let delay: TimeInterval
        let size: CGFloat
        let tilt: Double
    }

    private var slots: [BlossomSlot] {
        [
            BlossomSlot(x: 0, y: 22, delay: 0, size: 76, tilt: -6),
            BlossomSlot(x: -56, y: -6, delay: 0.1, size: 64, tilt: 8),
            BlossomSlot(x: 56, y: -6, delay: 0.18, size: 64, tilt: -5),
            BlossomSlot(x: 0, y: -62, delay: 0.26, size: 58, tilt: 4)
        ]
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<min(4, pawnNames.count), id: \.self) { i in
                    let slot = slots[i]
                    let bob = sin(t * 2.15 + Double(i) * 0.95) * 4.5
                    Image(pawnNames[i])
                        .resizable()
                        .scaledToFit()
                        .frame(width: slot.size, height: slot.size)
                        .shadow(color: .black.opacity(0.14), radius: 7, x: 0, y: 5)
                        .rotationEffect(.degrees(slot.tilt + sin(t * 1.8 + Double(i) * 1.1) * 3))
                        .offset(x: slot.x, y: slot.y + CGFloat(bob))
                        .scaleEffect(i < scales.count ? scales[i] : 1)
                }
            }
            .frame(width: 200, height: 200)
        }
        .onAppear {
            for i in 0..<min(4, pawnNames.count) {
                let d = slots[i].delay
                DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.52)) {
                        if i < scales.count {
                            scales[i] = 1.0
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Pack unlock modal (coin cash-out + four-pawn reveal)

struct PackUnlockModal: View {
    let pack: PawnPack
    let unlockCost: Int
    let coinBalance: Int
    var skipCashout: Bool = false
    let onDismiss: () -> Void
    let onPlayNow: () -> Void

    @State private var animatedBalance: Double
    @State private var revealPawns: Bool = false
    @State private var coinRotation: Double = 0
    @State private var coinScale: CGFloat = 1.0

    init(
        pack: PawnPack,
        unlockCost: Int,
        coinBalance: Int,
        skipCashout: Bool = false,
        onDismiss: @escaping () -> Void,
        onPlayNow: @escaping () -> Void
    ) {
        self.pack = pack
        self.unlockCost = unlockCost
        self.coinBalance = coinBalance
        self.skipCashout = skipCashout
        self.onDismiss = onDismiss
        self.onPlayNow = onPlayNow
        self._animatedBalance = State(initialValue: Double(coinBalance + unlockCost))
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.38)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                dismissRow

                Text(GameCopy.PackUnlockModal.unlockedTitle(pack.displayName))
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: 420)

                ZStack {
                    cashoutCounter
                    pawnClusterReveal
                }
                .frame(height: 268)

                if revealPawns {
                    PackPawnCatalogListCard(pawnAssetNames: pack.pawnAssetNames, maxHeight: 320)
                        .transition(.opacity)

                    Text(GameCopy.PackUnlockModal.whereToFind)
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

    private var cashoutCounter: some View {
        VStack(spacing: 10) {
            Image("coin")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .rotationEffect(.degrees(coinRotation))
                .scaleEffect(coinScale)

            PackAnimatableNumber(value: animatedBalance)
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundColor(.orange)

            Text(GameCopy.Common.coins)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.gray)
        }
        .opacity(revealPawns ? 0 : 1)
        .animation(.easeOut(duration: 0.3), value: revealPawns)
    }

    private var pawnClusterReveal: some View {
        PackPawnCelebrationCluster(pawnNames: pack.pawnAssetNames)
            .opacity(revealPawns ? 1 : 0)
            .animation(.easeIn(duration: 0.22), value: revealPawns)
    }

    private var playNowButton: some View {
        Button(GameCopy.Common.playNow) {
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
        .opacity(revealPawns ? 1 : 0)
        .animation(.easeIn(duration: 0.3), value: revealPawns)
    }

    private func startCashoutAnimation() {
        if skipCashout || unlockCost <= 0 {
            revealPawns = true
            SoundManager.shared.playPawnReachedHomeSound()
            return
        }

        SoundManager.shared.startCoinJangle()

        withAnimation(.linear(duration: 3.0)) {
            coinRotation = 1080
        }
        withAnimation(.easeInOut(duration: 0.3).repeatCount(9, autoreverses: true)) {
            coinScale = 1.18
        }
        withAnimation(.linear(duration: 3.0)) {
            animatedBalance = Double(coinBalance)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) {
            SoundManager.shared.stopCoinJangle()
            SoundManager.shared.playPawnReachedHomeSound()
            withAnimation(.easeInOut(duration: 0.2)) {
                revealPawns = true
            }
        }
    }
}
