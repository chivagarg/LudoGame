import SwiftUI

struct StartGameView: View {
    @EnvironmentObject private var game: LudoGame
    @Binding var isAdminMode: Bool
    @Binding var selectedPlayers: Set<PlayerColor>
    @Binding var aiPlayers: Set<PlayerColor>
    @Binding var selectedMode: GameMode
    let onStartGame: () -> Void

    @State private var step: Int = 0 // 0 = homepage, 1 = player selection (v2)
    @State private var showSettings: Bool = false
    @State private var showClaimSuccessModal: Bool = false
    @State private var recentlyClaimedPack: PawnPack? = nil
    @State private var unlockModalQueue: [PawnPack] = []

    @State private var purchaseTargetPack: PawnPack? = nil
    @State private var showPurchaseModal: Bool = false
    @State private var showPurchaseRevealModal: Bool = false
    @State private var purchaseRevealPack: PawnPack? = nil
    @State private var purchaseRevealBalance: Int = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(red: 249/255, green: 247/255, blue: 252/255).ignoresSafeArea()

                if step == 0 {
                    homepageContent(in: geo)
                    .transition(.opacity)
                } else if step == 1 {
                    PlayerSelectionViewV2(isAdminMode: $isAdminMode,
                                          selectedPlayers: $selectedPlayers,
                                          aiPlayers: $aiPlayers,
                                          onStart: onStartGame,
                                          onBack: { withAnimation { step = 0 } })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .transition(.opacity)
                }
            }

            if showClaimSuccessModal, let pack = recentlyClaimedPack {
                PackUnlockModal(
                    pack: pack,
                    unlockCost: pack.coinCost,
                    coinBalance: game.coins,
                    onDismiss: { dismissAndAdvanceUnlockModal() },
                    onPlayNow: {
                        unlockModalQueue.removeAll()
                        withAnimation(.easeOut(duration: 0.2)) { showClaimSuccessModal = false }
                        selectedMode = .mirchi
                        withAnimation { step = 1 }
                    }
                )
                .zIndex(200)
            }

            if showPurchaseModal, let pack = purchaseTargetPack {
                CoinPurchaseModal(
                    pack: pack,
                    currentCoinBalance: game.coins,
                    onDismiss: {
                        withAnimation(.easeOut(duration: 0.2)) { showPurchaseModal = false }
                    },
                    onPurchaseComplete: {
                        withAnimation(.easeOut(duration: 0.2)) { showPurchaseModal = false }
                        purchaseRevealPack = pack
                        purchaseRevealBalance = game.coins
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                                showPurchaseRevealModal = true
                            }
                        }
                    }
                )
                .zIndex(210)
            }

            if showPurchaseRevealModal, let pack = purchaseRevealPack {
                PackUnlockModal(
                    pack: pack,
                    unlockCost: 0,
                    coinBalance: purchaseRevealBalance,
                    skipCashout: true,
                    onDismiss: {
                        withAnimation(.easeOut(duration: 0.2)) { showPurchaseRevealModal = false }
                    },
                    onPlayNow: {
                        withAnimation(.easeOut(duration: 0.2)) { showPurchaseRevealModal = false }
                        selectedMode = .mirchi
                        withAnimation { step = 1 }
                    }
                )
                .zIndex(220)
            }
        }
        .sheet(isPresented: $showSettings) {
            if #available(iOS 16.0, *) {
                SettingsTableView(isAdminMode: $isAdminMode)
                    .presentationDetents([.medium])
            } else {
                SettingsTableView(isAdminMode: $isAdminMode)
            }
        }
        .onAppear {
            autoClaimEligiblePacksIfNeeded()
        }
        .onChange(of: step) { newStep in
            if newStep == 0 {
                autoClaimEligiblePacksIfNeeded()
            }
        }
    }

    @ViewBuilder
    private func homepageContent(in geo: GeometryProxy) -> some View {
        let topBarIconSize = min(max(24, geo.size.width * 0.045), 34)
        let topBarPadding = min(max(8, geo.size.width * 0.018), 12)
        let topBarCornerRadius = min(max(10, geo.size.width * 0.02), 14)
        let horizontalMargin = geo.size.width < 900 ? 16.0 : 24.0
        let topSpacer = max(10.0, geo.size.height * 0.018)
        let contentWidth = min(geo.size.width - (horizontalMargin * 2), 1180)

        VStack(spacing: 0) {
            HStack {
                Spacer()
                HStack(spacing: 10) {
                    coinBalancePill(iconSize: topBarIconSize, padding: topBarPadding, cornerRadius: topBarCornerRadius)
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: topBarIconSize, weight: .regular))
                            .foregroundColor(.gray)
                            .padding(topBarPadding)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
            }
            .padding(.horizontal, horizontalMargin)
            .padding(.top, 16)

            Spacer(minLength: topSpacer)
                .frame(height: topSpacer)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    heroCard(in: geo, cardWidth: contentWidth)
                    unlockProgressSection
                        .frame(width: contentWidth, alignment: .leading)
                }
                .frame(width: contentWidth, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, horizontalMargin)
                .padding(.bottom, max(24, geo.safeAreaInsets.bottom + 10))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func heroCard(in geo: GeometryProxy, cardWidth: CGFloat) -> some View {
        let isCompact = geo.size.width < 900
        let sidePadding = max(20.0, cardWidth * 0.08)
        let contentScale = max(0.62, min(1.0, cardWidth / 760.0))
        let heroTitleSize = min(max(24, cardWidth * 0.07), 56)

        Image("homepage-v0")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .overlay(
                HStack {
                    VStack(alignment: .leading, spacing: isCompact ? 8 : 10) {
                        Text(GameCopy.StartGame.heroKicker)
                            .font(isCompact ? .headline : .title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)

                        Text(GameCopy.StartGame.heroTitle)
                            .font(.system(size: heroTitleSize, weight: .black))
                            .foregroundColor(.black)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)

                        Text(GameCopy.StartGame.heroDescription)
                            .font(isCompact ? .callout : .body)
                            .foregroundColor(.black.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 12)

                        MirchiPrimaryButton(title: "Play now!") {
                            selectedMode = .mirchi
                            withAnimation { step = 1 }
                        }
                    }
                    .scaleEffect(contentScale, anchor: .leading)
                    .frame(maxWidth: cardWidth * 0.46, alignment: .leading)
                    .padding(.leading, sidePadding)
                    .padding(.vertical, isCompact ? 16 : 24)

                    Spacer()
                }
            )
            .frame(width: cardWidth)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private var unlockProgressSection: some View {
        let upcoming = UnlockManager.getUpcomingIncompletePacks(limit: 3)
        if let immediate = upcoming.first {
            let progress = UnlockManager.progressTowardNextClaim(for: game.coins)
            let progressFraction = min(1.0, CGFloat(progress.current) / CGFloat(max(1, progress.target)))

            VStack(alignment: .leading, spacing: 12) {
                Text(GameCopy.StartGame.unlockProgressTitle)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)

                let progressLine = "\(formattedCoin(progress.current))/\(formattedCoin(progress.target)) coins to unlock this pack for free!"
                unlockPackCard(pack: immediate, showProgress: true, progressText: progressLine, progressFraction: progressFraction)

                let nextTwo = Array(upcoming.dropFirst().prefix(2))
                if !nextTwo.isEmpty {
                    Text(GameCopy.StartGame.nextUp)
                        .font(.system(size: 30, weight: .regular))
                        .foregroundColor(.black.opacity(0.9))
                        .padding(.top, 4)

                    ForEach(nextTwo) { pack in
                        unlockPackCard(pack: pack, showProgress: false, progressText: nil, progressFraction: 0)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func unlockPackCard(pack: PawnPack, showProgress: Bool, progressText: String?, progressFraction: CGFloat) -> some View {
        let coinCost = pack.coinCost

        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 62, height: 62)
                    .overlay(
                        RotatingPackPawnPreview(pack: pack)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(pack.displayName)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Image("coin")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)

                        Text(formattedCoin(coinCost))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black.opacity(0.8))
                    }

                    Text(packMembersLine(pack))
                        .boostDescriptionTextStyle()
                        .foregroundColor(.black.opacity(0.75))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 10)

                Button(GameCopy.Common.unlockNow) {
                    purchaseTargetPack = pack
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                        showPurchaseModal = true
                    }
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 0x7C/255, green: 0x5C/255, blue: 0xD6/255))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red: 0x8D/255, green: 0x74/255, blue: 0xD9/255), lineWidth: 1.2)
                        )
                )
            }

            if showProgress, let progressText {
                Text(GameCopy.StartGame.almostThere(progressText))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.top, 2)

                GeometryReader { proxy in
                    let width = proxy.size.width
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.25))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green.opacity(0.85))
                            .frame(width: max(0, min(width, width * progressFraction)), height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.72))
        )
    }

    private func packMembersLine(_ pack: PawnPack) -> String {
        pack.pawnAssetNames.map { PawnCatalog.details(for: $0).title }.joined(separator: " · ")
    }

    private func autoClaimEligiblePacksIfNeeded() {
        guard step == 0 else { return }
        var claimedThisPass: [PawnPack] = []
        while UnlockManager.canClaimNextPack(for: game.coins) {
            guard let claimedPack = UnlockManager.claimNextUnlockablePack() else { break }
            claimedThisPass.append(claimedPack)
            game.coins = UnlockManager.getCoinBalance()
        }

        guard !claimedThisPass.isEmpty else { return }
        unlockModalQueue.append(contentsOf: claimedThisPass)
        if !showClaimSuccessModal {
            showNextUnlockModalIfNeeded()
        }
    }

    private func showNextUnlockModalIfNeeded() {
        guard !unlockModalQueue.isEmpty else {
            recentlyClaimedPack = nil
            return
        }
        recentlyClaimedPack = unlockModalQueue.removeFirst()
        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
            showClaimSuccessModal = true
        }
    }

    private func dismissAndAdvanceUnlockModal() {
        withAnimation(.easeOut(duration: 0.2)) {
            showClaimSuccessModal = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            showNextUnlockModalIfNeeded()
        }
    }

    private func formattedCoin(_ value: Int) -> String {
        NumberFormatter.localizedString(from: NSNumber(value: max(0, value)), number: .decimal)
    }

    @ViewBuilder
    private func coinBalancePill(iconSize: CGFloat, padding: CGFloat, cornerRadius: CGFloat) -> some View {
        HStack(spacing: 8) {
            Image("coin")
                .resizable()
                .scaledToFit()
                .frame(width: iconSize * 0.95, height: iconSize * 0.95)

            Text("\(game.coins)")
                .font(.system(size: max(14, iconSize * 0.72), weight: .semibold))
                .foregroundColor(.black.opacity(0.85))
                .lineLimit(1)
        }
        .padding(.vertical, max(6, padding * 0.55))
        .padding(.horizontal, max(10, padding * 0.95))
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
