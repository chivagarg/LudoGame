import SwiftUI

struct PlayerPanelView: View {
    @EnvironmentObject var game: LudoGame
    let color: PlayerColor
    let showDice: Bool
    let diceValue: Int
    let isDiceRolling: Bool
    let onDiceTap: () -> Void
    let panelWidth: CGFloat
    let panelHeight: CGFloat
    @State private var localDiceRolling: Bool = false

    private func canUseBoost(for color: PlayerColor) -> Bool {
        // Must be on your turn (boost can be armed anytime on your turn).
        return game.currentPlayer == color
            && !game.aiControlledPlayers.contains(color)
            && !game.isBusy
    }

    private var isRightSidePanel: Bool {
        color == .green || color == .yellow
    }

    private var mirchiRemaining: Int {
        game.mirchiMovesRemaining[color, default: 0]
    }

    private var boostRemaining: Int {
        game.boostUsesRemaining[color] ?? PawnAssets.boostUses(for: game.selectedAvatar(for: color))
    }

    private var hasMirchiFeature: Bool {
        game.gameMode == .mirchi
    }

    private var slotSize: CGFloat {
        min(slotSizeFromHeight, slotSizeFromWidth)
    }

    private var horizontalPadding: CGFloat {
        max(4, panelWidth * 0.012)
    }

    // 3 equal columns: Tools / Dice / Score
    private var thirdWidth: CGFloat {
        max(0, (panelWidth - (horizontalPadding * 2)) / 3.0)
    }

    private var sectionInnerSpacing: CGFloat {
        max(2, thirdWidth * 0.05)
    }

    private var sectionHorizontalInset: CGFloat {
        max(2, thirdWidth * 0.05)
    }

    private var notchWidth: CGFloat {
        max(28, min(thirdWidth * 0.86, panelHeight * 0.72))
    }

    private var sectionContentWidth: CGFloat {
        max(0, thirdWidth - (sectionHorizontalInset * 2))
    }

    private var slotSizeFromWidth: CGFloat {
        max(14, (sectionContentWidth - sectionInnerSpacing) / 2)
    }

    private var slotSizeFromHeight: CGFloat {
        min(44, max(20, panelHeight * 0.34))
    }

    private var iconSize: CGFloat {
        slotSize * 0.72
    }

    private var labelFontSize: CGFloat {
        min(14, max(8, panelHeight * 0.13))
    }

    private var valueFontSize: CGFloat {
        min(15, max(9, panelHeight * 0.16))
    }

    private var badgeSize: CGFloat {
        min(22, max(12, slotSize * 0.36))
    }

    private var sectionTitleSize: CGFloat {
        min(14, max(8, panelHeight * 0.13))
    }

    private var diceScale: CGFloat {
        min(0.8, max(0.38, notchWidth / 56.0))
    }

    @ViewBuilder
    private func boostIconBody(isUsed: Bool, isActive: Bool, isEnabled: Bool) -> some View {
        if let ability = game.boostAbility(for: color) {
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

    @ViewBuilder
    private func slotCard<Content: View>(
        title: String,
        valueText: String,
        badgeValue: Int? = nil,
        badgeActiveThreshold: Int = 1,
        valueColor: Color = .black,
        content: () -> Content
    ) -> some View {
        VStack(spacing: max(2, panelHeight * 0.03)) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: max(6, slotSize * 0.22))
                    .fill(Color.white.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: max(6, slotSize * 0.22))
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                    .frame(width: slotSize, height: slotSize)

                content()
                    .frame(width: slotSize, height: slotSize)

                if let badgeValue {
                    let active = badgeValue >= badgeActiveThreshold
                    Text("\(badgeValue)")
                        .font(.system(size: badgeSize * 0.56, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: badgeSize, height: badgeSize)
                        .background(Circle().fill(active ? Color.red : Color.gray))
                        // Keep badge fully inside slot bounds on compact devices.
                        .padding(.top, max(1, slotSize * 0.03))
                        .padding(.trailing, max(1, slotSize * 0.03))
                }
            }

            Text(title)
                .font(.system(size: labelFontSize, weight: .semibold, design: .rounded))
                .foregroundColor(.black.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if !valueText.isEmpty {
                Text(valueText)
                    .font(.system(size: valueFontSize, weight: .bold, design: .rounded))
                    .foregroundColor(valueColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func valueOnlySlot<Content: View>(
        valueText: String,
        valueColor: Color = .black,
        content: () -> Content
    ) -> some View {
        VStack(spacing: max(2, panelHeight * 0.03)) {
            content()
                .frame(width: slotSize, height: slotSize)

            Text(valueText)
                .font(.system(size: valueFontSize, weight: .bold, design: .rounded))
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func boostSlot() -> some View {
        let state = game.getBoostState(for: color)
        let isUsed = state == .used || boostRemaining <= 0
        let isActive = state == .armed
        let isEnabled = !isUsed && canUseBoost(for: color) && game.boostAbility(for: color) != nil
        slotCard(
            title: "Boost",
            valueText: "",
            badgeValue: max(0, boostRemaining),
            badgeActiveThreshold: 1
        ) {
            Button(action: {
                guard isEnabled else { return }
                game.tapBoost(color: color)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }) {
                ZStack {
                    boostIconBody(isUsed: isUsed, isActive: isActive, isEnabled: isEnabled)
                }
                .opacity(isUsed ? 0.5 : (isEnabled ? 1.0 : 0.65))
                .scaleEffect(isActive ? 1.08 : 1.0)
                .overlay(
                    RoundedRectangle(cornerRadius: max(6, slotSize * 0.22))
                        .stroke(isActive ? Color.purple.opacity(0.8) : Color.clear, lineWidth: 2)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!isEnabled)
        }
    }

    @ViewBuilder
    private func mirchiSlot() -> some View {
        let isMirchiActive = game.mirchiArrowActivated[color] == true
        let hasMirchiMoves = mirchiRemaining > 0
        let isEnabled = hasMirchiFeature && hasMirchiMoves
        slotCard(
            title: "Mirchi",
            valueText: "",
            badgeValue: max(0, mirchiRemaining),
            badgeActiveThreshold: 1
        ) {
            Button(action: {
                guard isEnabled else { return }
                game.mirchiArrowActivated[color]?.toggle()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }) {
                Image(PawnAssets.mirchiIndicator)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
                    .saturation(isMirchiActive ? 1.0 : 0.4)
                    .opacity(isEnabled ? (isMirchiActive ? 1.0 : 0.75) : 0.45)
                    .grayscale(isEnabled ? 0 : 1)
                    .scaleEffect(isMirchiActive ? 1.08 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!isEnabled)
        }
    }

    @ViewBuilder
    private func pawnScoreSlot() -> some View {
        let avatarName = game.selectedAvatar(for: color)
        valueOnlySlot(
            valueText: "\(game.scores[color] ?? 0)",
            valueColor: color.toSwiftUIColor(for: color)
        ) {
            AvatarIcon(avatarName: avatarName, playerColor: color.primaryColor)
                .frame(width: iconSize, height: iconSize)
        }
    }

    @ViewBuilder
    private func killsSlot() -> some View {
        valueOnlySlot(
            valueText: "\(game.killCounts[color] ?? 0)"
        ) {
            Image("skull_cute")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
        }
    }

    @ViewBuilder
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: sectionTitleSize, weight: .heavy, design: .rounded))
            .foregroundColor(color.primaryColor.opacity(0.9))
            .padding(.horizontal, max(4, panelHeight * 0.06))
            .padding(.vertical, max(1, panelHeight * 0.02))
            .background(
                RoundedRectangle(cornerRadius: max(6, panelHeight * 0.12))
                    .fill(Color.white.opacity(0.75))
            )
    }

    private var canRoll: Bool {
        showDice
            && !isDiceRolling
            && !localDiceRolling
            && game.eligiblePawns.isEmpty
            && game.currentRollPlayer == nil
            && !game.isBusy
            && !game.aiControlledPlayers.contains(color)
    }

    @ViewBuilder
    private func toolsSlots() -> some View {
        HStack(spacing: sectionInnerSpacing) {
            boostSlot()
            mirchiSlot()
        }
    }

    @ViewBuilder
    private func scoreSlots() -> some View {
        HStack(spacing: sectionInnerSpacing) {
            pawnScoreSlot()
            killsSlot()
        }
    }

    @ViewBuilder
    private func leftSection() -> some View {
        VStack(spacing: max(2, panelHeight * 0.03)) {
            sectionTitle("Tools")
            if isRightSidePanel {
                scoreSlots()
            } else {
                toolsSlots()
            }
        }
        .padding(.horizontal, sectionHorizontalInset)
        .frame(width: thirdWidth, alignment: .center)
    }

    @ViewBuilder
    private func rightSection() -> some View {
        VStack(spacing: max(2, panelHeight * 0.03)) {
            sectionTitle("Score")
            if isRightSidePanel {
                toolsSlots()
            } else {
                scoreSlots()
            }
        }
        .padding(.horizontal, sectionHorizontalInset)
        .frame(width: thirdWidth, alignment: .center)
    }

    @ViewBuilder
    private func diceNotch() -> some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.97))
                .overlay(Circle().stroke(color.primaryColor.opacity(0.45), lineWidth: max(1, panelHeight * 0.03)))
                .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 1)
                .frame(width: notchWidth * 0.88, height: notchWidth * 0.88)

            if showDice {
                DiceView(
                    value: diceValue,
                    isRolling: isDiceRolling || localDiceRolling,
                    shouldPulse: canRoll,
                    onTap: {
                        if !game.aiControlledPlayers.contains(color) {
                            onDiceTap()
                        }
                    }
                )
                .id(canRoll)
                .scaleEffect(diceScale)
            }
        }
        .frame(width: thirdWidth, alignment: .center)
    }

    @ViewBuilder
    private func panelContent() -> some View {
        HStack(spacing: 0) {
            leftSection()
            diceNotch()
            rightSection()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, max(2, panelHeight * 0.03))
    }

    var body: some View {
        ZStack {
            if game.selectedPlayers.contains(color) {
                RoundedRectangle(cornerRadius: max(12, panelHeight * 0.22))
                    .fill(Color.white)

                RoundedRectangle(cornerRadius: max(12, panelHeight * 0.22))
                    .fill(color.toSwiftUIColor(for: color).opacity(0.5))

                panelContent()
            }
        }
        .frame(width: panelWidth, height: panelHeight)
        // Enforce exact 6-cell panel bounds (content must not visually spill outside).
        .clipShape(RoundedRectangle(cornerRadius: max(12, panelHeight * 0.22)))
        // Base border for selected players
        .overlay(
            RoundedRectangle(cornerRadius: max(12, panelHeight * 0.22))
                .stroke(game.selectedPlayers.contains(color) ? color.toSwiftUIColor(for: color) : Color.clear, lineWidth: 2)
        )
        // Additional halo to highlight current player
        .overlay(
            RoundedRectangle(cornerRadius: max(13, panelHeight * 0.24))
                .stroke(game.currentPlayer == color ? color.toSwiftUIColor(for: color) : Color.clear, lineWidth: max(2, panelHeight * 0.04))
                .shadow(color: color.toSwiftUIColor(for: color).opacity(game.currentPlayer == color ? 0.7 : 0), radius: 6)
        )
        .shadow(color: .black.opacity(game.selectedPlayers.contains(color) ? 0.3 : 0), radius: 5, x: 0, y: 5)
        .onChange(of: game.rollID) { _ in
            if showDice && !isDiceRolling && !localDiceRolling {
                localDiceRolling = true
                DispatchQueue.main.asyncAfter(deadline: .now() + GameConstants.diceAnimationDuration) {
                    localDiceRolling = false
                }
            }
        }
    }
} 
