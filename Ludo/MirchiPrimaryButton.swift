import SwiftUI

struct MirchiPrimaryButton: View {
    let title: String
    var isFullWidth: Bool = false
    let action: () -> Void
    
    private let backgroundColor = Color(red: 0x92/255, green: 0x5F/255, blue: 0xF0/255)
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: isFullWidth ? .infinity : nil)
                .padding(.vertical, 14)
                .padding(.horizontal, 32)
                .background(backgroundColor)
                .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}


