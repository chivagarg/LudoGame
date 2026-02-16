import SwiftUI

struct AdminControlsView: View {
    let eligiblePawns: Set<Int>
    let selectedPlayers: Set<PlayerColor>
    let currentScores: [PlayerColor: Int]
    let onTestRoll: (Int) -> Void
    let onEndGame: ([PlayerColor: Int]) -> Void
    
    @State private var scoreInputs: [PlayerColor: String] = [:]
    
    private var orderedSelectedPlayers: [PlayerColor] {
        PlayerColor.allCases.filter { selectedPlayers.contains($0) }
    }
    
    private func syncScoreInputsFromGame() {
        var next: [PlayerColor: String] = [:]
        for color in orderedSelectedPlayers {
            next[color] = String(currentScores[color] ?? 0)
        }
        scoreInputs = next
    }
    
    private func parsedScores() -> [PlayerColor: Int] {
        var parsed: [PlayerColor: Int] = [:]
        for color in orderedSelectedPlayers {
            let raw = (scoreInputs[color] ?? "0").trimmingCharacters(in: .whitespacesAndNewlines)
            parsed[color] = max(0, Int(raw) ?? 0)
        }
        return parsed
    }
    
    var body: some View {
        HStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach([1, 2, 3, 4, 5, 6, 48, 56], id: \.self) { value in
                        Button("\(value)") {
                            onTestRoll(value)
                        }
                        .font(.footnote.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(eligiblePawns.isEmpty ? (value == 48 || value == 56 ? Color.purple : PlayerColor.green.primaryColor) : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(!eligiblePawns.isEmpty)
                    }

                    HStack(spacing: 8) {
                        ForEach(orderedSelectedPlayers, id: \.self) { color in
                            HStack(spacing: 5) {
                                Text(String(color.rawValue.prefix(1)).uppercased())
                                    .font(.footnote.bold())
                                    .frame(width: 16)

                                TextField("0", text: Binding(
                                    get: { scoreInputs[color] ?? "0" },
                                    set: { scoreInputs[color] = $0 }
                                ))
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.footnote)
                                .frame(width: 60)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.95)))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }

            // Keep critical actions always visible on compact screens.
            HStack(spacing: 8) {
                Button("End Game") {
                    onEndGame(parsedScores())
                }
                .font(.footnote.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)

                if let logFileURL = GameLogger.shared.logFileURL {
                    if #available(iOS 16.0, *) {
                        ShareLink(
                            item: logFileURL,
                            subject: Text("Ludo Game Log"),
                            message: Text("Here is the log from the last Ludo game session."),
                            label: {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.footnote.bold())
                                    .padding(9)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.95)))
                            }
                        )
                    }
                }
            }
            .padding(.trailing, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            syncScoreInputsFromGame()
        }
        .onChange(of: selectedPlayers) { _ in
            syncScoreInputsFromGame()
        }
    }
} 
