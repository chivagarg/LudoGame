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
    
    var body: some View {
        let winner = game.finalRankings.first ?? .red
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
                    let finalScore = (game.scores[color] ?? 0)
                    let displayScore = animatedScores[color, default: finalScore]
                    HStack {
                        Text("\(index + 1)")
                            .font(.title2)
                            .frame(width: 30, alignment: .leading)
                        
                        Image("pawn_\(color.rawValue)_marble_filled")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                        Spacer()
                        HStack(spacing:4) {
                            if isKillBonus {
                                badgeView(label: "TOP KILLS", icon: "skull_cute", bonus: "+5", color: .red)
                            }
                            if isFirstKill {
                                badgeView(label: "FIRST KILL", icon: "skull_cute", bonus: "+3", color: .black)
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
            if killBonusWinners.contains(color) {
                animatedScores[color] = max(0, base - 5)
            } else {
                animatedScores[color] = base
            }
        }
    }

    // Increment scores for winners one point at a time
    private func startKillBonusAnimation() {
        for color in killBonusWinners {
            let target = (game.scores[color] ?? 0) // this already includes bonus
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
    private func badgeView(label: String, icon: String, bonus: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .fontWeight(.heavy)
                .foregroundColor(color)
                .rotationEffect(.degrees(-10))
            Image(icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
            Text(bonus)
                .foregroundColor(.black)
        }
        .padding(.trailing,6)
    }
} 
