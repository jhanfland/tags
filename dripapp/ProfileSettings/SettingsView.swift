import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var address: String = ""
    @State private var username: String = ""
    @State private var topSizes: Set<String> = []
    @State private var bottomSizes: Set<String> = []
    @State private var shoeSizes: Set<String> = []
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingSizeSelector: SearchView.SizeType?
    @FocusState private var focusedField: Field?
    @StateObject private var addressCompleter = AddressCompleter()
    @State private var showingAddressSuggestions = false
    @State private var showSaveButton = false
    @State private var isSaving = false
    @EnvironmentObject var authManager: AuthenticationManager
    private let cashAppGreen = Color(red: 0, green: 202/255, blue: 64/255)

    @Environment(\.presentationMode) var presentationMode

    enum Field: Hashable {
        case name, email, phone, address
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .center, spacing: 20) {
                    // Header
                    HStack {
                        Spacer()
                        Text("@\(username)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .opacity(1.0)
                            .padding(.bottom, 5)
                        Spacer()
                    }
                    .padding(.bottom, -20)

                    SizeOptionsSection(
                        selectedTopSizes: $topSizes,
                        selectedBottomSizes: $bottomSizes,
                        selectedShoeSizes: $shoeSizes,
                        showingSizeSelector: $showingSizeSelector,
                        onUpdate: { showSaveButton = true }
                    )

                    ContactInformationSection(
                        name: $name,
                        email: $email,
                        phone: $phone,
                        address: $address,
                        addressCompleter: addressCompleter,
                        showingAddressSuggestions: $showingAddressSuggestions,
                        focusedField: $focusedField,
                        onUpdate: { showSaveButton = true }
                    )
                    
                    if let sizeType = showingSizeSelector {
                        SettingsSizeSelector(
                            sizeType: sizeType,
                            selectedSizes: binding(for: sizeType),
                            allSizes: sizesFor(sizeType),
                            onUpdate: { showSaveButton = true }
                        )
                    }
                    Spacer()
                    
                    // Help and Sign Out buttons
                    VStack(spacing: 15) {
                        Button(action: {
                            // Navigate to Help view
                        }) {
                            Text("Help")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(15)
                        }
                        .frame(height: 50)
                        
                        Button(action: {
                            showingAlert = true
                            alertTitle = "Sign Out"
                            alertMessage = "Are you sure you want to sign out?"
                        }) {
                            Text("Sign Out")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(15)
                        }
                        .frame(height: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                .padding()
            }
            
            if showSaveButton {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: updateUserInfo) {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                    .frame(width: 30, height: 30)
                            } else {
                                Text("Save")
                                    .foregroundColor(Color.blue.opacity(0.7))
                                    .font(.headline)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.trailing, 10)
                        .padding(.top, 10)
                    }
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                primaryButton: .destructive(Text("Sign Out")) {
                    signOut()
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear(perform: loadUserData)
    }

    private func loadUserData() {
        guard let currentUser = userManager.currentUser else { return }
        
        name = "\(currentUser.firstName) \(currentUser.lastName)"
        email = currentUser.email
        phone = currentUser.phone
        address = currentUser.address
        username = currentUser.username.lowercased()
        topSizes = currentUser.topSizes
        bottomSizes = currentUser.bottomSizes
        shoeSizes = currentUser.shoeSizes
    }

    private func updateUserInfo() {
        guard var updatedUser = userManager.currentUser else { return }
        
        isSaving = true
        
        let nameParts = name.split(separator: " ")
        updatedUser.firstName = String(nameParts.first ?? "")
        updatedUser.lastName = nameParts.count > 1 ? String(nameParts.dropFirst().joined(separator: " ")) : ""
        updatedUser.email = email
        updatedUser.phone = phone
        updatedUser.address = address
        updatedUser.username = username
        updatedUser.topSizes = topSizes
        updatedUser.bottomSizes = bottomSizes
        updatedUser.shoeSizes = shoeSizes

        userManager.updateUser(updatedUser) { result in
            DispatchQueue.main.async {
                isSaving = false
                switch result {
                case .success:
                    print("User info updated successfully")
                    showSaveButton = false
                case .failure(let error):
                    print("Error updating user info: \(error.localizedDescription)")
                    showError("Failed to update user information")
                }
            }
        }
    }

    private func binding(for sizeType: SearchView.SizeType) -> Binding<Set<String>> {
        switch sizeType {
        case .top: return $topSizes
        case .bottom: return $bottomSizes
        case .shoe: return $shoeSizes
        }
    }

    private func sizesFor(_ sizeType: SearchView.SizeType) -> [String] {
        switch sizeType {
        case .top: return CategoryData.topSizes
        case .bottom: return CategoryData.bottomSizes
        case .shoe: return CategoryData.shoeSizes
        }
    }

    private func showError(_ message: String) {
        alertTitle = "Error"
        alertMessage = message
        showingAlert = true
    }
    private func signOut() {
        do {
            try Auth.auth().signOut()
            authManager.isUserLoggedIn = false
        } catch let error {
            showError("Error signing out: \(error.localizedDescription)")
        }
    }
}

struct SizeOptionsSection: View {
    @Binding var selectedTopSizes: Set<String>
    @Binding var selectedBottomSizes: Set<String>
    @Binding var selectedShoeSizes: Set<String>
    @Binding var showingSizeSelector: SearchView.SizeType?
    var onUpdate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Spacer()
                ForEach(sizeTypeBindings(), id: \.type) { sizeBinding in
                    SettingsSizeButton(
                        type: sizeBinding.type,
                        selectedSizes: sizeBinding.selectedSizes,
                        showingSizeSelector: $showingSizeSelector,
                        onUpdate: onUpdate
                    )
                }
                Spacer()
            }
        }
        .padding(.top)
    }

    private func sizeTypeBindings() -> [(type: SearchView.SizeType, selectedSizes: Binding<Set<String>>)] {
        return [
            (type: .top, selectedSizes: $selectedTopSizes),
            (type: .bottom, selectedSizes: $selectedBottomSizes),
            (type: .shoe, selectedSizes: $selectedShoeSizes)
        ]
    }
}

struct SettingsSizeButton: View {
    let type: SearchView.SizeType
    @Binding var selectedSizes: Set<String>
    @Binding var showingSizeSelector: SearchView.SizeType?
    var onUpdate: () -> Void

    var body: some View {
        Button(action: {
            showingSizeSelector = (showingSizeSelector == type) ? nil : type
        }) {
            Text(buttonText)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.4), lineWidth: 2))
                .cornerRadius(15)
        }
    }

    private var buttonText: String {
        selectedSizes.isEmpty ? type.rawValue : selectedSizes.joined(separator: ", ")
    }
}

struct SettingsSizeSelector: View {
    let sizeType: SearchView.SizeType
    @Binding var selectedSizes: Set<String>
    let allSizes: [String]
    var onUpdate: () -> Void  // Add this line
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            ForEach(0..<(allSizes.count + 2) / 3, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { column in
                        let index = row * 3 + column
                        if index < allSizes.count {
                            sizeButton(for: allSizes[index])
                        } else {
                            Spacer().frame(width: 60, height: 40)
                        }
                    }
                }
            }
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity)
    }
    
    private func sizeButton(for size: String) -> some View {
        Button(action: {
            toggleSize(size)
            onUpdate()  // Call onUpdate when a size is toggled
        }) {
            Text(size)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(selectedSizes.contains(size) ? .blue : .black)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(selectedSizes.contains(size) ? Color.blue.opacity(0.1) : Color.white)
                .cornerRadius(15)
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.4), lineWidth: 2))
        }
    }
    
    private func toggleSize(_ size: String) {
        if selectedSizes.contains(size) {
            selectedSizes.remove(size)
        } else {
            selectedSizes.insert(size)
        }
    }
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
