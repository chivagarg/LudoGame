import SwiftUI

struct ProgressGaugeView: View {
    let currentValue: Int
    let maxValue: Int
    let nextUnlockablePawn: String?
    private let gridSize: CGFloat = 40

    var body: some View {
        HStack(spacing: 2) {
            // Progress cells
            ForEach(0..<maxValue, id: \.self) { i in
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
            
            // Final reward cell
            ZStack {
                Rectangle()
                    .fill(PlayerColor.yellow.primaryColor.opacity(0.6))
                    .frame(width: gridSize, height: gridSize)
                    .border(Color.white.opacity(0.8), width: 2)
                
                if let pawn = nextUnlockablePawn {
                    Image(pawn)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: gridSize * 0.8, height: gridSize * 0.8)
                        .shadow(radius: 3)
                }
            }
        }
    }
}

#Preview {
    ProgressGaugeView(currentValue: 3, maxValue: 10, nextUnlockablePawn: "pawn_mango")
        .padding()
        .background(Color.gray)
}
