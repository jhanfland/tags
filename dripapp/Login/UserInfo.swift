import SwiftUI
import Firebase
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import CryptoKit
import FirebaseFirestore

struct UserInfo: Codable, Identifiable, Equatable {
    let id: String
    var firstName: String
    var lastName: String
    var username: String
    var email: String
    var phone: String
    var address: String
    var gender: Gender
    var topSizes: Set<String>
    var bottomSizes: Set<String>
    var shoeSizes: Set<String>
    var sellerRating: Double
    var salesCount: Int
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    static func == (lhs: UserInfo, rhs: UserInfo) -> Bool {
        return lhs.id == rhs.id &&
               lhs.firstName == rhs.firstName &&
               lhs.lastName == rhs.lastName &&
               lhs.username == rhs.username &&
               lhs.email == rhs.email &&
               lhs.phone == rhs.phone &&
               lhs.address == rhs.address &&
               lhs.gender == rhs.gender &&
               lhs.topSizes == rhs.topSizes &&
               lhs.bottomSizes == rhs.bottomSizes &&
               lhs.shoeSizes == rhs.shoeSizes &&
               lhs.sellerRating == rhs.sellerRating &&
               lhs.salesCount == rhs.salesCount
    }
}

class UserManager: ObservableObject {
    @Published var currentUser: UserInfo?
    @Published var isOnboardingComplete: Bool = false
    static let shared = UserManager()
    private let db = Firestore.firestore()
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadCachedUserInfo()
    }
    
    func createUser(_ user: UserInfo, completion: @escaping (Result<Void, Error>) -> Void) {
        let userData: [String: Any] = [
            "firstName": user.firstName,
            "lastName": user.lastName,
            "username": user.username,
            "gender": user.gender.rawValue,
            "topSizes": Array(user.topSizes),
            "bottomSizes": Array(user.bottomSizes),
            "shoeSizes": Array(user.shoeSizes),
            "email": user.email,
            "phone": user.phone,
            "address": user.address,
            "sellerRating": user.sellerRating,
            "salesCount": user.salesCount
        ]

        db.collection("users").document(user.id).setData(userData) { [weak self] error in
            if let error = error {
                completion(.failure(error))
            } else {
                self?.isOnboardingComplete = true
                self?.currentUser = user
                self?.cacheUserInfo(user)
                completion(.success(()))
            }
        }
    }

    func fetchUserInfo(userId: String, completion: @escaping (Result<UserInfo, Error>) -> Void) {
        let userRef = db.collection("users").document(userId)

        userRef.getDocument { [weak self] (document, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let document = document, document.exists, let data = document.data() else {
                completion(.failure(NSError(domain: "UserManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "User document not found"])))
                return
            }

            do {
                var userData = data
                userData["id"] = userId
                let jsonData = try JSONSerialization.data(withJSONObject: userData, options: [])
                let decodedUser = try JSONDecoder().decode(UserInfo.self, from: jsonData)

                DispatchQueue.main.async {
                    self?.currentUser = decodedUser
                    self?.cacheUserInfo(decodedUser)
                }
                completion(.success(decodedUser))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func updateUser(_ user: UserInfo, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "UserManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }

        let userData: [String: Any] = [
            "firstName": user.firstName,
            "lastName": user.lastName,
            "username": user.username,
            "gender": user.gender.rawValue,
            "topSizes": Array(user.topSizes),
            "bottomSizes": Array(user.bottomSizes),
            "shoeSizes": Array(user.shoeSizes),
            "email": user.email,
            "phone": user.phone,
            "address": user.address,
            "sellerRating": user.sellerRating,
            "salesCount": user.salesCount
        ]

        db.collection("users").document(userId).setData(userData, merge: true) { [weak self] error in
            if let error = error {
                completion(.failure(error))
            } else {
                self?.currentUser = user
                self?.cacheUserInfo(user)
                completion(.success(()))
            }
        }
    }

    func cacheUserInfo(_ user: UserInfo) {
        do {
            let encodedData = try JSONEncoder().encode(user)
            userDefaults.set(encodedData, forKey: "cachedUserInfo")
        } catch {
            // Handle error if necessary
        }
    }

    func loadCachedUserInfo() {
        if let cachedData = userDefaults.data(forKey: "cachedUserInfo") {
            do {
                let decodedUser = try JSONDecoder().decode(UserInfo.self, from: cachedData)
                self.currentUser = decodedUser
            } catch {
                // Handle error if necessary
            }
        }
    }

    func clearCachedUserInfo() {
        userDefaults.removeObject(forKey: "cachedUserInfo")
        self.currentUser = nil
    }
}

class AuthenticationManager: ObservableObject {
    @Published var isUserLoggedIn: Bool = false
    @Published var currentUser: User?
    @Published var isNewUser: Bool = false
    @Published var userInfo: UserInfo?

    private var currentNonce: String?
    private let db = Firestore.firestore()
    private let userManager = UserManager.shared

    static let shared = AuthenticationManager()

    private init() {
        setupGoogleSignIn()
        checkCurrentUser()
    }

    func getCurrentUserId() -> String? {
        return Auth.auth().currentUser?.uid
    }

    func checkCurrentUser() {
        if let user = Auth.auth().currentUser {
            self.currentUser = user
            self.isUserLoggedIn = true
            fetchUserInfo(userId: user.uid)
        } else {
            self.isUserLoggedIn = false
            self.currentUser = nil
            self.userInfo = nil
            self.isNewUser = true
        }
    }

    private func fetchUserInfo(userId: String) {
        userManager.fetchUserInfo(userId: userId) { [weak self] result in
            switch result {
            case .success(let userInfo):
                DispatchQueue.main.async {
                    self?.userInfo = userInfo
                    self?.isNewUser = false
                    self?.userManager.currentUser = userInfo
                    self?.userManager.cacheUserInfo(userInfo)
                }
            case .failure:
                DispatchQueue.main.async {
                    self?.isNewUser = true
                }
            }
        }
    }

    func updateUserInfo(_ updatedInfo: UserInfo, completion: @escaping (Result<Void, Error>) -> Void) {
        userManager.updateUser(updatedInfo) { [weak self] result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self?.userInfo = updatedInfo
                }
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func completeOnboarding(username: String) {
        isNewUser = false
        isUserLoggedIn = true
        if let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest() {
            changeRequest.displayName = username
            changeRequest.commitChanges { error in
                // Handle error if necessary
            }
        }
    }

    private func setupGoogleSignIn() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            return
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    }

    func signInWithGoogle(completion: @escaping (Bool) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(false)
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            completion(false)
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            if let _ = error {
                completion(false)
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                completion(false)
                return
            }
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            self?.authenticateWithFirebase(credential) { success in
                completion(success)
            }
        }
    }

    private func authenticateWithFirebase(_ credential: AuthCredential, completion: @escaping (Bool) -> Void) {
        Auth.auth().signIn(with: credential) { [weak self] (authResult, _) in
            self?.currentUser = authResult!.user
            self?.db.collection("users").document(authResult!.user.uid).getDocument { (document, _) in
                self?.isNewUser = document!.exists ? false : true
                self?.fetchUserInfo(userId: authResult!.user.uid)
                completion(true)
            }
        }
    }

    func handleAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>, completion: @escaping (Bool) -> Void) {
        switch result {
        case .success(let authResult):
            guard let appleIDCredential = authResult.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = currentNonce,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                completion(false)
                return
            }

            let credential = OAuthProvider.credential(
                                           providerID: .apple,
                                           idToken: idTokenString,
                                           rawNonce: nonce
                                       )
            authenticateWithFirebase(credential, completion: completion)
        case .failure:
            completion(false)
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isUserLoggedIn = false
            self.currentUser = nil
            self.userInfo = nil
            self.isNewUser = true
            userManager.clearCachedUserInfo()
        } catch {
            // Handle error if necessary
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if status != errSecSuccess {
                fatalError("Unable to generate nonce")
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random % UInt8(charset.count))])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

extension Notification.Name {
    static let userLoggedIn = Notification.Name("userLoggedIn")
}
