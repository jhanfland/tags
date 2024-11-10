import SwiftUI
import PhotosUI
import Firebase
import FirebaseStorage
import Kingfisher

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var userManager: UserManager
    @StateObject private var viewModel = ProfileViewModel()
    @State private var selectedTab = 0
    @State private var showingSettings = false
    @State private var isImagePickerPresented = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Profile Header
                ProfileHeader(
                    profileImage: $viewModel.profileUIImage, // Corrected to use Binding<UIImage?>
                    isImagePickerPresented: $isImagePickerPresented,
                    userInfo: viewModel.userInfo
                )
                .frame(height: 120)

                // Tab Selector
                Picker("", selection: $selectedTab) {
                    Text("Selling").tag(0)
                    Text("Saved").tag(1)
                    Text("Purchases").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // Item Grid
                TabView(selection: $selectedTab) {
                    ItemGrid(items: viewModel.sellingItems)
                        .tag(0)
                    ItemGrid(items: viewModel.savedItems)
                        .tag(1)
                    ItemGrid(items: viewModel.purchasedItems)
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.default, value: selectedTab)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .padding(.top, -40)
        }
        .onAppear {
            viewModel.loadProfileData(authManager: authManager, userManager: userManager)
        }
        .onChange(of: userManager.currentUser) { _, _ in
            viewModel.loadProfileData(authManager: authManager, userManager: userManager)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $isImagePickerPresented) {
            SharedImagePicker(image: $viewModel.profileUIImage, sourceType: .photoLibrary)
        }
        .preferredColorScheme(.light)
    }
}
struct ProfileHeader: View {
    @Binding var profileImage: UIImage? // Updated to use Binding<UIImage?>
    @Binding var isImagePickerPresented: Bool
    let userInfo: UserInfo?

    var body: some View {
        HStack {
            ProfileImageView(profileImage: $profileImage, isImagePickerPresented: $isImagePickerPresented)

            VStack(alignment: .leading) {
                Text("\(userInfo?.firstName ?? "") \(userInfo?.lastName ?? "")")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("@\(userInfo?.username ?? "")")
                    .foregroundColor(.gray)
            }

            Spacer()

            SellerRatingView(sellerRating: userInfo?.sellerRating ?? 0, salesCount: userInfo?.salesCount ?? 0)
        }
        .padding()
    }
}


struct ProfileImageView: View {
    @Binding var profileImage: UIImage? // Updated to use Binding<UIImage?>
    @Binding var isImagePickerPresented: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 80)

            if let profileImage = profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(.gray)
            }
        }
        .onTapGesture {
            isImagePickerPresented = true
        }
    }
}

struct SellerRatingView: View {
    let sellerRating: Double
    let salesCount: Int

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 4) {
                Text(String(format: "%.1f%%", sellerRating))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.blue)
            }
            Text("\(salesCount) sales")
                .font(.system(size: 12))
                .foregroundColor(.blue)
        }
    }
}

struct ItemGrid: View {
    let items: [ItemData]
    let placeholderCount: Int = 18 // Total number of grid items to show

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(0..<placeholderCount, id: \.self) { index in
                    if index < items.count {
                        NavigationLink(destination: ItemDetailView(item: items[index])) {
                            ItemThumbnail(item: items[index])
                        }
                    } else {
                        PlaceholderItem()
                    }
                }
            }
            .padding()
        }
    }
}

struct ItemThumbnail: View {
    let item: ItemData

    var body: some View {
        Group {
            if let imageUrlString = item.imageUrls?.first, let imageUrl = URL(string: imageUrlString) {
                KFImage(imageUrl)
                    .resizable()
                    .placeholder {
                        ProgressView()
                    }
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                PlaceholderItem()
            }
        }
    }
}

struct PlaceholderItem: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.gray.opacity(0.3))
            .aspectRatio(0.88, contentMode: .fit)
    }
}

class ProfileViewModel: ObservableObject {
    @Published var userInfo: UserInfo?
    @Published var profileImageURL: URL?
    @Published var profileUIImage: UIImage?
    @Published var sellingItems: [ItemData] = []
    @Published var savedItems: [ItemData] = []
    @Published var purchasedItems: [ItemData] = []

    private let firebaseManager = FirebaseProductManager()
    private let db = Firestore.firestore()
    
    // Removed redundant storage reference since it's handled in uploadProfileImage

    func loadProfileData(authManager: AuthenticationManager, userManager: UserManager) {
        guard let userId = authManager.getCurrentUserId() else {
            print("Error: No authenticated user ID")
            return
        }
        
        print("Loading profile data for user: \(userId)")
        
        // Use existing cached user info if available
        if let cachedUser = userManager.currentUser {
            print("Using cached user info")
            self.userInfo = cachedUser
            loadItems(userId: userId)
            return
        }
        
        // Otherwise fetch from Firestore
        fetchUserInfo(userId: userId)
        loadItems(userId: userId)
    }

    private func fetchUserInfo(userId: String) {
        print("Fetching user info from Firestore for ID: \(userId)")
        
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching user info: \(error)")
                return
            }
            
            if let snapshot = snapshot, let data = snapshot.data() {
                print("Received user data: \(data)")
                
                // Create mutable copy and ensure ID is set
                var userData = data
                userData["id"] = userId
                
                do {
                    // Use custom decoder to handle the specific field mappings
                    let decoder = Firestore.Decoder()
                    let userInfo = try decoder.decode(UserInfo.self, from: userData)
                    
                    print("Successfully decoded user info - Name: \(userInfo.firstName) \(userInfo.lastName), Username: \(userInfo.username)")
                    
                    DispatchQueue.main.async {
                        self?.userInfo = userInfo
                    }
                } catch {
                    print("Error decoding user info: \(error)")
                }
            } else {
                print("No user document found for ID: \(userId)")
            }
        }
    }

    private func loadItems(userId: String) {
        print("Loading items for user: \(userId)")
        
        // Load all items in parallel using async/await
        Task { @MainActor in
            async let sellingTask = firebaseManager.fetchProducts(for: userId)
            async let savedTask = fetchSavedItems(for: userId)
            async let purchasedTask = fetchPurchasedItems(for: userId)
            
            do {
                // Wait for all tasks to complete
                let (selling, saved, purchased) = try await (sellingTask, savedTask, purchasedTask)
                
                // Update UI
                self.sellingItems = selling
                self.savedItems = saved
                self.purchasedItems = purchased
                
                print("Successfully loaded all items - Selling: \(selling.count), Saved: \(saved.count), Purchased: \(purchased.count)")
            } catch {
                print("Error loading items: \(error)")
            }
        }
    }

    private func fetchSavedItems(for userId: String) async throws -> [ItemData] {
        print("Fetching saved items")
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("savedItems")
            .getDocuments()
        
        return try snapshot.documents.compactMap { doc in
            var data = doc.data()
            data["id"] = doc.documentID
            return try Firestore.Decoder().decode(ItemData.self, from: data)
        }
    }

    private func fetchPurchasedItems(for userId: String) async throws -> [ItemData] {
        print("Fetching purchased items")
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("purchasedItems")
            .getDocuments()
        
        return try snapshot.documents.compactMap { doc in
            var data = doc.data()
            data["id"] = doc.documentID
            return try Firestore.Decoder().decode(ItemData.self, from: data)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AuthenticationManager.shared)
            .environmentObject(UserManager.shared)
    }
}
