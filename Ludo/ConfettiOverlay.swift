import SwiftUI
#if canImport(ConfettiSwiftUI)
import ConfettiSwiftUI // https://github.com/simibac/ConfettiSwiftUI
#endif

struct StrokeText: View {
    let text: String
    let size: CGFloat
    let weight: Font.Weight
    let strokeColor: Color
    let textColor: Color
    let strokeWidth: CGFloat

    var body: some View {
        ZStack {
            // 4-way outline
            Text(text)
                .font(.system(size: size, weight: weight))
                .foregroundColor(strokeColor)
                .offset(x: strokeWidth, y: strokeWidth)
            Text(text)
                .font(.system(size: size, weight: weight))
                .foregroundColor(strokeColor)
                .offset(x: -strokeWidth, y: -strokeWidth)
            Text(text)
                .font(.system(size: size, weight: weight))
                .foregroundColor(strokeColor)
                .offset(x: -strokeWidth, y: strokeWidth)
            Text(text)
                .font(.system(size: size, weight: weight))
                .foregroundColor(strokeColor)
                .offset(x: strokeWidth, y: -strokeWidth)
            // Center fill
            Text(text)
                .font(.system(size: size, weight: weight))
                .foregroundColor(textColor)
        }
    }
}


struct ConfettiOverlay: View {
    @State private var confettiTrigger: Int = 0            // regular +10 confetti
    @State private var finishConfettiTrigger: Int = 0      // bigger fireworks for game completion
    @State private var mirchiConfettiTrigger: Int = 0      // chile confetti when backward capture
    @State private var firstBloodConfettiTrigger: Int = 0   // skull confetti for first blood
    @State private var confettiQueue: [() -> Void] = []
    @State private var confettiActive: Bool = false
    @State private var flashText: Bool = false
    @State private var displayText: String = ""
    @State private var textColor: Color = .orange
    @State private var textSize: CGFloat = 60
    @State private var messageQueue: [(String, Color, Bool)] = [] // (text,color,shouldSmallConfetti)

    var body: some View {
        ZStack {
            if flashText {
                StrokeText(text: displayText,
                           size: textSize,
                           weight: .heavy,
                           strokeColor: .white,
                           textColor: textColor,
                           strokeWidth: 2)
                    .scaleEffect(flashText ? 1.2 : 1.0)
                    .transition(.scale)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
#if canImport(ConfettiSwiftUI)
        // Standard confetti for each pawn reaching home
        .confettiCannon(trigger: $confettiTrigger,
                        num: 40,
                        colors: [.red, .green, .yellow, .blue])
        // Extra-special fireworks when a player finishes the game
        .confettiCannon(trigger: $finishConfettiTrigger,
                        num: 60,
                        confettis: [.shape(.circle), .shape(.triangle), .shape(.square), .shape(.roundedCross), .text("⭐️"), .text("🎉")],
                        colors: [.yellow, .red, .green, .blue, .purple, .orange],
                        confettiSize: 14,
                        openingAngle: .degrees(0),
                        closingAngle: .degrees(360),
                        radius: 350,
                        hapticFeedback: true)
        // Mirchi confetti for backward captures
        .confettiCannon(trigger: $mirchiConfettiTrigger,
                        num: 45,
                        confettis: [.text("🌶️")],
                        colors: [.red, .orange],
                        confettiSize: 20,
                        openingAngle: .degrees(0),
                        closingAngle: .degrees(360),
                        radius: 300)
        // First blood skull confetti
        .confettiCannon(trigger: $firstBloodConfettiTrigger,
                        num: 50,
                        confettis: [.text("💀")],
                        colors: [.black, .gray],
                        confettiSize: 28,
                        openingAngle: .degrees(0),
                        closingAngle: .degrees(360),
                        radius: 300)
#endif
        .allowsHitTesting(false)
        .onReceive(NotificationCenter.default.publisher(for: .pawnReachedHome)) { notification in
            let completed = notification.userInfo?["completed"] as? Bool ?? false
            let useSmall = !completed // small confetti only if not completed
            enqueueMessage(basePoints: 10, notification: notification, smallConfetti: useSmall)
            if completed {
                finishConfettiTrigger += 1 // launch fireworks once
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .playerFinished)) { notification in
            if let bonus = notification.userInfo?["bonus"] as? Int {
                 enqueueMessage(basePoints: bonus, notification: notification, smallConfetti: false)
                 // Fireworks already triggered on pawnReachedHome when completed, so do not increment again
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .firstBlood)) { notification in
            GameLogger.shared.log("💀 DEBUG: ConfettiOverlay queued first blood", level: .debug)
            SoundManager.shared.playEvilLaugh()
            enqueueConfetti { firstBloodConfettiTrigger += 1 }

            // Custom "First Kill +3" message
            var color: Color = .orange
            if let raw = notification.userInfo?["color"] as? String,
               let colorEnum = PlayerColor(rawValue: raw) {
                color = colorEnum.color
            }
            messageQueue.append(("FIRST KILL +3", color, false))
            if !flashText { showNextMessage() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .mirchiBackwardCapture)) { _ in
            GameLogger.shared.log("🌶️ DEBUG: ConfettiOverlay received mirchiBackwardCapture", level: .debug)
            enqueueConfetti { mirchiConfettiTrigger += 1 }
        }
    }

    // MARK: - Helper Functions

    private func enqueueMessage(basePoints points: Int, notification: Notification, smallConfetti: Bool = true) {
        // Determine color
        var color: Color = .orange
        if let colorEnum = (notification.userInfo?["color"]) as? PlayerColor {
            color = colorEnum.color
        } else if let raw = (notification.userInfo?["color"]) as? String,
                  let colorEnum = PlayerColor(rawValue: raw) {
            color = colorEnum.color
        }

        // Add message to queue
        messageQueue.append(("+\(points)", color, smallConfetti))

        // If not currently showing text, show next
        if !flashText {
            showNextMessage()
        }
    }

    private func showNextMessage() {
        guard !messageQueue.isEmpty else { return }
        let (msg, color, smallConfetti) = messageQueue.removeFirst()
        displayText = msg
        textColor = color
        textSize = msg.hasPrefix("FIRST KILL") ? 40 : 60
        if smallConfetti {
            confettiTrigger += 1  // regular burst per message
        }

        withAnimation(.easeInOut) {
            flashText = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut) {
                flashText = false
            }
            // After hide animation, show next if available
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.showNextMessage()
            }
        }
    }

    // MARK: - Confetti Queue Helper

    private func enqueueConfetti(action: @escaping () -> Void) {
        confettiQueue.append(action)
        triggerNextConfettiIfNeeded()
    }

    private func triggerNextConfettiIfNeeded() {
        guard !confettiActive, !confettiQueue.isEmpty else { return }
        confettiActive = true
        let action = confettiQueue.removeFirst()
        action()
        // Assume confetti lasts ~2s
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            confettiActive = false
            triggerNextConfettiIfNeeded()
        }
    }
} 
