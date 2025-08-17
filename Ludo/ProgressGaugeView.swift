import SwiftUI

struct ProgressGaugeView: View {
    let currentValue: Int
    let maxValue: Int
    let nextUnlockablePawn: String?
    private let gridSize: CGFloat = 50
    private let rewardGridSize: CGFloat = 60

    @State private var animatedProgress: Int
    @State private var isBouncing = false

    init(currentValue: Int, maxValue: Int, nextUnlockablePawn: String?) {
        self.currentValue = currentValue
        self.maxValue = maxValue
        self.nextUnlockablePawn = nextUnlockablePawn
        // Start animation from previous cell, or 0 if it's the first
        _animatedProgress = State(initialValue: max(0, currentValue - 1))
    }

    var body: some View {
        HStack(spacing: 2) {
            // Progress cells
            ForEach(0..<maxValue, id: \.self) { i in
                ZStack {
                    Rectangle()
                        .fill(PlayerColor.blue.primaryColor.opacity(0.4))
                        .frame(width: gridSize, height: gridSize)
                        .border(Color.white.opacity(0.5), width: 1)
                    
                    if i == animatedProgress {
                        Image("pawn_blue_marble_filled")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: gridSize * 0.8, height: gridSize * 0.8)
                            .shadow(radius: 3)
                    }
                }
            }
            
            // Final reward cell
            if let pawn = nextUnlockablePawn {
                Image(pawn)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: rewardGridSize * 0.8, height: rewardGridSize * 0.8)
                    .shadow(radius: 3)
                    .offset(y: isBouncing ? -10 : 0)
            }
        }
        .onAppear {
            // Animate to the final position
            withAnimation(.easeInOut(duration: 1.2)) {
                animatedProgress = currentValue
            }
            // Bouncing animation for the reward pawn
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                isBouncing = true
            }
        }
        .onChange(of: currentValue) { newValue in
            // Animate when value changes from outside
            animatedProgress = max(0, newValue - 1)
            withAnimation(.easeInOut(duration: 1.2)) {
                animatedProgress = newValue
            }
        }
    }
}

#Preview {
    ProgressGaugeView(currentValue: 3, maxValue: 10, nextUnlockablePawn: "pawn_mango")
        .padding()
        .background(Color.gray)
}
