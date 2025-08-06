import SwiftUI
#if canImport(ConfettiSwiftUI)
import ConfettiSwiftUI
#endif

struct GameOverView: View {
    @EnvironmentObject var game: LudoGame
    @Binding var selectedPlayers: Set<PlayerColor>
    
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
    
    var body: some View {
        let winner = game.finalRankings.first ?? .red

        let _ = {
            GameLogger.shared.log("🎲 AVERAGE ROLLS: \(averageRolls)", level: .debug)
            GameLogger.shared.log("🎲 UNLUCKY WINNERS: \(unluckyWinners)", level: .debug)
        }()

        VStack(spacing: 24) {
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
                    Image("pawn_\(winner.rawValue)_marble_filled")
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
                            Image("pawn_\(color.rawValue)_marble_filled")
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
        .onAppear {
            setupAnimatedScores()
            confettiTrigger += 1
            trophyBounce = true
            startKillBonusAnimation()
        }
    }
    
    // Initialize animated score dictionary with pre-bonus values
    private func setupAnimatedScores() {
        for color in game.finalRankings {
            let base = game.scores[color] ?? 0
            animatedScores[color] = base  // start without bonuses; we will animate them in
        }
    }

    // Increment scores for winners one point at a time
    private func startKillBonusAnimation() {
        let allBonusPlayers = Set(killBonusWinners).union(unluckyWinners)
        for color in allBonusPlayers {
            let base = game.scores[color] ?? 0
            var bonus = 0
            if killBonusWinners.contains(color) { bonus += 5 }
            if unluckyWinners.contains(color) { bonus += 5 }
            let target = base + bonus
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
} 
