import Foundation

enum GameCopy {
    enum Common {
        static let ok = "OK"
        static let coins = "coins"
        static let robot = "Robot"
        static let playNow = "Play now"
        static let unlockNow = "Unlock Now!"
        static let invalidMoveTitle = "Invalid Move"
    }
				
    enum DeploymentErrors {
        static let ineligibleSafeZone = "This spot is ineligible to deploy (Safe Zone). Select an unoccupied spot on the board."
        static let ineligibleStartingHome = "This spot is ineligible to deploy (Starting Home). Select an unoccupied spot on the board."
        static let ineligibleTrapPresent = "This spot is ineligible to deploy (Trap is present). Select an unoccupied spot on the board."
        static let ineligibleOccupied = "This spot is ineligible to deploy (Occupied by Pawn). Select an unoccupied spot on the board."
    }

    enum MirchiErrors {
        static let cannotGoPastStart = "You cannot move backward past the starting position. Disable the Mirchi to move forward."
        static let cannotMoveBackwardInEndingStrip = "You cannot move backward while this pawn is in the ending safety strip."
    }

    enum StartGame {
        static let heroKicker = "It's time to play"
        static let heroTitle = "Ludo Mirchi!"
        static let heroDescription = "Each player gets 5 mirchis to hop backwards. Catch your opponents before they catch you."
        static let unlockProgressTitle = "You’re on your way to unlocking a new pawn!"
        static let nextUp = "Next up"
        static let allUnlocked = "All pawns unlocked!"
        static let mirchiModeIphTitle = "Mirchi Mode"
        static let mirchiModeIphMessage = "Each player gets 5 chances to hop backwards during the game. Activate mirchi mode by tapping this button before selecting a pawn on your turn."

        static func almostThere(_ progressText: String) -> String {
            "Almost there! \(progressText)"
        }
    }

    enum PlayerSelection {
        static let gameOptions = "Game options"
        static let selectPawns = "Select your pawns"
        static let pawnsTab = "Pawns"

        static func playersCount(_ count: Int) -> String {
            "\(count) Players"
        }

        static func selectedPawnTitle(_ playerName: String) -> String {
            "\(playerName) pawn"
        }
    }

    enum CoinPurchaseModal {
        static func neededCoins(_ needed: String) -> String {
            "You need \(needed) more coins to unlock this pawn. Keep playing, or you can buy now to unlock immediately."
        }

        static func buyAndUnlockNow(price: String) -> String {
            "Buy and unlock now for \(price)"
        }

        static func unlocking(_ pawnTitle: String) -> String {
            "Unlocking \(pawnTitle)…"
        }
    }

    enum PawnUnlockModal {
        static func unlockedTitle(_ pawnTitle: String) -> String {
            "You've unlocked \(pawnTitle)!"
        }

        static func whereToFind(_ pawnTitle: String) -> String {
            "Find \(pawnTitle) in the pawn selection in your next game!"
        }
    }

    enum BoostUnavailableIph {
        static let title = "Boost unavailable"
        static let message = "Boosts are special powers that only certain pawns have (this pawn doesn't). Keep playing to unlock pawns with boost abilities."
    }

    enum PawnBoostIph {
        static func title(_ pawnTitle: String) -> String {
            "\(pawnTitle) Boost"
        }

        static func message(boostDescription: String, uses: Int) -> String {
            let usesLine = uses == 1 ? "You can use this boost once per game." : "You can use this boost \(uses) times per game."
            return "\(boostDescription) Tap the Boost button on your turn to use it. \(usesLine)"
        }
    }

    enum GameOver {
        static let title = "Game Over"
        static let subtitle = "Final Standings"
        static let winner = "Winner"
        static let exitGame = "Exit Game"

        static func avgRoll(_ value: Double) -> String {
            String(format: "%.1f avg roll", value)
        }

        static func coinsEarned(_ value: Int) -> String {
            "+\(max(0, value)) coins earned"
        }

        static func points(_ value: Int) -> String {
            "\(value) pts"
        }
    }

    enum Splash {
        static let leading = "m"
        static let trailing = "rchi labs"
    }

    enum Settings {
        static let title = "Game Settings"
        static let mode = "Mode"
        static let status = "Status"
        static let adminMode = "Admin Mode"
    }

    enum PauseDialog {
        static let resume = "Resume"
        static let restart = "Restart"
        static let exitGame = "Exit Game"
    }

    enum PlayerPanel {
        static let boostLabel = "Boost"
        static let mirchiModeLabel = "Mirchi mode"
        static let totalPointsLabel = "Total points"
        static let totalKillsLabel = "Total kills"
    }

    enum Admin {
        static let coinsPlaceholder = "Coins"
        static let set = "Set"
        static let endGame = "End Game"
        static let resetUnlocks = "Reset Unlocks"
        static let resetToFirstRun = "Reset To First Run"
        static let shareLogSubject = "Ludo Game Log"
        static let shareLogMessage = "Here is the log from the last Ludo game session."
    }
}
