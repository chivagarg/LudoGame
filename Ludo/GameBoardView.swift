import SwiftUI

struct GameBoardView: View {
    @EnvironmentObject var game: LudoGame
    
    var body: some View {
        VStack(spacing: 16) {
            if game.isAdminMode {
                AdminControlsView(
                    currentPlayer: game.currentPlayer,
                    eligiblePawns: game.eligiblePawns,
                    onTestRoll: { value in
                        game.testRollDice(value: value)
                    }
                )
            }
            
            LudoBoardView()
        }
    }
} 
