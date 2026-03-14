import SwiftUI

struct MirchiTileView: View {
    let tileSize: CGFloat
    let iconSize: CGFloat
    let badgeValue: Int
    let badgeSize: CGFloat
    var isActive: Bool = false
    var isEnabled: Bool = true
    var inactiveBadgeColor: Color = .gray
    var highlightColor: Color = .red
    var backgroundColor: Color = .white

    private var cornerRadius: CGFloat { tileSize / 2 }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(backgroundColor.opacity(0.95))
                .overlay(
                    Circle().stroke(highlightColor.opacity(0.45), lineWidth: max(1, tileSize * 0.045))
                )
                .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 1)
                .frame(width: tileSize, height: tileSize)

            Image(PawnAssets.mirchiIndicator)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
                .frame(width: tileSize, height: tileSize)
                .saturation(isActive ? 1.0 : 0.4)
                .opacity(isEnabled ? (isActive ? 1.0 : 0.75) : 0.45)
                .grayscale(isEnabled ? 0 : 1)
                .scaleEffect(isActive ? 1.08 : 1.0)
                .marchingLightsBorder(isActive: isActive, cornerRadius: cornerRadius, color: highlightColor)

            let active = badgeValue >= 1
            Text("\(badgeValue)")
                .font(.system(size: badgeSize * 0.56, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: badgeSize, height: badgeSize)
                .background(Circle().fill(active ? Color.red : inactiveBadgeColor))
                .padding(.top, max(1, tileSize * 0.03))
                .padding(.trailing, max(1, tileSize * 0.03))
        }
        .frame(width: tileSize, height: tileSize)
    }
}
