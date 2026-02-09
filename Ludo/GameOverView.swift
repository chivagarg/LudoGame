import SwiftUI
#if canImport(ConfettiSwiftUI)
import ConfettiSwiftUI
#endif

struct GameOverView: View {
    @EnvironmentObject var game: LudoGame
    @Binding var selectedPlayers: Set<PlayerColor>
    var onExitGame: () -> Void
    
    @State private var confettiTrigger: Int = 0
    @State private var trophyBounce: Bool = false
    @State private var animatedScores: [PlayerColor: Int] = [:]
    
    // Determine kill-bonus winners once
    private var killBonusWinners: [PlayerColor] {
        let maxKills = game.killCounts.values.max() ?? 0
        return game.killCounts.filter { $0.value == maxKills && maxKills > 0 }.map { $0.key }
    }

    // Average roll per player (one decimal)
    private var averageRolls: [PlayerColor: Double] {
        Dictionary(uniqueKeysWithValues: game.diceRollHistory.map { (key, rolls) in
            guard !rolls.isEmpty else { return (key, 0.0) }
            let avg = Double(rolls.reduce(0,+)) / Double(rolls.count)
            return (key, avg)
        })
    }

    // Players with lowest average roll (unluckiest)
    private var unluckyWinners: [PlayerColor] {
        let valid = averageRolls.filter { $0.value > 0 }
        let minAvg = valid.values.min() ?? 0
        return valid.filter { abs($0.value - minAvg) < 0.0001 }.map { $0.key }
    }
    
    @State private var bubbles = false

    // Bonus celebration queue
    @State private var bonusQueue: [(PlayerColor, String, String)] = [] // (color,label,points)
    @State private var currentBonus: (PlayerColor, String, String)? = nil
    @State private var showBonus: Bool = false

    // Confetti triggers for bonus celebration
    @State private var skullBonusConfetti: Int = 0
    @State private var unluckyConfetti: Int = 0
    @State private var unlockedPawnConfetti: Int = 0
    
    // Unlock celebration
    @State private var newlyUnlockedPawn: String? = nil
    @State private var showUnlockCelebration: Bool = false

    var body: some View {
        let winner = game.finalRankings.first ?? .red

        let _ = {
            GameLogger.shared.log("🎲 AVERAGE ROLLS: \(averageRolls)", level: .debug)
            GameLogger.shared.log("🎲 UNLUCKY WINNERS: \(unluckyWinners)", level: .debug)
        }()

        ZStack {
            BubbleBackground(animate: $bubbles)

            VStack(spacing: 30) {
                // Rainbow headline
                HStack(spacing: 0) {
                    let title = Array("GAME OVER")
                    let palette: [Color] = [.red, .green, .yellow, .blue]
                    ForEach(title.indices, id: \ .self) { idx in
                        let ch = String(title[idx])
                        ZStack {
                            // outline
                            let outlineOffsets = [(-3,-3),(3,3),(-3,3),(3,-3)]
                            ForEach(0..<outlineOffsets.count, id: \ .self) { k in
                                let off = outlineOffsets[k]
                                Text(ch)
                                    .font(.system(size: 60, weight: .heavy))
                                    .foregroundColor(.black)
                                    .offset(x: CGFloat(off.0), y: CGFloat(off.1))
                            }
                            Text(ch).font(.system(size: 60, weight: .heavy)).foregroundColor(palette[idx % palette.count])
                        }
                    }
                }

                // Existing content
                content
            }

            // Bonus celebration overlay
            if let bonus = currentBonus, showBonus {
                HStack(spacing: 12) {
                    Image(game.selectedAvatar(for: bonus.0))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                    Text("\(bonus.1) \(bonus.2)")
                        .font(.system(size: 40, weight: .heavy))
                        .foregroundColor(.white)
                        .shadow(radius: 4)
                }
                .padding(20)
                .background(Color.black.opacity(0.7))
                .cornerRadius(20)
                .transition(.scale)
            }
            
            // Unlock celebration overlay
            if let pawn = newlyUnlockedPawn, showUnlockCelebration {
                VStack {
                    Text("UNLOCKED!!")
                        .font(.system(size: 60, weight: .heavy))
                        .foregroundColor(.yellow)
                        .shadow(radius: 5)
                    Image(pawn)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .shadow(radius: 5)
                }
                .padding(30)
                .background(Color.black.opacity(0.8))
                .cornerRadius(25)
                .transition(.scale.animation(.spring(response: 0.4, dampingFraction: 0.6)))
            }
        }
        .padding()
#if canImport(ConfettiSwiftUI)
        .confettiCannon(trigger: $confettiTrigger,
                        num: 100,
                        colors: [.red, .green, .yellow, .blue, .purple, .orange],
                        confettiSize: 12,
                        repetitions: 3,
                        repetitionInterval: 0.5)
#endif
        // Bonus skull confetti
        .confettiCannon(trigger: $skullBonusConfetti,
                        num: 40,
                        confettis: [.text("💀")],
                        colors: [.black],
                        confettiSize: 20,
                        radius: 250)
        // Unlucky confetti (stars)
        .confettiCannon(trigger: $unluckyConfetti,
                        num: 40,
                        confettis: [.text("⭐️")],
                        colors: [.yellow, .orange],
                        confettiSize: 18,
                        radius: 250)
        // Unlocked confetti (stars)
        .confettiCannon(trigger: $unlockedPawnConfetti,
                        num: 80,
                        confettis: [.text("🌟")],
                        colors: [.yellow, .white, .orange],
                        confettiSize: 24,
                        radius: 400)
        .onAppear {
            /*
            GameStats.incrementGameCompletionCount()
            let unlocked = UnlockManager.checkForUnlocks()
            if let firstUnlocked = unlocked.first {
                self.newlyUnlockedPawn = firstUnlocked
            }
            */
            bubbles = true
            applyBonusesOnce()
            setupAnimatedScores()
            confettiTrigger += 1
            trophyBounce = true
            startKillBonusAnimation()
            SoundManager.shared.playYeah()

            // Build bonus queue
            var queue: [(PlayerColor,String,String)] = []
            for c in unluckyWinners { queue.append((c, "UNLUCKIEST", "+5")) }
            for c in killBonusWinners { queue.append((c, "TOP KILLS", "+5")) }
            bonusQueue = queue
            showNextBonus()
        }
    }

    // Extract existing main VStack into computed property for clarity
    private var content: some View {
        let winner = game.finalRankings.first ?? .red
        return VStack(spacing: 24) {
            // Winner section
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    // Bouncing trophy
                    Image(systemName: "trophy.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.yellow)
                        .offset(y: trophyBounce ? -10 : 0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: trophyBounce)
                    // Winning pawn image (marble style)
                    Image(game.selectedAvatar(for: winner))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .shadow(radius: 4)
                }
                Text("Winner!")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundColor(winner.color)
            }
            .padding(.top)
            
            // Scoreboard
            VStack(spacing: 12) {
                ForEach(Array(game.finalRankings.enumerated()), id: \.element) { index, color in
                    let isKillBonus = killBonusWinners.contains(color)
                    let isFirstKill = (game.firstKillPlayer == color)
                    let isUnlucky = unluckyWinners.contains(color)
                    let finalScore = (game.scores[color] ?? 0) // bonuses will be animated in
                    let displayScore = animatedScores[color, default: finalScore]
                    HStack {
                        Text("\(index + 1)")
                            .font(.title2)
                            .frame(width: 30, alignment: .leading)
                        
                        VStack(spacing:2) {
                            Image(game.selectedAvatar(for: color))
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                            Text("Avg Roll: \(averageRolls[color] ?? 0, specifier: "%.1f")")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(color.color)
                        }
                        .frame(minWidth: 80, alignment: .leading)
                        Spacer()
                        HStack(spacing:4) {
                            if isKillBonus {
                                badgeView(label: "TOP KILLS", icon: "skull_cute", bonus: "+5", color: .red)
                            }
                            if isFirstKill {
                                badgeView(label: "FIRST KILL", icon: "skull_cute", bonus: "+3", color: .black)
                            }
                            if isUnlucky {
                                badgeView(label: "UNLUCKIEST", icon: "skull_cute", bonus: "+5", color: .blue)
                            }
                        }
                        Text("\(displayScore) pts")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(color.color)
                    }
                    .padding()
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color == winner ? color.color : Color.clear, lineWidth: 3)
                    )
                    .cornerRadius(12)
                    .shadow(radius: 3)
                }
            }
            .padding()
            
            Button(action: {
                game.startGame(selectedPlayers: selectedPlayers, aiPlayers: game.aiControlledPlayers, mode: game.gameMode)
            }) {
                Text("Play Again")
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(PlayerColor.blue.primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            Button(action: onExitGame) {
                Text("Exit Game")
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
    }

    // MARK: - Bonus application
    @State private var didApplyBonuses: Bool = false

    private func applyBonusesOnce() {
        guard !didApplyBonuses else { return }
        didApplyBonuses = true

        // Persist bonuses into game.scores
        for c in killBonusWinners { game.scores[c, default:0] += 5 }
        for c in unluckyWinners { game.scores[c, default:0] += 5 }

        // Recompute rankings based on updated scores
        game.finalRankings = game.scores.keys.sorted { (game.scores[$0] ?? 0) > (game.scores[$1] ?? 0) }
    }

    // Initialize animated score dictionary with pre-bonus values
    private func setupAnimatedScores() {
        for color in game.finalRankings {
            let base = game.scores[color] ?? 0
            var start = base
            var bonus = 0
            if killBonusWinners.contains(color) { bonus += 5 }
            if unluckyWinners.contains(color) { bonus += 5 }
            start -= bonus

            GameLogger.shared.log("🏁 Setup animated score for \(color.rawValue). base=\(base) bonus=\(bonus) start=\(start)", level: .debug)

            animatedScores[color] = max(0,start)
        }
    }

    // Increment scores for winners one point at a time
    private func startKillBonusAnimation() {
        let allBonusPlayers = Set(killBonusWinners).union(unluckyWinners)
        for color in allBonusPlayers {
            let target = game.scores[color] ?? 0
            incrementScore(for: color, to: target)
        }
    }

    private func incrementScore(for color: PlayerColor, to target: Int) {
        guard var current = animatedScores[color], current < target else { return }
        // Schedule increments
        for step in 1...5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * 0.5) {
                animatedScores[color, default: current] += 1
            }
        }
    }

    @ViewBuilder
    private func badgeView(label: String, icon: String, bonus: String, color: Color, system: Bool = false) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .fontWeight(.heavy)
                .foregroundColor(color)
                .rotationEffect(.degrees(-10))
            (system ? Image(systemName: icon) : Image(icon))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
            Text(bonus)
                .foregroundColor(.black)
        }
        .padding(.trailing,6)
    }

    // MARK: Bonus overlay sequence
    private func showNextBonus() {
        guard !showBonus, !bonusQueue.isEmpty else {
            // All bonuses shown, check for unlocks
            if newlyUnlockedPawn != nil {
                startUnlockCelebration()
            }
            return
        }
        currentBonus = bonusQueue.removeFirst()
        // Trigger confetti based on type
        if currentBonus?.1 == "TOP KILLS" {
            skullBonusConfetti += 1
        } else if currentBonus?.1 == "UNLUCKIEST" {
            unluckyConfetti += 1
        }
        withAnimation { showBonus = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { showBonus = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { showNextBonus() }
        }
    }
    
    private func startUnlockCelebration() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            unlockedPawnConfetti += 1
            withAnimation {
                showUnlockCelebration = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                withAnimation {
                    showUnlockCelebration = false
                }
            }
        }
    }
} 
