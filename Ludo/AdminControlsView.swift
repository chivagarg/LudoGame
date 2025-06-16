import SwiftUI

struct AdminControlsView: View {
    let currentPlayer: PlayerColor
    let eligiblePawns: Set<Int>
    let onTestRoll: (Int) -> Void
    
    var body: some View {
        VStack {
            Text("Current Player: \(currentPlayer.rawValue.capitalized)")
                .font(.title2)
            
            HStack {
                ForEach([1, 2, 3, 4, 5, 6, 48, 56], id: \.self) { value in
                    Button("\(value)") {
                        onTestRoll(value)
                    }
                    .font(.title3)
                    .padding(8)
                    .background(eligiblePawns.isEmpty ? (value == 48 || value == 56 ? Color.purple : Color.green) : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(!eligiblePawns.isEmpty)
                }
            }
            
            if let logFileURL = GameLogger.shared.logFileURL {
                if #available(iOS 16.0, *) {
                    ShareLink(
                        item: logFileURL,
                        subject: Text("Ludo Game Log"),
                        message: Text("Here is the log from the last Ludo game session."),
                        label: {
                            Label("Share Game Log", systemImage: "square.and.arrow.up")
                        }
                    )
                    .padding()
                } else {
                    // Fallback on earlier versions
                }
            }
        }
    }
} 
