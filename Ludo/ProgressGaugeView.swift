import SwiftUI

struct ProgressGaugeView: View {
    let currentValue: Int
    let maxValue: Int
    private let gridSize: CGFloat = 40

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0...maxValue, id: \.self) { i in
                ZStack {
                    Rectangle()
                        .fill(PlayerColor.blue.primaryColor.opacity(0.4))
                        .frame(width: gridSize, height: gridSize)
                        .border(Color.white.opacity(0.5), width: 1)
                    
                    if i == currentValue {
                        Image("pawn_blue_marble_filled")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: gridSize * 0.8, height: gridSize * 0.8)
                            .shadow(radius: 3)
                    }
                }
            }
        }
    }
}

#Preview {
    ProgressGaugeView(currentValue: 0, maxValue: 10)
        .padding()
        .background(Color.gray)
}
