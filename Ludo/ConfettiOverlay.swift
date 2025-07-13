import SwiftUI
#if canImport(ConfettiSwiftUI)
import ConfettiSwiftUI // https://github.com/simibac/ConfettiSwiftUI
#endif

struct ConfettiOverlay: View {
    @State private var confettiTrigger: Int = 0
    @State private var flashText: Bool = false
    @State private var displayText: String = "+10"

    var body: some View {
        ZStack {
            if flashText {
                Text(displayText)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.orange)
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
        .onReceive(NotificationCenter.default.publisher(for: .pawnReachedHome)) { _ in
            confettiTrigger += 1
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
