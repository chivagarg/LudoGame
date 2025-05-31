import SwiftUI

struct SettingsTableView: View {
    @Binding var isAdminMode: Bool
    @Binding var isMirchiMode: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            settingsTable
        }
        .padding()
        .background(colorScheme == .dark ? Color.black : Color.white)
        .cornerRadius(15)
        .shadow(radius: 2)
        .frame(maxWidth: 300)
        .onAppear {
            print("SettingsTableView appeared")
            print("Admin mode binding: \(isAdminMode)")
            print("Mirchi mode binding: \(isMirchiMode)")
        }
    }
    
    private var headerView: some View {
        Text("Game Settings")
            .font(.headline)
            .foregroundColor(.blue)
            .padding(.bottom, 8)
    }
    
    private var settingsTable: some View {
        VStack(spacing: 0) {
            tableHeader
            adminModeRow
            mirchiModeRow
        }
        .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            print("Settings table appeared")
            print("Mirchi mode binding value: \(isMirchiMode)")
            print("Admin mode binding value: \(isAdminMode)")
        }
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
                .foregroundColor(.red)
            Spacer()
            Toggle("", isOn: $isAdminMode)
                .labelsHidden()
                .tint(.red)
                .onChange(of: isAdminMode) { newValue in
                    print("Admin mode changed to: \(newValue)")
                }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(colorScheme == .dark ? Color.black : Color.white)
        .onAppear {
            print("Admin mode row appeared")
        }
    }
    
    private var mirchiModeRow: some View {
        HStack {
            Text("Mirchi Mode")
                .font(.body)
                .foregroundColor(.orange)
            Spacer()
            Toggle("", isOn: $isMirchiMode)
                .labelsHidden()
                .tint(.orange)
                .onChange(of: isMirchiMode) { newValue in
                    print("Mirchi mode changed to: \(newValue)")
                }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(colorScheme == .dark ? Color.black : Color.white)
        .onAppear {
            print("Mirchi mode row appeared")
        }
    }
}

struct SettingsTableView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsTableView(isAdminMode: .constant(false), isMirchiMode: .constant(false))
                .padding()
                .background(Color.gray.opacity(0.1))
                .previewDevice("iPad Pro (11-inch)")
                .previewInterfaceOrientation(.portrait)
            
            SettingsTableView(isAdminMode: .constant(false), isMirchiMode: .constant(false))
                .padding()
                .background(Color.gray.opacity(0.1))
                .preferredColorScheme(.dark)
                .previewDevice("iPad Pro (11-inch)")
                .previewInterfaceOrientation(.portrait)
        }
    }
} 
