import SwiftUI

struct TrailParticleView: View {
    let particle: TrailParticle
    let cellSize: CGFloat
    
    var body: some View {
        Circle()
            .fill(particle.color.color)
            .opacity(particle.opacity)
            .frame(width: cellSize * 0.3, height: cellSize * 0.3)
    }
}

#Preview {
    TrailParticleView(
        particle: TrailParticle(
            position: (row: 5, col: 5),
            color: .red,
            opacity: 0.6,
            age: 0.0,
            createdAt: Date()
        ),
        cellSize: 40
    )
} 
