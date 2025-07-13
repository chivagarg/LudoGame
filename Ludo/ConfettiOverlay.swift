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
    @State private var confettiTrigger: Int = 0
    @State private var flashText: Bool = false
    @State private var displayText: String = ""
    @State private var textColor: Color = .orange
    @State private var messageQueue: [(String, Color)] = []

    var body: some View {
        ZStack {
            if flashText {
                StrokeText(text: displayText,
                           size: 60,
                           weight: .heavy,
                           strokeColor: .white,
                           textColor: textColor,
                           strokeWidth: 2)
                    .scaleEffect(flashText ? 1.2 : 1.0)
                    .transition(.scale)
            }
        }
#if canImport(ConfettiSwiftUI)
        .confettiCannon(trigger: $confettiTrigger,
                        num: 40,
                        colors: [.red, .green, .yellow, .blue])
#endif
        .allowsHitTesting(false)
        .onReceive(NotificationCenter.default.publisher(for: .pawnReachedHome)) { notification in
            enqueueMessage(basePoints: 10, notification: notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: .playerFinished)) { notification in
            if let bonus = notification.userInfo?["bonus"] as? Int {
                enqueueMessage(basePoints: bonus, notification: notification)
            }
        }
    }

    // MARK: - Helper Functions

    private func enqueueMessage(basePoints points: Int, notification: Notification) {
        // Determine color
        var color: Color = .orange
        if let colorEnum = (notification.userInfo?["color"]) as? PlayerColor {
            color = colorEnum.color
        } else if let raw = (notification.userInfo?["color"]) as? String,
                  let colorEnum = PlayerColor(rawValue: raw) {
            color = colorEnum.color
        }

        // Add message to queue
        messageQueue.append(("+\(points)", color))

        // If not currently showing text, show next
        if !flashText {
            showNextMessage()
        }
    }

    private func showNextMessage() {
        guard !messageQueue.isEmpty else { return }
        let (msg, color) = messageQueue.removeFirst()
        displayText = msg
        textColor = color
        confettiTrigger += 1

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
} 
