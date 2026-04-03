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
    /// Current player's panel (eligible for the “your turn” styling ladder below).
    var isHighlightedForTurn: Bool = false
    /// When `true` together with `isHighlightedForTurn`, shows primary fill + white icon (armed). When `false` on your turn, secondary fill + primary icon (unarmed).
    var isArmed: Bool = false
    var isEnabled: Bool = true
    var showBadge: Bool = true
    var inactiveBadgeColor: Color = .gray
    var highlightColor: Color = .purple
    var backgroundColor: Color = .white

    private var cornerRadius: CGFloat { tileSize / 2 }

    /// Primary “active” look only when it’s this player’s turn *and* boost is armed (matches design: unarmed vs armed on your turn).
    private var showArmedHighlight: Bool {
        isHighlightedForTurn && !isUsed && isArmed
    }

    private var circleFill: Color {
        if isUsed {
            return backgroundColor.opacity(0.95)
        }
        return showArmedHighlight ? highlightColor : backgroundColor.opacity(0.95)
    }

    private var circleBorderColor: Color {
        if isUsed {
            return highlightColor.opacity(0.35)
        }
        return showArmedHighlight ? Color.white.opacity(0.45) : highlightColor
    }

    private var iconForeground: Color {
        if isUsed {
            return Color.gray.opacity(0.55)
        }
        return showArmedHighlight ? Color.white : highlightColor
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

            iconBody()
                .frame(width: tileSize, height: tileSize)
                .opacity(isUsed ? 0.5 : (isEnabled ? 1.0 : 0.65))

            if showBadge {
                let active = badgeValue >= 1
                Text("\(badgeValue)")
                    .font(.system(size: badgeSize * 0.56, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: badgeSize, height: badgeSize)
                    // Match Mirchi tile badge: `Color.red` (not player primary).
                    .background(Circle().fill(active ? Color.red : inactiveBadgeColor))
                    .padding(.top, max(1, tileSize * 0.03))
                    .padding(.trailing, max(1, tileSize * 0.03))
            }
        }
        .frame(width: tileSize, height: tileSize)
    }

    @ViewBuilder
    private func iconBody() -> some View {
        if let ability {
            if let assetName = boostAssetName(for: ability.kind) {
                Image(assetName)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
                    .foregroundColor(iconForeground)
            } else {
                Image(systemName: ability.iconSystemName)
                    .font(.system(size: iconSize * 0.95, weight: .heavy))
                    .foregroundColor(iconForeground)
            }
        } else {
            Image(systemName: "bolt.fill")
                .font(.system(size: iconSize * 0.9, weight: .heavy))
                .foregroundColor(.gray.opacity(0.6))
        }
    }

    private func boostAssetName(for kind: BoostKind) -> String? {
        switch kind {
        case .rerollToSix:
            return PawnAssets.boostDice
        case .trap:
            return PawnAssets.boostTrap
        case .safeZone:
            return PawnAssets.boostShield
        case .extraBackwardMove:
            return PawnAssets.boostMirchi
        }
    }
}
