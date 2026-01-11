import Foundation

// MARK: - Boost core models

enum BoostKind: String, Equatable {
    case mangoRerollToSix
    case mirchiExtraBackwardMove
}

enum BoostState: Equatable {
    case available
    case armed
    case used
}

/// Context passed to boost abilities so they can make decisions without depending on UI.
/// Keep this small and grow it as new boost types require more information.
struct BoostContext {
    let currentPlayer: PlayerColor
    let isBusy: Bool
    let isAIControlled: Bool
}

protocol BoostAbility {
    var kind: BoostKind { get }
    var iconSystemName: String { get }

    /// Whether this boost can ever be used for this avatar.
    func isCompatible(with avatarName: String) -> Bool

    /// Whether boost can be armed right now.
    func canArm(context: BoostContext) -> Bool

    /// Toggle behavior when the boost button is tapped.
    func onTap(currentState: BoostState) -> BoostState

    /// Whether to consume the boost when a pawn is tapped (common rule today).
    /// Some future boosts may prefer different consumption timing.
    func shouldConsumeOnPawnTap(context: BoostContext, currentState: BoostState) -> Bool
}

extension BoostAbility {
    var iconSystemName: String { "bolt.fill" }

    func onTap(currentState: BoostState) -> BoostState {
        switch currentState {
        case .available: return .armed
        case .armed: return .available
        case .used: return .used
        }
    }

    func shouldConsumeOnPawnTap(context: BoostContext, currentState: BoostState) -> Bool {
        // Default behavior: if it's armed and it's your turn, consume when you tap a pawn to move.
        return currentState == .armed
    }
}

// MARK: - Registry

enum BoostRegistry {
    /// Returns the boost ability for an avatar name, if any.
    static func ability(for avatarName: String) -> (any BoostAbility)? {
        // These are placeholders for now; we’ll implement their real effects next.
        if avatarName.contains("mango") { return MangoRerollToSixBoost() }
        if avatarName.contains("mirchi") { return MirchiExtraBackwardMoveBoost() }
        return nil
    }
}

// MARK: - Placeholder abilities (no special effects yet)

struct MangoRerollToSixBoost: BoostAbility {
    let kind: BoostKind = .mangoRerollToSix
    func isCompatible(with avatarName: String) -> Bool { avatarName.contains("mango") }
    func canArm(context: BoostContext) -> Bool { !context.isBusy && !context.isAIControlled }
    func shouldConsumeOnPawnTap(context: BoostContext, currentState: BoostState) -> Bool { currentState == .armed }
}

struct MirchiExtraBackwardMoveBoost: BoostAbility {
    let kind: BoostKind = .mirchiExtraBackwardMove
    func isCompatible(with avatarName: String) -> Bool { avatarName.contains("mirchi") }
    func canArm(context: BoostContext) -> Bool { !context.isBusy && !context.isAIControlled }
    func shouldConsumeOnPawnTap(context: BoostContext, currentState: BoostState) -> Bool { currentState == .armed }
}


