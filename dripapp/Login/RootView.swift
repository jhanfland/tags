import SwiftUI
import Firebase
import FirebaseAuth

struct RootView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var userManager: UserManager
    @State private var isInitialized = false
    
    var body: some View {
        Group {
            if isInitialized {
                if !authManager.isUserLoggedIn {
                    SignInView()
                        .transition(.opacity)
                } else {
                    MainTabView()
                        .transition(.opacity)
                }
            } else {
                // Loading view while checking auth state
                ZStack {
                    Color.white.edgesIgnoringSafeArea(.all)
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                }
            }
        }
        .animation(.easeInOut, value: authManager.isUserLoggedIn)
        .animation(.easeInOut, value: isInitialized)
        .onAppear {
            authManager.checkCurrentUser()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    isInitialized = true
                }
            }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(AuthenticationManager.shared)
            .environmentObject(UserManager.shared)
    }
}
