import SwiftUI

@main
struct LudoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var isShowingSplash = true

    var body: some Scene {
        WindowGroup {
            if isShowingSplash {
                SplashScreenView()
                    .onAppear {
                        #if DEBUG
                        let delay = 5.0
                        #else
                        let delay = 3.0
                        #endif
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            withAnimation {
                                self.isShowingSplash = false
                            }
                        }
                    }
            } else {
                LudoGameView()
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return [.portrait, .portraitUpsideDown]
    }
} 
