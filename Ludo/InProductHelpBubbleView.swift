import SwiftUI

enum HelpBubbleIcon {
    case image(String)
    case system(String)
    case mirchiMode
}

/// Generic in-product help modal with dimmed overlay.
/// Pattern: icon -> title -> explanation + close affordance.
struct InProductHelpBubbleView: View {
    let icon: HelpBubbleIcon
    let title: String
    let message: String
    var iconBadgeValue: Int? = nil
    var primaryButtonTitle: String? = nil
    var onPrimaryAction: (() -> Void)? = nil
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack(spacing: 14) {
                header
                iconTile
                titleText
                messageText

                if let primaryButtonTitle {
                    Button(action: {
                        if let onPrimaryAction {
                            onPrimaryAction()
                        } else {
                            onClose()
                        }
                    }) {
                        Text(primaryButtonTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
            .frame(width: 340)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
            )
            .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 8)
            .padding(.horizontal, 20)
        }
    }

    private var header: some View {
        HStack {
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(.black.opacity(0.65))
            }
        }
    }

    @ViewBuilder
    private var iconTile: some View {
        switch icon {
        case .mirchiMode:
            ZStack {
                Circle()
                    .fill(PlayerColor.red.secondaryColor.opacity(0.95))
                    .overlay(
                        Circle().stroke(PlayerColor.red.primaryColor.opacity(0.45), lineWidth: 3)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 5, x: 0, y: 3)
                    .frame(width: 74, height: 74)

                Image(PawnAssets.backRed)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .offset(x: -11, y: -6)

                Image(PawnAssets.mirchiIndicator)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .offset(x: 12, y: 10)
            }
        case .image(let name):
            if let ability = boostAbility(for: name) {
                BoostIconTileView(
                    ability: ability,
                    tileSize: 74,
                    iconSize: 46,
                    badgeValue: iconBadgeValue ?? 0,
                    badgeSize: 24,
                    isUsed: false,
                    isActive: false,
                    isEnabled: true,
                    highlightActiveBorder: false,
                    showBadge: iconBadgeValue != nil,
                    highlightColor: highlightColor(for: name),
                    backgroundColor: .white
                )
            } else {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 4)
                        .frame(width: 72, height: 72)

                    Image(name)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                }
            }
        case .system(let name):
            ZStack {
                Circle()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 4)
                    .frame(width: 72, height: 72)

                Image(systemName: name)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.orange)
            }
        }
    }

    private func boostAbility(for assetName: String) -> (any BoostAbility)? {
        switch assetName {
        case PawnAssets.boostShield: return SafeZoneBoost()
        case PawnAssets.boostTrap: return TrapBoost()
        case PawnAssets.boostDice: return RerollToSixBoost()
        case PawnAssets.boostMirchi: return ExtraBackwardMoveBoost()
        default: return nil
        }
    }

    private func highlightColor(for assetName: String) -> Color {
        switch assetName {
        case PawnAssets.boostShield: return PlayerColor.green.primaryColor
        case PawnAssets.boostTrap: return PlayerColor.blue.primaryColor
        case PawnAssets.boostDice: return PlayerColor.yellow.primaryColor
        case PawnAssets.boostMirchi: return PlayerColor.red.primaryColor
        default: return .purple
        }
    }

    private var titleText: some View {
        Text(title)
            .font(.system(size: 40, weight: .bold))
            .foregroundColor(.black)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.72)
    }

    private var messageText: some View {
        Text(message)
            .boostDescriptionTextStyle()
            .foregroundColor(.black.opacity(0.7))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 4)
    }
}
