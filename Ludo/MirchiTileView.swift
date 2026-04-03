import SwiftUI

struct MirchiTileView: View {
    let tileSize: CGFloat
    let iconSize: CGFloat
    let badgeValue: Int
    let badgeSize: CGFloat
    let backArrowAssetName: String
    /// Mirchi backward mode on (user tapped to arm) — same idea as boost `isArmed`.
    var isArmed: Bool = false
    /// Current player's panel — matches `BoostIconTileView.isHighlightedForTurn`.
    var isHighlightedForTurn: Bool = false
    /// No Mirchi moves left — mirrors boost “used up” styling.
    var isExhausted: Bool = false
    var inactiveBadgeColor: Color = .gray
    var highlightColor: Color = .red
    var backgroundColor: Color = .white

    /// Primary circle fill when it’s your turn, Mirchi is armed, and moves remain.
    private var showArmedHighlight: Bool {
        isHighlightedForTurn && !isExhausted && isArmed
    }

    private var circleFill: Color {
        if isExhausted {
            return backgroundColor.opacity(0.95)
        }
        return showArmedHighlight ? highlightColor : backgroundColor.opacity(0.95)
    }

    private var circleBorderColor: Color {
        if isExhausted {
            return highlightColor.opacity(0.35)
        }
        return showArmedHighlight ? Color.white.opacity(0.45) : highlightColor
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(circleFill)
                .overlay(
                    Circle()
                        .stroke(circleBorderColor, lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 1)
                .frame(width: tileSize, height: tileSize)

            mirchiIcons()
                .frame(width: tileSize, height: tileSize)

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

    /// Chili keeps full-color art; back arrow turns white when Mirchi is armed so it reads on the primary fill.
    @ViewBuilder
    private func mirchiIcons() -> some View {
        ZStack {
            Group {
                if showArmedHighlight {
                    Image(backArrowAssetName)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iconSize * 0.56, height: iconSize * 0.56)
                        .foregroundColor(.white)
                } else {
                    Image(backArrowAssetName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iconSize * 0.56, height: iconSize * 0.56)
                }
            }
            .offset(x: -iconSize * 0.22, y: -iconSize * 0.12)

            Image(PawnAssets.mirchiIndicator)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize * 1.04, height: iconSize * 1.04)
                .offset(x: iconSize * 0.22, y: iconSize * 0.14)
        }
    }
}
