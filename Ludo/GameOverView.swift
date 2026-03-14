import SwiftUI
#if canImport(ConfettiSwiftUI)
import ConfettiSwiftUI
#endif

struct GameOverView: View {
    @EnvironmentObject var game: LudoGame
    @Binding var selectedPlayers: Set<PlayerColor>
    var onExitGame: () -> Void

    // MARK: - Animation state (unchanged)
    @State private var confettiTrigger: Int = 0
    @State private var trophyBounce: Bool = false      // drives winner pawn float
    @State private var animatedScores: [PlayerColor: Int] = [:]
    @State private var bonusQueue: [(PlayerColor, String, String)] = []
    @State private var currentBonus: (PlayerColor, String, String)? = nil
    @State private var showBonus: Bool = false
    @State private var skullBonusConfetti: Int = 0
    @State private var unluckyConfetti: Int = 0
    @State private var animatedCoinBalance: Int = 0
    @State private var showCoinCounterAnimation: Bool = false
    @State private var didApplyBonuses: Bool = false

    // MARK: - Computed helpers (unchanged)

    private var killBonusWinners: [PlayerColor] {
        let maxKills = game.killCounts.values.max() ?? 0
        return game.killCounts.filter { $0.value == maxKills && maxKills > 0 }.map { $0.key }
    }

    private var averageRolls: [PlayerColor: Double] {
        Dictionary(uniqueKeysWithValues: game.diceRollHistory.map { (key, rolls) in
            guard !rolls.isEmpty else { return (key, 0.0) }
            let avg = Double(rolls.reduce(0, +)) / Double(rolls.count)
            return (key, avg)
        })
    }

    private var unluckyWinners: [PlayerColor] {
        let valid = averageRolls.filter { $0.value > 0 }
        let minAvg = valid.values.min() ?? 0
        return valid.filter { abs($0.value - minAvg) < 0.0001 }.map { $0.key }
    }

    // MARK: - Body

    var body: some View {
        let winner = game.finalRankings.first ?? .red

        let _ = {
            GameLogger.shared.log("🎲 AVERAGE ROLLS: \(averageRolls)", level: .debug)
            GameLogger.shared.log("🎲 UNLUCKY WINNERS: \(unluckyWinners)", level: .debug)
        }()

        GeometryReader { geo in
            ZStack {
                // Background — matches StartGameView
                Color(red: 249/255, green: 247/255, blue: 252/255)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        headlineBlock
                        winnerCard(winner: winner, geo: geo)
                        scoreboardSection
                        actionButtons
                    }
                    .frame(maxWidth: min(geo.size.width - 40, 620))
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.top, max(20, geo.safeAreaInsets.top + 16))
                    .padding(.bottom, max(28, geo.safeAreaInsets.bottom + 16))
                }

                // Bonus celebration overlay (unchanged)
                if let bonus = currentBonus, showBonus {
                    HStack(spacing: 14) {
                        Image(game.selectedAvatar(for: bonus.0))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 56)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(bonus.1)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                            Text(bonus.2)
                                .font(.system(size: 34, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.black.opacity(0.78))
                    )
                    .shadow(color: .black.opacity(0.22), radius: 14, x: 0, y: 6)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(100)
                }

                // Coin counter animation (unchanged)
                if showCoinCounterAnimation {
                    VStack(spacing: 8) {
                        HStack(spacing: 10) {
                            Image("coin")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 52, height: 52)
                            Text("\(animatedCoinBalance)")
                                .font(.system(size: 60, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.45), radius: 8, x: 0, y: 3)
                        }
                        Text(GameCopy.GameOver.coinsEarned(game.lastCoinAward))
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.black.opacity(0.74))
                    )
                    .shadow(color: .black.opacity(0.3), radius: 18, x: 0, y: 8)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(120)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        // Confetti cannons — all unchanged
#if canImport(ConfettiSwiftUI)
        .confettiCannon(trigger: $confettiTrigger,
                        num: 100,
                        colors: [.red, .green, .yellow, .blue, .purple, .orange],
                        confettiSize: 12,
                        repetitions: 3,
                        repetitionInterval: 0.5)
#endif
        .confettiCannon(trigger: $skullBonusConfetti,
                        num: 40,
                        confettis: [.text("💀")],
                        colors: [.black],
                        confettiSize: 20,
                        radius: 250)
        .confettiCannon(trigger: $unluckyConfetti,
                        num: 40,
                        confettis: [.text("⭐️")],
                        colors: [.yellow, .orange],
                        confettiSize: 18,
                        radius: 250)
        .onAppear {
            applyBonusesOnce()
            setupAnimatedScores()
            confettiTrigger += 1
            trophyBounce = true
            startKillBonusAnimation()
            SoundManager.shared.playYeah()

            var queue: [(PlayerColor, String, String)] = []
            for c in unluckyWinners { queue.append((c, "UNLUCKIEST", "+5")) }
            for c in killBonusWinners { queue.append((c, "TOP KILLS", "+5")) }
            bonusQueue = queue
            showNextBonus()
            startCoinCountAnimation()
        }
    }

    // MARK: - Sub-views

    private var headlineBlock: some View {
        VStack(spacing: 4) {
            Text(GameCopy.GameOver.title)
                .font(.custom("BeVietnamPro-Bold", size: 48))
                .foregroundColor(.black)
                .minimumScaleFactor(0.75)
                .lineLimit(1)
            Text(GameCopy.GameOver.subtitle)
                .font(.custom("Inter-Regular", size: 15))
                .foregroundColor(.black.opacity(0.45))
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private func winnerCard(winner: PlayerColor, geo: GeometryProxy) -> some View {
        VStack(spacing: 12) {
            // Winner badge pill
            Text(GameCopy.GameOver.winner)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(winner.primaryColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(winner.primaryColor.opacity(0.12))
                        .overlay(Capsule().stroke(winner.primaryColor.opacity(0.35), lineWidth: 1))
                )

            // Winner pawn — bobs up and down
            Image(game.selectedAvatar(for: winner))
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .shadow(color: winner.primaryColor.opacity(0.3), radius: 16, x: 0, y: 8)
                .offset(y: trophyBounce ? -10 : 0)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: trophyBounce)

            Text(PawnCatalog.details(for: game.selectedAvatar(for: winner)).title)
                .font(.custom("BeVietnamPro-Bold", size: 22))
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
    }

    private var scoreboardSection: some View {
        VStack(spacing: 10) {
            ForEach(Array(game.finalRankings.enumerated()), id: \.element) { index, color in
                scoreRow(rank: index + 1, color: color)
            }
        }
    }

    @ViewBuilder
    private func scoreRow(rank: Int, color: PlayerColor) -> some View {
        let winner = game.finalRankings.first ?? .red
        let isWinner = (color == winner)
        let isKillBonus = killBonusWinners.contains(color)
        let isFirstKill = (game.firstKillPlayer == color)
        let isUnlucky = unluckyWinners.contains(color)
        let finalScore = game.scores[color] ?? 0
        let displayScore = animatedScores[color, default: finalScore]

        HStack(spacing: 12) {
            // Rank number
            Text("\(rank)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.black.opacity(0.35))
                .frame(width: 22, alignment: .center)

            // Pawn + avg roll
            VStack(spacing: 3) {
                Image(game.selectedAvatar(for: color))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                Text(GameCopy.GameOver.avgRoll(averageRolls[color] ?? 0))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.black.opacity(0.4))
            }
            .frame(width: 52)

            // Player color label
            Text(color.rawValue.capitalized)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.black.opacity(0.75))

            Spacer(minLength: 4)

            // Bonus badges
            HStack(spacing: 5) {
                if isKillBonus   { bonusPill(label: "TOP KILLS",  bonus: "+5", tint: .red) }
                if isFirstKill   { bonusPill(label: "FIRST KILL", bonus: "+3", tint: Color(white: 0.2)) }
                if isUnlucky     { bonusPill(label: "UNLUCKIEST ROLLER", bonus: "+5", tint: .blue) }
            }

            // Score
            Text(GameCopy.GameOver.points(displayScore))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .frame(minWidth: 60, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
        )
        .overlay(
            // Subtle left-edge accent for winner
            HStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(isWinner ? color.primaryColor : Color.clear)
                    .frame(width: 3)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        )
        .shadow(color: .black.opacity(isWinner ? 0.1 : 0.05), radius: isWinner ? 8 : 4, x: 0, y: 2)
    }

    @ViewBuilder
    private func bonusPill(label: String, bonus: String, tint: Color) -> some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(.black)
            Text(bonus)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundColor(.black)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(tint.opacity(0.1))
                .overlay(Capsule().stroke(tint.opacity(0.3), lineWidth: 0.8))
        )
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            MirchiPrimaryButton(title: "Play Again", isFullWidth: true) {
                game.startGame(
                    selectedPlayers: selectedPlayers,
                    aiPlayers: game.aiControlledPlayers,
                    mode: game.gameMode
                )
            }

            Button(action: onExitGame) {
                Text(GameCopy.GameOver.exitGame)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0x7C/255, green: 0x5C/255, blue: 0xD6/255))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0x8D/255, green: 0x74/255, blue: 0xD9/255), lineWidth: 1.5)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.bottom, 8)
    }

    // MARK: - Logic (all unchanged)

    private func applyBonusesOnce() {
        guard !didApplyBonuses else { return }
        didApplyBonuses = true
        for c in killBonusWinners { game.scores[c, default: 0] += 5 }
        for c in unluckyWinners   { game.scores[c, default: 0] += 5 }
        game.finalRankings = game.scores.keys.sorted { (game.scores[$0] ?? 0) > (game.scores[$1] ?? 0) }
    }

    private func setupAnimatedScores() {
        for color in game.finalRankings {
            let base = game.scores[color] ?? 0
            var bonus = 0
            if killBonusWinners.contains(color) { bonus += 5 }
            if unluckyWinners.contains(color)   { bonus += 5 }
            let start = base - bonus
            GameLogger.shared.log("🏁 Setup animated score for \(color.rawValue). base=\(base) bonus=\(bonus) start=\(start)", level: .debug)
            animatedScores[color] = max(0, start)
        }
    }

    private func startKillBonusAnimation() {
        let allBonusPlayers = Set(killBonusWinners).union(unluckyWinners)
        for color in allBonusPlayers {
            let target = game.scores[color] ?? 0
            incrementScore(for: color, to: target)
        }
    }

    private func incrementScore(for color: PlayerColor, to target: Int) {
        guard let current = animatedScores[color], current < target else { return }
        for step in 1...5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * 0.5) {
                animatedScores[color, default: current] += 1
            }
        }
    }

    private func showNextBonus() {
        guard !showBonus, !bonusQueue.isEmpty else { return }
        currentBonus = bonusQueue.removeFirst()
        if currentBonus?.1 == "TOP KILLS"   { skullBonusConfetti += 1 }
        if currentBonus?.1 == "UNLUCKIEST ROLLER"  { unluckyConfetti += 1 }
        withAnimation { showBonus = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { showBonus = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { showNextBonus() }
        }
    }

    private func startCoinCountAnimation() {
        let start = max(0, game.coinBalanceBeforeLastAward)
        let end = max(start, game.coins)
        let delta = end - start
        guard delta > 0 else { return }

        animatedCoinBalance = start
        withAnimation(.spring(response: 0.26, dampingFraction: 0.78)) {
            showCoinCounterAnimation = true
        }
        for step in 1...delta {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * 0.012) {
                animatedCoinBalance = start + step
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(delta) * 0.012 + 1.0) {
            withAnimation(.easeOut(duration: 0.25)) {
                showCoinCounterAnimation = false
            }
        }
    }
}
