import Foundation
import SwiftUI

class PawnState: ObservableObject, Identifiable, Equatable {
    let id: Int
    let color: PlayerColor
    @Published var positionIndex: Int? // nil = at home, 0...N = on path, -1 = finished

    init(id: Int, color: PlayerColor, positionIndex: Int?) {
        self.id = id
        self.color = color
        self.positionIndex = positionIndex
    }

    static func == (lhs: PawnState, rhs: PawnState) -> Bool {
        lhs.id == rhs.id && lhs.color == rhs.color && lhs.positionIndex == rhs.positionIndex
    }
} 
