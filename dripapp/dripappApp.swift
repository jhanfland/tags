import SwiftUI
import Firebase
import GoogleSignIn


@main
struct dripappApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var userManager = UserManager.shared
    @StateObject private var cartManager = CartManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(userManager)
                .environmentObject(cartManager)
                .preferredColorScheme(.light)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        setenv("GRPC_VERBOSITY", "ERROR", 1)
        setenv("GRPC_TRACE", "", 1)
        return true
    }
}
