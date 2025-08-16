import SwiftUI

struct SettingsTableView: View {
    @Binding var isAdminMode: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var gameCompletionCount: Int = GameStats.getGameCompletionCount()
    
    var body: some View {
        VStack(spacing: 0) {
            header
            settingsTable
        }
        .padding()
        .background(colorScheme == .dark ? Color.black : Color.white)
        .cornerRadius(15)
        .shadow(radius: 2)
        .frame(width: 300)
        .onChange(of: gameCompletionCount) { newValue in
            GameStats.setGameCompletionCount(newValue)
        }
    }
    
    private var header: some View {
        Text("Game Settings")
            .font(.headline)
            .foregroundColor(.blue)
            .padding(.bottom, 8)
    }
    
    private var settingsTable: some View {
        VStack(spacing: 0) {
            tableHeader
            adminModeRow
            gamesPlayedRow
        }
        .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var tableHeader: some View {
        HStack {
            Text("Mode")
                .font(.subheadline)
                .foregroundColor(.green)
            Spacer()
            Text("Status")
                .font(.subheadline)
                .foregroundColor(.yellow)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1))
    }
    
    private var adminModeRow: some View {
        HStack {
            Text("Admin Mode")
                .font(.body)
                .foregroundColor(PlayerColor.red.primaryColor)
            Spacer()
            Toggle("", isOn: $isAdminMode)
                .labelsHidden()
                .tint(PlayerColor.red.primaryColor)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
    
    private var gamesPlayedRow: some View {
        HStack {
            Text("Games Played")
                .font(.body)
                .foregroundColor(PlayerColor.blue.primaryColor)
            Spacer()
            Stepper(value: $gameCompletionCount, in: 0...100) {
                Text("\(gameCompletionCount)")
            }
            .tint(PlayerColor.blue.primaryColor)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
} 
