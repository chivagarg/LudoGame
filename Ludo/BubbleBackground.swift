import SwiftUI

struct BubbleBackground: View {
    @Binding var animate: Bool
    private let palette: [Color] = [
        PlayerColor.red.primaryColor,
        PlayerColor.green.primaryColor,
        PlayerColor.yellow.primaryColor,
        PlayerColor.blue.primaryColor
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<14, id: \ .self) { idx in
                    let size = CGFloat(Int.random(in: 140...260))
                    let color = palette[idx % palette.count].opacity(0.25)
                    Circle()
                        .fill(color)
                        .frame(width: size, height: size)
                        .position(x: CGFloat.random(in: 0...geo.size.width),
                                  y: CGFloat.random(in: 0...geo.size.height))
                        .offset(y: animate ? -20 : 20)
                        .animation(.easeInOut(duration: Double.random(in: 6...10)).repeatForever(autoreverses: true), value: animate)
                }
            }
            .ignoresSafeArea()
        }
    }
} 
