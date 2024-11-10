import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var userManager: UserManager
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var username = ""
    @State private var selectedGender: UserInfo.Gender = .all
    @State private var selectedTopSizes: Set<String> = []
    @State private var selectedBottomSizes: Set<String> = []
    @State private var selectedShoeSizes: Set<String> = []
    @State private var showingSizeSelector: SearchView.SizeType?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    Text("Welcome")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 50)

                    VStack(spacing: 20) {
                        HStack(spacing: 10) {
                            TextField("First Name", text: $firstName)
                                .modifier(CustomTextFieldStyle())
                            TextField("Last Name", text: $lastName)
                                .modifier(CustomTextFieldStyle())
                        }

                        HStack {
                            Text("@")
                                .foregroundColor(.gray)
                            TextField("username", text: $username)
                        }
                        .padding(.horizontal, 15)
                        .frame(height: 50)
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )

                        VStack(spacing: 20) {
                            Text("Select Gender")
                                .font(.headline)
                            GenderSelectionButton(selectedGender: $selectedGender)
                        }

                        VStack(spacing: 20) {
                            Text("My Sizes")
                                .font(.headline)

                            HStack {
                                SizeButton(type: .top, selectedSizes: $selectedTopSizes, showingSizeSelector: $showingSizeSelector)
                                SizeButton(type: .bottom, selectedSizes: $selectedBottomSizes, showingSizeSelector: $showingSizeSelector)
                                SizeButton(type: .shoe, selectedSizes: $selectedShoeSizes, showingSizeSelector: $showingSizeSelector)
                            }

                            if let sizeType = showingSizeSelector {
                                SizeSelectionGrid(
                                    sizeType: sizeType,
                                    selectedSizes: binding(for: sizeType),
                                    allSizes: sizesFor(sizeType)
                                )
                            }
                        }
                    }
                    .padding()

                    Spacer()

                    Button(action: createAccount) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Create Account")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.blue : Color.gray)
                    .cornerRadius(15)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                    .disabled(!isFormValid || isLoading)
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private var isFormValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !username.isEmpty
    }

    private func binding(for sizeType: SearchView.SizeType) -> Binding<Set<String>> {
        switch sizeType {
        case .top: return $selectedTopSizes
        case .bottom: return $selectedBottomSizes
        case .shoe: return $selectedShoeSizes
        }
    }

    private func sizesFor(_ sizeType: SearchView.SizeType) -> [String] {
        switch sizeType {
        case .top: return CategoryData.topSizes
        case .bottom: return CategoryData.bottomSizes
        case .shoe: return CategoryData.shoeSizes
        }
    }

    private func createAccount() {
        guard let userId = authManager.getCurrentUserId()else {
            print("Invalid URL")
            return
        }
        let apiKey = "84f3ca014fca8e0f3b24488da4fe1192"
        guard let url = URL(string: "http://api.nessieisreal.com/customers/\(userId)/accounts?key=\(apiKey)") else {
            print("Invalid URL")
            return
        }
        isLoading = true
        print("Starting account creation process...")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let accountDetails: [String: Any] = [
            "type": "Credit Card",
            "nickname": "My Credit Card",
            "rewards": 100,
            "balance": 5000,
            "account_number": userId
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: accountDetails, options: []) }
        catch {
            print("Error serializing JSON: \(error)")
            return
        }
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error making request: \(error)")
                    return
                }
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 201 {
                    print("Account created successfully.")
                } else {
                    print("Failed to create account. Status code: \(httpResponse.statusCode)")
                }
            }
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Response data: \(responseString)")
            }
        }
        task.resume()

        let newUser = UserInfo(
            id: userId,
            firstName: firstName,
            lastName: lastName,
            username: username,
            email: authManager.currentUser?.email ?? "",
            phone: "",
            address: "",
            gender: selectedGender,
            topSizes: selectedTopSizes,
            bottomSizes: selectedBottomSizes,
            shoeSizes: selectedShoeSizes,
            sellerRating: 0.0,
            salesCount: 0
        )

        userManager.createUser(newUser) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success:
                    print("Account created successfully")
                    self.authManager.completeOnboarding(username: self.username)
                    self.presentationMode.wrappedValue.dismiss()
                case .failure(let error):
                    print("Failed to create account: \(error.localizedDescription)")
                    self.showAlert(message: "Failed to create account. Please try again.")
                }
            }
        }
        
    }


    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}

struct CustomTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 15)
            .frame(height: 50)
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
    }
}

struct GenderSelectionButton: View {
    @Binding var selectedGender: UserInfo.Gender

    var body: some View {
        HStack(spacing: 20) {
            ForEach([UserInfo.Gender.mens, UserInfo.Gender.womens], id: \.self) { gender in
                Button(action: {
                    selectedGender = gender
                }) {
                    Text(gender.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selectedGender == gender ? .blue : .black)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(selectedGender == gender ? Color.blue.opacity(0.2) : Color.white)
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 2)
                        )
                }
            }
        }
        .padding(.bottom, 20)
    }
}

struct SizeSelectionGrid: View {
    let sizeType: SearchView.SizeType
    @Binding var selectedSizes: Set<String>
    let allSizes: [String]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 10) {
            ForEach(allSizes, id: \.self) { size in
                Button(action: {
                    if selectedSizes.contains(size) {
                        selectedSizes.remove(size)
                    } else {
                        selectedSizes.insert(size)
                    }
                }) {
                    Text(size)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selectedSizes.contains(size) ? .blue : .black)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(selectedSizes.contains(size) ? Color.blue.opacity(0.2) : Color.white)                    .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 2)
                        )
                }
            }
        }
    }
}
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
        .environmentObject(AuthenticationManager.shared)
        .environmentObject(UserManager.shared)
    }
}
