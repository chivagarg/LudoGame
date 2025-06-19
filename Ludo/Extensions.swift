import SwiftUI

extension PlayerColor {
    func toSwiftUIColor(for color: PlayerColor) -> Color {
        switch self {
        case .red:
            return .red
        case .green:
            return .green
        case .yellow:
            return .yellow
        case .blue:
            return .blue
        }
    }
} 
