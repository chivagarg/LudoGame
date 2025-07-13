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
    @State private var displayText: String = "+10"
    @State private var textColor: Color = .orange

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
            confettiTrigger += 1
            if let colorEnum = (notification.userInfo?["color"]) as? PlayerColor {
                textColor = colorEnum.color
            } else if let raw = (notification.userInfo?["color"]) as? String, let colorEnum = PlayerColor(rawValue: raw) {
                textColor = colorEnum.color
            } else {
                textColor = .orange
            }
            withAnimation(.easeInOut) {
                flashText = true
            }
            // hide after 2 sec
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut) {
                    flashText = false
                }
            }
        }
    }
} 
