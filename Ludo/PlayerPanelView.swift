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
        // `game.currentPlayer == color` ensures:
        //   (a) you can only act on your own turn, and
        //   (b) no human can tap their boost while it is an AI player's turn.
        // `!aiControlledPlayers.contains(color)` prevents a human from tapping
        //   an AI player's boost button regardless of whose turn it is.
        // `tapBoost` in LudoGame repeats the `currentPlayer == color` guard as
        //   a server-side safety net in case the UI check is ever bypassed.
        return game.currentPlayer == color
            && !game.aiControlledPlayers.contains(color)
            && !game.isBusy
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

    private var horizontalPadding: CGFloat {
        max(4, panelWidth * 0.012)
    }

    private var verticalPadding: CGFloat {
        max(6, panelHeight * 0.08)
    }

    private var panelInnerWidth: CGFloat {
        max(1, panelWidth - (horizontalPadding * 2))
    }

    private var panelInnerHeight: CGFloat {
        max(1, panelHeight - (verticalPadding * 2))
    }

    // Panel interior proportions: Boost 30% | Dice 40% | Mirchi 30%
    private var boostSectionWidth: CGFloat { panelInnerWidth * 0.30 }
    private var diceSectionWidth: CGFloat { panelInnerWidth * 0.40 }
    private var mirchiSectionWidth: CGFloat { panelInnerWidth * 0.30 }

    private var actionSlotSize: CGFloat {
        min(boostSectionWidth * 0.84, panelInnerHeight * 0.78)
    }

    private var sideButtonSize: CGFloat {
        actionSlotSize * 0.84
    }

    private var diceSize: CGFloat {
        min(diceSectionWidth * 0.96, panelInnerHeight * 0.98)
    }

    private var scoreIconSize: CGFloat {
        min(28, max(16, panelHeight * 0.22))
    }

    private var actionLabelFontSize: CGFloat { min(12, max(8, panelHeight * 0.09)) }

    private var scoreLabelFontSize: CGFloat { min(14, max(10, panelHeight * 0.11)) }

    private var scoreValueFontSize: CGFloat {
        min(18, max(12, panelHeight * 0.15))
    }

    private var actionLabelHeight: CGFloat {
        max(30, panelInnerHeight * 0.32)
    }

    private var badgeSize: CGFloat {
        min(30, max(16, actionSlotSize * 0.34))
    }

    private var outsideScoreGap: CGFloat {
        max(8, panelHeight * 0.08)
    }

    private var diceScale: CGFloat {
        min(1.0, max(0.5, diceSize / 56.0))
    }

    private var canOpenBoostHelpIph: Bool {
        game.currentPlayer == color
            && !game.aiControlledPlayers.contains(color)
            && !game.isBusy
    }

    private var canOpenMirchiHelpIph: Bool {
        game.currentPlayer == color
            && !game.aiControlledPlayers.contains(color)
            && !game.isBusy
            && hasMirchiFeature
    }

    @ViewBuilder
    private func actionLabel(title: String, showHelp: Bool, helpEnabled: Bool, onHelpTap: @escaping () -> Void) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: actionLabelFontSize, weight: .semibold, design: .rounded))
                .foregroundColor(.black.opacity(0.85))
                .lineLimit(1)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
            if showHelp {
                let chipSize = max(30, actionLabelFontSize * 2.55)
                let iconSize = chipSize * 0.62
                Button(action: onHelpTap) {
                    ZStack {
                        Circle()
                            .fill(
                                helpEnabled
                                    ? color.secondaryColor.opacity(0.98)
                                    : Color.black.opacity(0.06)
                            )
                            .shadow(
                                color: Color.black.opacity(helpEnabled ? 0.12 : 0.05),
                                radius: helpEnabled ? 3 : 1,
                                x: 0,
                                y: 1
                            )
                        Image("iph-exclamation")
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: iconSize, height: iconSize)
                            .foregroundColor(
                                Color(red: 0x9F/255, green: 0x9F/255, blue: 0x9F/255)
                                    .opacity(helpEnabled ? 1.0 : 0.7)
                            )
                    }
                    .frame(width: chipSize, height: chipSize)
                    .contentShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!helpEnabled)
                .accessibilityLabel("Help")
            }
        }
        .frame(height: actionLabelHeight)
    }

    @ViewBuilder
    private func actionSlot<Content: View>(
        label: String,
        width: CGFloat,
        showHelp: Bool = false,
        helpEnabled: Bool = false,
        onHelpTap: @escaping () -> Void = {},
        content: () -> Content
    ) -> some View {
        VStack {
            Spacer(minLength: 0)
            VStack(spacing: max(2, panelHeight * 0.02)) {
                content()
                    .frame(height: actionSlotSize)
                actionLabel(
                    title: label,
                    showHelp: showHelp,
                    helpEnabled: helpEnabled,
                    onHelpTap: onHelpTap
                )
            }
            Spacer(minLength: 0)
        }
        .frame(width: width, height: panelInnerHeight)
    }

    @ViewBuilder
    private func boostSlot() -> some View {
        let state = game.getBoostState(for: color)
        let isUsed = state == .used || boostRemaining <= 0
        let isCurrentPlayerTurn = game.currentPlayer == color
        let isArmed = state == .armed
        let isEnabled = !isUsed && canUseBoost(for: color) && game.boostAbility(for: color) != nil
        actionSlot(
            label: GameCopy.PlayerPanel.boostLabel,
            width: boostSectionWidth,
            showHelp: true,
            helpEnabled: canOpenBoostHelpIph,
            onHelpTap: { game.showBoostHelpIphForPlayerPanel(color: color) }
        ) {
            Button(action: {
                guard isEnabled else { return }
                game.tapBoost(color: color)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }) {
                BoostIconTileView(
                    ability: game.boostAbility(for: color),
                    tileSize: sideButtonSize,
                    iconSize: sideButtonSize * 0.5,
                    badgeValue: max(0, boostRemaining),
                    badgeSize: badgeSize,
                    isUsed: isUsed,
                    isHighlightedForTurn: isCurrentPlayerTurn,
                    isArmed: isArmed,
                    isEnabled: isEnabled,
                    highlightColor: color.primaryColor,
                    backgroundColor: color.secondaryColor
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
        let isCurrentPlayerTurn = game.currentPlayer == color
        let isEnabled = hasMirchiFeature && hasMirchiMoves
            && isCurrentPlayerTurn
            && !game.aiControlledPlayers.contains(color)
            && !game.isBusy
        actionSlot(
            label: GameCopy.PlayerPanel.mirchiModeLabel,
            width: mirchiSectionWidth,
            showHelp: hasMirchiFeature,
            helpEnabled: canOpenMirchiHelpIph,
            onHelpTap: { game.showMirchiModeHelpIphForPlayerPanel(color: color) }
        ) {
            Button(action: {
                guard isEnabled else { return }
                game.toggleMirchiMode(for: color)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }) {
                MirchiTileView(
                    tileSize: sideButtonSize,
                    iconSize: sideButtonSize * 0.5,
                    badgeValue: max(0, mirchiRemaining),
                    badgeSize: badgeSize,
                    backArrowAssetName: PawnAssets.backArrow(for: color),
                    isArmed: isMirchiActive,
                    isHighlightedForTurn: isCurrentPlayerTurn,
                    isExhausted: mirchiRemaining <= 0,
                    highlightColor: color.primaryColor,
                    backgroundColor: color.secondaryColor
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!isEnabled)
        }
    }

    @ViewBuilder
    private func scoreRowSlot(label: String, value: Int, icon: some View) -> some View {
        VStack(spacing: max(2, panelHeight * 0.016)) {
            Text(label)
                .font(.system(size: scoreLabelFontSize, weight: .semibold, design: .rounded))
                .foregroundColor(.black.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HStack(spacing: 6) {
                icon
                    .frame(width: scoreIconSize, height: scoreIconSize)
                Text("\(value)")
                    .font(.system(size: scoreValueFontSize, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func pawnScoreSlot() -> some View {
        let avatarName = game.selectedAvatar(for: color)
        scoreRowSlot(
            label: GameCopy.PlayerPanel.totalPointsLabel,
            value: game.scores[color] ?? 0,
            icon: AvatarIcon(avatarName: avatarName, playerColor: color.primaryColor)
        )
    }

    @ViewBuilder
    private func killsSlot() -> some View {
        scoreRowSlot(
            label: GameCopy.PlayerPanel.totalKillsLabel,
            value: game.killCounts[color] ?? 0,
            icon: Image("skull_cute")
                .resizable()
                .aspectRatio(contentMode: .fit)
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
    private func diceSlot() -> some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.97))
                    .overlay(Circle().stroke(color.primaryColor.opacity(0.45), lineWidth: max(1, panelHeight * 0.03)))
                    .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 1)
                    .frame(width: diceSize, height: diceSize)

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
                    .marchingLightsBorder(
                        isActive: canRoll,
                        cornerRadius: 12,
                        color: color.primaryColor
                    )
                    .id(canRoll)
                    .scaleEffect(diceScale)
                }
            }
        }
        .frame(width: diceSectionWidth, height: panelInnerHeight, alignment: .center)
    }

    @ViewBuilder
    private func panelContent() -> some View {
        HStack(spacing: 0) {
            boostSlot()
            diceSlot()
            mirchiSlot()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
    }

    @ViewBuilder
    private func scoreContentOutsidePanel() -> some View {
        HStack(spacing: max(8, panelWidth * 0.04)) {
            pawnScoreSlot()
            killsSlot()
        }
        .padding(.horizontal, max(8, panelWidth * 0.08))
    }

    @ViewBuilder
    private func panelShell() -> some View {
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
        .clipShape(RoundedRectangle(cornerRadius: max(12, panelHeight * 0.22)))
        .overlay(
            RoundedRectangle(cornerRadius: max(12, panelHeight * 0.22))
                .stroke(game.selectedPlayers.contains(color) ? color.toSwiftUIColor(for: color) : Color.clear, lineWidth: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: max(13, panelHeight * 0.24))
                .stroke(game.currentPlayer == color ? color.toSwiftUIColor(for: color) : Color.clear, lineWidth: max(2, panelHeight * 0.04))
                .shadow(color: color.toSwiftUIColor(for: color).opacity(game.currentPlayer == color ? 0.7 : 0), radius: 6)
        )
        .shadow(color: .black.opacity(game.selectedPlayers.contains(color) ? 0.3 : 0), radius: 5, x: 0, y: 5)
    }

    var body: some View {
        panelShell()
            .overlay(alignment: .top) {
                if game.selectedPlayers.contains(color) {
                    scoreContentOutsidePanel()
                        .padding(.top, panelHeight + outsideScoreGap)
                }
            }
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
