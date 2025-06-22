import SwiftUI

enum PlayerColor: String, CaseIterable, Identifiable {
    case red, green, yellow, blue
    var id: String { rawValue }
    
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
    
    var color: Color {
        switch self {
        case .red: return .red
        case .green: return .green
        case .yellow: return .yellow
        case .blue: return .blue
        }
    }
} 
