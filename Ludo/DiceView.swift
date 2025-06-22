import SwiftUI
import AVFoundation

struct DiceView: View {
    let value: Int
    let isRolling: Bool
    let onTap: () -> Void
    
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Dice background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(radius: 5)
                .frame(width: 60, height: 60)
            
            if isRolling {
                // Rolling animation
                Text("🎲")
                    .font(.system(size: 40))
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(scale)
                    .onAppear {
                        // Play dice roll sound
                        SoundManager.shared.playDiceRollSound()
                        withAnimation(.easeInOut(duration: 0.2).repeatForever(autoreverses: true)) {
                            rotation = 360
                            scale = 1.2
                        }
                    }
                    .onDisappear {
                        rotation = 0
                        scale = 1.0
                    }
            } else {
                // Dice dots
                VStack(spacing: 8) {
                    ForEach(0..<3) { row in
                        HStack(spacing: 8) {
                            ForEach(0..<3) { col in
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 8, height: 8)
                                    .opacity(shouldShowDot(row: row, col: col) ? 1 : 0)
                            }
                        }
                    }
                }
                .frame(width: 40, height: 40)
            }
        }
        .frame(width: 60, height: 60)
        .contentShape(Rectangle())  // Make the entire area tappable
        .onTapGesture {
            if !isRolling {
                onTap()
            }
        }
    }
    
    private func shouldShowDot(row: Int, col: Int) -> Bool {
        switch value {
        case 1:
            return row == 1 && col == 1
        case 2:
            return (row == 0 && col == 0) || (row == 2 && col == 2)
        case 3:
            return (row == 0 && col == 0) || (row == 1 && col == 1) || (row == 2 && col == 2)
        case 4:
            return (row == 0 && col == 0) || (row == 0 && col == 2) ||
                   (row == 2 && col == 0) || (row == 2 && col == 2)
        case 5:
            return (row == 0 && col == 0) || (row == 0 && col == 2) ||
                   (row == 1 && col == 1) ||
                   (row == 2 && col == 0) || (row == 2 && col == 2)
        case 6:
            return (row == 0 && col == 0) || (row == 0 && col == 2) ||
                   (row == 1 && col == 0) || (row == 1 && col == 2) ||
                   (row == 2 && col == 0) || (row == 2 && col == 2)
        default:
            return false
        }
    }
} 
 