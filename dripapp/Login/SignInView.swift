import SwiftUI
import Firebase
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import CryptoKit

struct SignInView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isAnimating = false
    @State private var shouldNavigateToHome = false
    @State private var shouldNavigateToOnboarding = false

    // Custom Carolina Blue color
    let carolinaBlue = Color(red: 46/255, green: 117/255, blue: 92/255)
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.blue.opacity(0.1)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer()
                    
                    // Tags title
                    Text("Tags")
                        .font(.system(size: 65, weight: .bold))
                        .foregroundColor(carolinaBlue)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : -50)
                    
                    Spacer()
                    
                    VStack(spacing: 20) {
                        // Sign in with Google button
                        Button(action: {
                            authManager.signInWithGoogle { success in
                                if success {
                                    navigateAfterSignIn()
                                }
                            }
                        }) {
                            HStack {
                                Image("google")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)
                                Text("Sign in with Google")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                        }
                        
                        // Sign in with Apple button
                        HStack {
                            SignInWithAppleButton(
                                .signIn,
                                onRequest: { request in
                                    authManager.handleAppleSignInRequest(request)
                                },
                                onCompletion: { result in
                                    authManager.handleAppleSignInCompletion(result) { success in
                                        if success {
                                            navigateAfterSignIn()
                                        }
                                    }
                                }
                            )
                            .signInWithAppleButtonStyle(.black)
                            .frame(height: 50)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 40)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 50)
                }
                .padding(.bottom, 50)
            }
            .navigationDestination(isPresented: $shouldNavigateToHome) {
                HomeView()
            }
            .navigationDestination(isPresented: $shouldNavigateToOnboarding) {
                OnboardingView()
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.6)) {
                isAnimating = true
            }
        }
    }
    
    private func navigateAfterSignIn() {
            if authManager.isNewUser {
                self.shouldNavigateToOnboarding = true
            } else {
                self.shouldNavigateToHome = true
            }
        }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView().environmentObject(AuthenticationManager.shared)
    }
}
