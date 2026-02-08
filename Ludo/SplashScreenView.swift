import SwiftUI

struct SplashScreenView: View {
    @State private var isBouncing = false

    var body: some View {
        GeometryReader { geometry in
            let fontSize = geometry.size.width * 0.1
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("m")
                    Image("pawn_mirchi_splash")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: fontSize)
                        .padding(.horizontal, -fontSize * 0.15)
                        .offset(y: fontSize * 0.15 + (isBouncing ? -fontSize * 0.2 : 0))
                    Text("rchi labs")
                }
                .font(.custom("Chalkboard SE", size: fontSize))
                .foregroundColor(.red)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                isBouncing = true
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
