import SwiftUI

struct SettingsTableView: View {
    @Binding var isAdminMode: Bool
    @Binding var isMirchiMode: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Game Settings")
                .font(.headline)
                .foregroundColor(.blue)
                .padding(.bottom, 8)
            
            // Settings Table
            VStack(spacing: 0) {
                // Table Header
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
                
                // Admin Mode Row
                HStack {
                    Text("Admin Mode")
                        .font(.body)
                        .foregroundColor(.red)
                    Spacer()
                    Toggle("", isOn: $isAdminMode)
                        .labelsHidden()
                        .tint(.red)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(colorScheme == .dark ? Color.black : Color.white)
                
                // Mirchi Mode Row
                HStack {
                    Text("Mirchi Mode")
                        .font(.body)
                        .foregroundColor(.orange)
                    Spacer()
                    Toggle("", isOn: $isMirchiMode)
                        .labelsHidden()
                        .tint(.orange)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(colorScheme == .dark ? Color.black : Color.white)
            }
            .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .padding()
        .background(colorScheme == .dark ? Color.black : Color.white)
        .cornerRadius(15)
        .shadow(radius: 2)
        .frame(width: 300)
    }
} 
