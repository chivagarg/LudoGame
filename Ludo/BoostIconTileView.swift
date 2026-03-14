import SwiftUI

// MARK: - Reusable Marching Lights Border

struct MarchingBorderModifier: ViewModifier {
    let isActive: Bool
    let cornerRadius: CGFloat
    var color: Color = .purple

    @State private var dashPhase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(color.opacity(0.3), lineWidth: 7)
                        .blur(radius: 4)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            style: StrokeStyle(
                                lineWidth: 2.5,
                                lineCap: .round,
                                lineJoin: .round,
                                dash: [3, 6],
                                dashPhase: dashPhase
                            )
                        )
                        .foregroundColor(color.opacity(0.9))
                        .shadow(color: color.opacity(0.7), radius: 3)
                }
                .opacity(isActive ? 1 : 0)
            )
            .onAppear {
                withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                    dashPhase -= 9
                }
            }
    }
}

extension View {
    func marchingLightsBorder(isActive: Bool, cornerRadius: CGFloat, color: Color = .purple) -> some View {
        modifier(MarchingBorderModifier(isActive: isActive, cornerRadius: cornerRadius, color: color))
    }
}

// MARK: - Boost Icon Tile

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
    var highlightColor: Color = .purple

    private var cornerRadius: CGFloat { tileSize / 2 }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(Color.white.opacity(0.95))
                .overlay(
                    Circle().stroke(highlightColor.opacity(0.45), lineWidth: max(1, tileSize * 0.045))
                )
                .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 1)
                .frame(width: tileSize, height: tileSize)

            iconBody()
                .frame(width: tileSize, height: tileSize)
                .opacity(isUsed ? 0.5 : (isEnabled ? 1.0 : 0.65))
                .scaleEffect(isActive ? 1.08 : 1.0)
                .marchingLightsBorder(
                    isActive: highlightActiveBorder && isActive,
                    cornerRadius: cornerRadius
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
