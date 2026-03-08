import Foundation

// MARK: - Move type

/// A tuple representing the AI's chosen move.
typealias AIPlayerMove = (pawnId: Int, moveBackwards: Bool)

// MARK: - Protocol

/// Defines the decision-making logic for an AI player.
protocol AILogicStrategy {
    /// Select a pawn and direction from the current eligible set.
    func selectPawnMovementStrategy(from eligiblePawns: Set<Int>, for player: PlayerColor, in game: LudoGame) -> AIPlayerMove?

    /// Called at the start of `handlePostRoll`, before pawn selection.
    /// Implement this to fire boost abilities (e.g. Mango reroll, shield placement).
    /// - Returns: `true` if `handlePostRoll` should return immediately because the boost
    ///   already triggered its own new game state (e.g. `forceDiceRollToSixForCurrentTurn`).
    ///   Return `false` to continue normal pawn selection.
    func useImmediateBoostIfNeeded(for player: PlayerColor, in game: LudoGame) -> Bool
}

extension AILogicStrategy {
    /// Default: no boost action.
    func useImmediateBoostIfNeeded(for player: PlayerColor, in game: LudoGame) -> Bool { false }
}

// MARK: - Shared position helpers

/// True if any opponent pawn occupies `position`.
func isOpponentAt(position: Position, in game: LudoGame, excluding player: PlayerColor) -> Bool {
    for (opponentColor, opponentPawns) in game.pawns where opponentColor != player {
        let opponentPath = game.path(for: opponentColor)
        guard !opponentPath.isEmpty else { continue }
        for opponentPawn in opponentPawns {
            if let idx = opponentPawn.positionIndex, idx >= 0, idx < opponentPath.count {
                if opponentPath[idx] == position { return true }
            }
        }
    }
    return false
}

/// Board position a pawn would land on after a forward roll, or nil.
func aiForwardDest(pawnId: Int, player: PlayerColor, path: [Position], game: LudoGame) -> Position? {
    guard let pawn = game.pawns[player]?.first(where: { $0.id == pawnId }),
          let pos = pawn.positionIndex, pos >= 0 else { return nil }
    let newIndex = pos + game.diceValue
    guard newIndex < path.count else { return nil }
    return path[newIndex]
}

/// Board position a pawn would land on after a backward roll, or nil.
func aiBackwardDest(pawnId: Int, player: PlayerColor, path: [Position], game: LudoGame) -> Position? {
    guard let pawn = game.pawns[player]?.first(where: { $0.id == pawnId }),
          let pos = pawn.positionIndex, pos >= 0 else { return nil }
    let newIndex = pos - game.diceValue
    guard newIndex >= 0 else { return nil }
    return path[newIndex]
}

/// True if any opponent can reach `position` in exactly 1–6 forward rolls along their own path.
func isExposedToOpponentReach(position: Position, player: PlayerColor, game: LudoGame) -> Bool {
    guard !game.isSafePosition(position) else { return false }
    for (opponentColor, opponentPawns) in game.pawns where opponentColor != player {
        let opponentPath = game.path(for: opponentColor)
        guard !opponentPath.isEmpty else { continue }
        for opponentPawn in opponentPawns {
            guard let oppIdx = opponentPawn.positionIndex,
                  oppIdx >= 0, oppIdx < opponentPath.count else { continue }
            for roll in 1...6 {
                let targetIdx = oppIdx + roll
                guard targetIdx < opponentPath.count else { break }
                if opponentPath[targetIdx] == position { return true }
            }
        }
    }
    return false
}

/// True if `pawn` can be reached by any opponent in 1–6 forward rolls.
func isPawnThreatened(pawn: PawnState, player: PlayerColor, path: [Position], game: LudoGame) -> Bool {
    guard let pos = pawn.positionIndex, pos >= 0, pos < path.count else { return false }
    return isExposedToOpponentReach(position: path[pos], player: player, game: game)
}

// MARK: - Existing simple strategies (kept for reference / admin use)

struct RandomMoveStrategy: AILogicStrategy {
    func selectPawnMovementStrategy(from eligiblePawns: Set<Int>, for player: PlayerColor, in game: LudoGame) -> AIPlayerMove? {
        eligiblePawns.randomElement().map { ($0, false) }
    }
}

struct RationalMoveStrategy: AILogicStrategy {
    func selectPawnMovementStrategy(from eligiblePawns: Set<Int>, for player: PlayerColor, in game: LudoGame) -> AIPlayerMove? {
        guard !eligiblePawns.isEmpty else { return nil }
        let currentPath = game.path(for: player)
        guard !currentPath.isEmpty else { return (eligiblePawns.first!, false) }

        if game.gameMode == .mirchi {
            let movesLeft = game.mirchiMovesRemaining[player, default: 0]
            for pawnId in eligiblePawns where movesLeft > 0 && game.isValidBackwardMove(color: player, pawnId: pawnId) {
                if let dest = aiBackwardDest(pawnId: pawnId, player: player, path: currentPath, game: game),
                   !game.isSafePosition(dest), isOpponentAt(position: dest, in: game, excluding: player) {
                    return (pawnId, true)
                }
            }
        }
        for pawnId in eligiblePawns {
            if let dest = aiForwardDest(pawnId: pawnId, player: player, path: currentPath, game: game),
               !game.isSafePosition(dest), isOpponentAt(position: dest, in: game, excluding: player) {
                return (pawnId, false)
            }
        }
        let atRisk = eligiblePawns.filter { pawnId in
            guard let pawn = game.pawns[player]?.first(where: { $0.id == pawnId }) else { return false }
            return isPawnThreatened(pawn: pawn, player: player, path: currentPath, game: game)
        }
        if game.diceValue == 6 {
            for pawnId in eligiblePawns {
                if game.pawns[player]?.first(where: { $0.id == pawnId })?.positionIndex == nil {
                    return (pawnId, false)
                }
            }
        }
        let pawnToMove = eligiblePawns.max { a, b in
            (game.pawns[player]?.first(where: { $0.id == a })?.positionIndex ?? 0) <
            (game.pawns[player]?.first(where: { $0.id == b })?.positionIndex ?? 0)
        }
        return pawnToMove.map { ($0, false) } ?? eligiblePawns.randomElement().map { ($0, false) }
    }
}

struct BackwardOnlyMoveStrategy: AILogicStrategy {
    func selectPawnMovementStrategy(from eligiblePawns: Set<Int>, for player: PlayerColor, in game: LudoGame) -> AIPlayerMove? {
        guard !eligiblePawns.isEmpty else { return nil }
        if game.gameMode == .mirchi {
            for pawnId in eligiblePawns where game.isValidBackwardMove(color: player, pawnId: pawnId) {
                return (pawnId, true)
            }
        }
        return eligiblePawns.first.map { ($0, false) }
    }
}

// MARK: - SmartMoveStrategy (Classic pawn AI)

/// Primary AI strategy. Uses threat-aware pawn selection and a Mirchi budget.
/// Used for classic (Tier 0) pawns and as the base for boost-aware strategies.
struct SmartMoveStrategy: AILogicStrategy {

    /// Minimum Mirchi moves to keep in reserve before spending one on a defensive retreat.
    /// Captures always bypass this reserve.
    private let mirchiDefenseReserve = 3

    func selectPawnMovementStrategy(
        from eligiblePawns: Set<Int>,
        for player: PlayerColor,
        in game: LudoGame
    ) -> AIPlayerMove? {
        GameLogger.shared.log("🤖 [AI SMART] \(player.rawValue) thinking. Eligible: \(eligiblePawns)", level: .debug)
        guard !eligiblePawns.isEmpty else { return nil }
        let currentPath = game.path(for: player)
        guard !currentPath.isEmpty else { return (eligiblePawns.first!, false) }

        let mirchiLeft = game.mirchiMovesRemaining[player, default: 0]
        let pawnsOnBoard = game.pawns[player]?.filter {
            $0.positionIndex != nil && $0.positionIndex != GameConstants.finishedPawnIndex
        }.count ?? 0

        // 1. Forward capture
        for pawnId in eligiblePawns {
            if let dest = aiForwardDest(pawnId: pawnId, player: player, path: currentPath, game: game),
               !game.isSafePosition(dest),
               isOpponentAt(position: dest, in: game, excluding: player) {
                GameLogger.shared.log("🤖 [AI SMART] Forward capture → pawn \(pawnId).")
                return (pawnId, false)
            }
        }

        // 2. Backward capture (Mirchi)
        if game.gameMode == .mirchi, mirchiLeft > 0 {
            for pawnId in eligiblePawns where game.isValidBackwardMove(color: player, pawnId: pawnId) {
                if let dest = aiBackwardDest(pawnId: pawnId, player: player, path: currentPath, game: game),
                   !game.isSafePosition(dest),
                   isOpponentAt(position: dest, in: game, excluding: player) {
                    GameLogger.shared.log("🤖 [AI SMART] Backward capture → pawn \(pawnId).")
                    return (pawnId, true)
                }
            }
        }

        // 3 & 4. Escape imminent threat (forward)
        let threatened = eligiblePawns.filter { pawnId in
            guard let pawn = game.pawns[player]?.first(where: { $0.id == pawnId }) else { return false }
            return isPawnThreatened(pawn: pawn, player: player, path: currentPath, game: game)
        }
        if !threatened.isEmpty {
            // Prefer landing on safe zone
            for pawnId in threatened {
                if let dest = aiForwardDest(pawnId: pawnId, player: player, path: currentPath, game: game),
                   game.isSafePosition(dest) {
                    GameLogger.shared.log("🤖 [AI SMART] Escaping threat → safe zone, pawn \(pawnId).")
                    return (pawnId, false)
                }
            }
            // Any non-dangerous forward square
            for pawnId in threatened {
                if let dest = aiForwardDest(pawnId: pawnId, player: player, path: currentPath, game: game),
                   !isExposedToOpponentReach(position: dest, player: player, game: game) {
                    GameLogger.shared.log("🤖 [AI SMART] Escaping threat → safe square, pawn \(pawnId).")
                    return (pawnId, false)
                }
            }
        }

        // 5. Bring pawn from home (≤1 on board)
        if game.diceValue == 6, pawnsOnBoard <= 1 {
            for pawnId in eligiblePawns {
                if let pawn = game.pawns[player]?.first(where: { $0.id == pawnId }),
                   pawn.positionIndex == nil {
                    GameLogger.shared.log("🤖 [AI SMART] Bringing pawn \(pawnId) from home (≤1 on board).")
                    return (pawnId, false)
                }
            }
        }

        // 6. Forward to a safe zone
        for pawnId in eligiblePawns {
            if let dest = aiForwardDest(pawnId: pawnId, player: player, path: currentPath, game: game),
               game.isSafePosition(dest),
               !isExposedToOpponentReach(position: dest, player: player, game: game) {
                GameLogger.shared.log("🤖 [AI SMART] Moving pawn \(pawnId) to safe zone.")
                return (pawnId, false)
            }
        }

        // 7. Backward retreat to safe zone (Mirchi, threatened pawn, budget above reserve)
        if game.gameMode == .mirchi, mirchiLeft > mirchiDefenseReserve {
            for pawnId in eligiblePawns where game.isValidBackwardMove(color: player, pawnId: pawnId) {
                guard let pawn = game.pawns[player]?.first(where: { $0.id == pawnId }),
                      isPawnThreatened(pawn: pawn, player: player, path: currentPath, game: game) else { continue }
                if let dest = aiBackwardDest(pawnId: pawnId, player: player, path: currentPath, game: game),
                   game.isSafePosition(dest) {
                    GameLogger.shared.log("🤖 [AI SMART] Backward retreat to safe zone, pawn \(pawnId).")
                    return (pawnId, true)
                }
            }
        }

        // 8. Advance to a square not in opponent reach (most-forward first)
        let safeMoves = eligiblePawns.compactMap { pawnId -> (pawnId: Int, pos: Int)? in
            guard let pawn = game.pawns[player]?.first(where: { $0.id == pawnId }),
                  let pos = pawn.positionIndex,
                  pos != GameConstants.finishedPawnIndex,
                  let dest = aiForwardDest(pawnId: pawnId, player: player, path: currentPath, game: game),
                  !isExposedToOpponentReach(position: dest, player: player, game: game) else { return nil }
            return (pawnId, pos)
        }.sorted { $0.pos > $1.pos }

        if let best = safeMoves.first {
            GameLogger.shared.log("🤖 [AI SMART] Advancing pawn \(best.pawnId) to safe forward square.")
            return (best.pawnId, false)
        }

        // 9. Bring pawn from home on 6 (≥2 already on board)
        if game.diceValue == 6 {
            for pawnId in eligiblePawns {
                if let pawn = game.pawns[player]?.first(where: { $0.id == pawnId }),
                   pawn.positionIndex == nil {
                    GameLogger.shared.log("🤖 [AI SMART] Bringing pawn \(pawnId) from home (2+ on board).")
                    return (pawnId, false)
                }
            }
        }

        // 10. Advance most-forward pawn
        let ranked = eligiblePawns.sorted { idA, idB in
            let posA = game.pawns[player]?.first(where: { $0.id == idA })?.positionIndex ?? -1
            let posB = game.pawns[player]?.first(where: { $0.id == idB })?.positionIndex ?? -1
            return posA > posB
        }
        if let pawnId = ranked.first {
            GameLogger.shared.log("🤖 [AI SMART] Fallback: advance most-forward pawn \(pawnId).")
            return (pawnId, false)
        }

        // 11. Random safety net
        return eligiblePawns.randomElement().map { ($0, false) }
    }
}

// MARK: - RedBoostSmartStrategy (Extra backward move)

/// Red Tomato / Anar Kali.
/// Arms the backward-move boost when mirchi runs out but a backward capture is on the table.
struct RedBoostSmartStrategy: AILogicStrategy {
    private let base = SmartMoveStrategy()

    func useImmediateBoostIfNeeded(for player: PlayerColor, in game: LudoGame) -> Bool {
        guard game.getBoostState(for: player) == .available else { return false }
        // Only arm if mirchi is exhausted — otherwise let normal mirchi logic handle it.
        guard game.mirchiMovesRemaining[player, default: 0] == 0 else { return false }

        let currentPath = game.path(for: player)
        for pawnId in game.eligiblePawns
            where game.isValidBackwardMove(color: player, pawnId: pawnId, isBoost: true) {
            if let dest = aiBackwardDest(pawnId: pawnId, player: player, path: currentPath, game: game),
               !game.isSafePosition(dest),
               isOpponentAt(position: dest, in: game, excluding: player) {
                GameLogger.shared.log("🤖 [AI RED BOOST] Arming backward boost for capture.")
                game.tapBoost(color: player)   // arms state to .armed
                return false  // pawn selection continues normally
            }
        }
        return false
    }

    func selectPawnMovementStrategy(
        from eligiblePawns: Set<Int>,
        for player: PlayerColor,
        in game: LudoGame
    ) -> AIPlayerMove? {
        let currentPath = game.path(for: player)

        // If boost is armed, attempt boost-enabled backward capture (bypasses mirchi count).
        if game.getBoostState(for: player) == .armed {
            for pawnId in eligiblePawns
                where game.isValidBackwardMove(color: player, pawnId: pawnId, isBoost: true) {
                if let dest = aiBackwardDest(pawnId: pawnId, player: player, path: currentPath, game: game),
                   !game.isSafePosition(dest),
                   isOpponentAt(position: dest, in: game, excluding: player) {
                    GameLogger.shared.log("🤖 [AI RED BOOST] Boost-enabled backward capture → pawn \(pawnId).")
                    return (pawnId, true)
                }
            }
        }

        return base.selectPawnMovementStrategy(from: eligiblePawns, for: player, in: game)
    }
}

// MARK: - YellowBoostSmartStrategy (Reroll to 6)

/// Mango Tango / Pina Anna.
/// Forces a 6 when stuck at home or when a capture with a 6 is available.
struct YellowBoostSmartStrategy: AILogicStrategy {
    private let base = SmartMoveStrategy()

    func useImmediateBoostIfNeeded(for player: PlayerColor, in game: LudoGame) -> Bool {
        guard game.getBoostState(for: player) == .available else { return false }
        guard game.diceValue != 6 else { return false }   // already rolled a 6

        let playerPawns = game.pawns[player] ?? []
        let pawnsOnBoard = playerPawns.filter {
            $0.positionIndex != nil && $0.positionIndex != GameConstants.finishedPawnIndex
        }.count
        let pawnsAtHome = playerPawns.filter { $0.positionIndex == nil }.count

        // Use boost if all unfinished pawns are stuck at home
        let allStuckAtHome = pawnsOnBoard == 0 && pawnsAtHome > 0
        // Or if a forward capture would be possible with a 6
        let captureAvailableWith6 = forwardCaptureExistsForRoll(6, player: player, in: game)

        if allStuckAtHome || captureAvailableWith6 {
            GameLogger.shared.log("🤖 [AI YELLOW BOOST] Using reroll-to-6 boost. allHome=\(allStuckAtHome) capture=\(captureAvailableWith6).")
            game.tapBoost(color: player)
            return true   // forceDiceRollToSixForCurrentTurn was called; new handlePostRoll takes over
        }
        return false
    }

    func selectPawnMovementStrategy(
        from eligiblePawns: Set<Int>,
        for player: PlayerColor,
        in game: LudoGame
    ) -> AIPlayerMove? {
        base.selectPawnMovementStrategy(from: eligiblePawns, for: player, in: game)
    }

    private func forwardCaptureExistsForRoll(_ roll: Int, player: PlayerColor, in game: LudoGame) -> Bool {
        let currentPath = game.path(for: player)
        guard !currentPath.isEmpty else { return false }
        for pawnId in game.eligiblePawns {
            guard let pawn = game.pawns[player]?.first(where: { $0.id == pawnId }),
                  let pos = pawn.positionIndex, pos >= 0 else { continue }
            let destIdx = pos + roll
            guard destIdx < currentPath.count else { continue }
            let dest = currentPath[destIdx]
            if !game.isSafePosition(dest) && isOpponentAt(position: dest, in: game, excluding: player) {
                return true
            }
        }
        return false
    }
}

// MARK: - GreenBoostSmartStrategy (Safe zone)

/// Shimla Shield / Tarboozii.
///
/// Tactic: for the most advanced threatened eligible pawn, place a safe zone at its
/// *forward destination* (where it would land this turn), then let pawn selection
/// move it there. The pawn safely arrives on a square that is now protected.
///
/// Constraints mirror `handleCellTap`: the destination must not already be safe,
/// must not be a trap, must not be occupied, and must not be inside a home corner.
struct GreenBoostSmartStrategy: AILogicStrategy {
    private let base = SmartMoveStrategy()

    func useImmediateBoostIfNeeded(for player: PlayerColor, in game: LudoGame) -> Bool {
        guard game.getBoostState(for: player) == .available else { return false }
        guard let cell = chooseSafeZoneCell(for: player, in: game) else { return false }

        GameLogger.shared.log("🤖 [AI GREEN BOOST] Placing safe zone at destination (\(cell.row),\(cell.col)).")
        game.tapBoost(color: player)                       // arm
        game.handleCellTap(row: cell.row, col: cell.col)  // place & consume
        return false  // pawn selection continues — base strategy will pick the threatened pawn
    }

    func selectPawnMovementStrategy(
        from eligiblePawns: Set<Int>,
        for player: PlayerColor,
        in game: LudoGame
    ) -> AIPlayerMove? {
        // After placing the safe zone at the destination, the base SmartMoveStrategy
        // tier 3 ("escape threat → safe zone") naturally selects the threatened pawn.
        base.selectPawnMovementStrategy(from: eligiblePawns, for: player, in: game)
    }

    /// Returns the forward destination of the most advanced threatened eligible pawn,
    /// provided that destination is a valid cell for safe-zone placement.
    private func chooseSafeZoneCell(for player: PlayerColor, in game: LudoGame) -> Position? {
        let currentPath = game.path(for: player)
        guard !currentPath.isEmpty else { return nil }

        let candidates = game.eligiblePawns.compactMap { pawnId -> (pathIndex: Int, dest: Position)? in
            guard let pawn = game.pawns[player]?.first(where: { $0.id == pawnId }),
                  let pos = pawn.positionIndex,
                  pos >= 0,
                  pos < currentPath.count else { return nil }

            // Only consider pawns that are currently threatened.
            guard isPawnThreatened(pawn: pawn, player: player, path: currentPath, game: game)
            else { return nil }

            // Forward destination with the current dice value.
            let destIdx = pos + game.diceValue
            guard destIdx < currentPath.count else { return nil }  // would overshoot home
            let dest = currentPath[destIdx]

            // Destination must be a valid placement cell.
            guard !game.isSafePosition(dest),           // not already safe (no need)
                  !game.isStartingHomeArea(dest),        // not a home corner
                  !game.trappedZones.contains(dest),     // not already a trap
                  !isOccupied(position: dest, in: game)  // not currently occupied by any pawn
            else { return nil }

            // Don't bother if the destination has an opponent — capture is better.
            if isOpponentAt(position: dest, in: game, excluding: player) { return nil }

            return (pos, dest)
        }
        .sorted { $0.pathIndex > $1.pathIndex }  // most advanced pawn first

        return candidates.first?.dest
    }

    private func isOccupied(position: Position, in game: LudoGame) -> Bool {
        for (_, playerPawns) in game.pawns {
            for pawn in playerPawns {
                if let idx = pawn.positionIndex, idx >= 0 {
                    let path = game.path(for: pawn.color)
                    if idx < path.count && path[idx] == position { return true }
                }
            }
        }
        return false
    }
}

// MARK: - BlueBoostSmartStrategy (Trap)

/// Bombergine / Jamun.
/// Deploys a trap on the square that the most opponents can reach in 1–6 rolls.
struct BlueBoostSmartStrategy: AILogicStrategy {
    private let base = SmartMoveStrategy()

    func useImmediateBoostIfNeeded(for player: PlayerColor, in game: LudoGame) -> Bool {
        guard game.getBoostState(for: player) == .available else { return false }
        guard let cell = chooseTrapCell(for: player, in: game) else { return false }

        GameLogger.shared.log("🤖 [AI BLUE BOOST] Deploying trap at (\(cell.row),\(cell.col)).")
        game.tapBoost(color: player)               // arm
        game.handleCellTap(row: cell.row, col: cell.col)   // place & consume
        return false   // pawn selection continues normally
    }

    func selectPawnMovementStrategy(
        from eligiblePawns: Set<Int>,
        for player: PlayerColor,
        in game: LudoGame
    ) -> AIPlayerMove? {
        base.selectPawnMovementStrategy(from: eligiblePawns, for: player, in: game)
    }

    /// Find the board cell with the highest number of opponents that could land on it in 1–6 rolls.
    private func chooseTrapCell(for player: PlayerColor, in game: LudoGame) -> Position? {
        var coverage: [Position: Int] = [:]

        for (opponentColor, opponentPawns) in game.pawns where opponentColor != player {
            let opponentPath = game.path(for: opponentColor)
            guard !opponentPath.isEmpty else { continue }
            for opponentPawn in opponentPawns {
                guard let oppIdx = opponentPawn.positionIndex,
                      oppIdx >= 0, oppIdx < opponentPath.count else { continue }
                for roll in 1...6 {
                    let targetIdx = oppIdx + roll
                    guard targetIdx < opponentPath.count else { break }
                    let target = opponentPath[targetIdx]
                    // Must be a deployable square
                    if !game.isSafePosition(target),
                       !game.isStartingHomeArea(target),
                       !game.trappedZones.contains(target),
                       !isPawnOccupied(position: target, in: game) {
                        coverage[target, default: 0] += 1
                    }
                }
            }
        }

        // Prefer cells farther from our own pawns to reduce self-trap risk.
        let ownPositions = ownBoardPositions(player: player, in: game)
        return coverage
            .sorted { a, b in
                // Primary: more opponents covered
                if a.value != b.value { return a.value > b.value }
                // Tiebreak: farther from own pawns
                let distA = ownPositions.map { manhattanDistance(from: a.key, to: $0) }.min() ?? 0
                let distB = ownPositions.map { manhattanDistance(from: b.key, to: $0) }.min() ?? 0
                return distA > distB
            }
            .first?.key
    }

    private func isPawnOccupied(position: Position, in game: LudoGame) -> Bool {
        for (_, playerPawns) in game.pawns {
            for pawn in playerPawns {
                if let idx = pawn.positionIndex, idx >= 0 {
                    let path = game.path(for: pawn.color)
                    if idx < path.count && path[idx] == position { return true }
                }
            }
        }
        return false
    }

    private func ownBoardPositions(player: PlayerColor, in game: LudoGame) -> [Position] {
        let path = game.path(for: player)
        return (game.pawns[player] ?? []).compactMap { pawn -> Position? in
            guard let idx = pawn.positionIndex, idx >= 0, idx < path.count else { return nil }
            return path[idx]
        }
    }

    private func manhattanDistance(from a: Position, to b: Position) -> Int {
        abs(a.row - b.row) + abs(a.col - b.col)
    }
}

// MARK: - Strategy factory

/// Returns the appropriate AI strategy for the given pawn asset name.
func aiStrategy(for avatarName: String) -> AILogicStrategy {
    guard let ability = BoostRegistry.ability(for: avatarName) else {
        return SmartMoveStrategy()   // classic / no-boost pawn
    }
    switch ability.kind {
    case .extraBackwardMove: return RedBoostSmartStrategy()
    case .rerollToSix:       return YellowBoostSmartStrategy()
    case .safeZone:          return GreenBoostSmartStrategy()
    case .trap:              return BlueBoostSmartStrategy()
    }
}
