import SwiftUI

struct GameBoardView: View {
    @EnvironmentObject var game: LudoGame
    
    var body: some View {
        ZStack {
            if game.isAdminMode {
                VStack(spacing: 16) {
                    AdminControlsView(
                        currentPlayer: game.currentPlayer,
                        eligiblePawns: game.eligiblePawns,
                        onTestRoll: { value in
                            game.testRollDice(value: value)
                        }
                    )
                    LudoBoardView(maximized: false)
                }
            } else {
                LudoBoardView(maximized: true)
            }
        }
    }
} 
