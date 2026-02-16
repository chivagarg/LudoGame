import SwiftUI

struct BoostIconTileView: View {
    let ability: (any BoostAbility)?
    let tileSize: CGFloat
    let iconSize: CGFloat
    let badgeValue: Int
    let badgeSize: CGFloat
    var isUsed: Bool = false
    var isActive: Bool = false
    var isEnabled: Bool = true
    var highlightActiveBorder: Bool = false
    var inactiveBadgeColor: Color = .gray

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: max(6, tileSize * 0.22))
                .fill(Color.white.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: max(6, tileSize * 0.22))
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
                .frame(width: tileSize, height: tileSize)

            iconBody()
                .frame(width: tileSize, height: tileSize)
                .opacity(isUsed ? 0.5 : (isEnabled ? 1.0 : 0.65))
                .scaleEffect(isActive ? 1.08 : 1.0)
                .overlay(
                    RoundedRectangle(cornerRadius: max(6, tileSize * 0.22))
                        .stroke(
                            highlightActiveBorder && isActive ? Color.purple.opacity(0.8) : Color.clear,
                            lineWidth: 2
                        )
                )

            let active = badgeValue >= 1
            Text("\(badgeValue)")
                .font(.system(size: badgeSize * 0.56, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: badgeSize, height: badgeSize)
                .background(Circle().fill(active ? Color.red : inactiveBadgeColor))
                // Keep badge fully inside tile bounds on compact layouts.
                .padding(.top, max(1, tileSize * 0.03))
                .padding(.trailing, max(1, tileSize * 0.03))
        }
        .frame(width: tileSize, height: tileSize)
    }

    @ViewBuilder
    private func iconBody() -> some View {
        if let ability {
            if ability.kind == .rerollToSix {
                Image(systemName: "die.face.6.fill")
                    .font(.system(size: iconSize * 1.15))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 0.8, green: 0.6, blue: 0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .saturation(isUsed ? 0.0 : 1.0)
                    .opacity(isUsed ? 0.6 : 1.0)
            } else if ability.kind == .extraBackwardMove {
                HStack(spacing: 1) {
                    Text("+1")
                        .font(.system(size: iconSize * 0.58, weight: .heavy, design: .rounded))
                        .foregroundColor(.red)
                    Image(PawnAssets.mirchiIndicator)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iconSize * 0.52, height: iconSize * 0.52)
                }
                .saturation(isUsed ? 0.0 : 1.0)
                .opacity(isUsed ? 0.6 : 1.0)
            } else {
                Image(systemName: ability.iconSystemName)
                    .font(.system(size: iconSize * 0.95, weight: .heavy))
                    .foregroundColor(isUsed ? .gray : (isActive ? Color.purple : Color.purple.opacity(0.7)))
            }
        } else {
            Image(systemName: "bolt.fill")
                .font(.system(size: iconSize * 0.9, weight: .heavy))
                .foregroundColor(.gray.opacity(0.6))
        }
    }
}
