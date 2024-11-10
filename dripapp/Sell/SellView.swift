// Add comment: Optimized SellView using shared components and reduced redundancy
import SwiftUI
import Firebase
import FirebaseAuth
import Kingfisher

struct SellView: View {
    @State private var activeListings = 0
    @State private var soldItems = 0
    @State private var totalEarnings = 0.00
    @State private var showingAddClothes = false
    @State private var savedItems: [ItemData] = []
    @StateObject private var openAIManager = OpenAIManager()
    @StateObject private var firebaseManager = FirebaseProductManager()
    @State private var selectedItem: ItemData?
    @State private var showingItemPopup = false
    
    let currentUserId = Auth.auth().currentUser?.uid ?? "currentUserID"
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // Header
                    Text("Dashboard")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    // Dashboard Stats
                    HStack(spacing: 30) {
                        ForEach([
                            ("Active", "\(activeListings)"),
                            ("Sold", "\(soldItems)"),
                            ("Total", "$\(String(format: "%.2f", totalEarnings))")
                        ], id: \.0) { item in
                            SharedDashboardItem(title: item.0, value: item.1)
                        }
                    }
                    
                    // Items List
                    if savedItems.isEmpty {
                        Text("No items listed yet")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(savedItems) { item in
                                SharedCompactItemRow(
                                    item: item,
                                    onTap: {
                                        selectedItem = item
                                        showingItemPopup = true
                                    }
                                )
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                            .onDelete(perform: deleteItems)
                        }
                        .listStyle(PlainListStyle())
                    }
                }
                .navigationBarHidden(true)
                
                // Generate Listing Button
                VStack {
                    Spacer()
                    SharedButtonStyles.primaryButton(
                        title: "Generate Listing",
                        action: { showingAddClothes = true }
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .sheet(isPresented: $showingAddClothes) {
            AddClothesView(
                onSave: handleNewItem,
                userId: currentUserId
            )
        }
        .onAppear(perform: loadItems)
        .sheet(item: $selectedItem) { item in
            ItemPopupView(
                item: Binding(
                    get: { item },
                    set: { newValue in
                        if let index = savedItems.firstIndex(where: { $0.id == item.id }) {
                            savedItems[index] = newValue
                        }
                    }
                ),
                isPresented: $showingItemPopup,
                onUpdate: updateItem
            )
        }
    }
    
    private func handleNewItem(_ result: Result<ItemData, Error>) {
        switch result {
        case .success(let newItem):
            // Add the already-loading item to the list
            savedItems.insert(newItem, at: 0)
            activeListings = savedItems.count
            // Process the item
            addNewItem(newItem)
        case .failure(let error):
            print("Error adding new item: \(error.localizedDescription)")
            AppUtilities.shared.showError(error.localizedDescription, in: UIView())
        }
    }

    private func addNewItem(_ item: ItemData) {
        Task {
            do {
                let savedItem = try await firebaseManager.saveProduct(item)
                await MainActor.run {
                    // Replace the loading item with the completed item
                    if let index = savedItems.firstIndex(where: { $0.id == item.id }) {
                        savedItems[index] = savedItem
                    }
                    activeListings = savedItems.count
                }
            } catch {
                await MainActor.run {
                    // Remove the loading item if there was an error
                    savedItems.removeAll(where: { $0.id == item.id })
                    activeListings = savedItems.count
                    AppUtilities.shared.showError(error.localizedDescription, in: UIView())
                }
            }
        }
    }
    
    private func updateItem(_ item: ItemData) {
        Task {
            do {
                try await firebaseManager.updateProduct(item)
                if let index = savedItems.firstIndex(where: { $0.id == item.id }) {
                    await MainActor.run {
                        savedItems[index] = item
                    }
                }
            } catch {
                await MainActor.run {
                    AppUtilities.shared.showError(error.localizedDescription, in: UIView())
                }
            }
        }
    }
    
    private func loadItems() {
        Task {
            do {
                let items = try await firebaseManager.fetchProducts(for: currentUserId)
                await MainActor.run {
                    savedItems = items
                    activeListings = items.count
                }
            } catch {
                await MainActor.run {
                    AppUtilities.shared.showError(error.localizedDescription, in: UIView())
                }
            }
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        let indices = Array(offsets)
        
        Task {
            for index in indices {
                do {
                    let item = savedItems[index]
                    if let itemId = item.id {
                        try await firebaseManager.deleteProduct(itemId)
                        await MainActor.run {
                            if let currentIndex = savedItems.firstIndex(where: { $0.id == itemId }) {
                                savedItems.remove(at: currentIndex)
                                activeListings = savedItems.count
                            }
                        }
                    }
                } catch {
                    await MainActor.run {
                        AppUtilities.shared.showError(error.localizedDescription, in: UIView())
                    }
                }
            }
        }
    }
}

// Add comment: Additional shared components that should be moved to SharedComponents.swift
struct SharedDashboardItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
    }
}

struct SharedCompactItemRow: View {
    let item: ItemData
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                SharedItemImage(url: item.imageUrls?.first)
                    .frame(width: 60, height: 60)
                
                SharedItemDetails(item: item)
            }
            .frame(height: 80)
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
            .frame(width: UIScreen.main.bounds.width * 0.95)
        }
    }
}

// Add comment: These extensions should be moved to a separate file called Extensions.swift
extension ButtonStyle where Self == SharedButtonStyle {
    static var prominent: Self {
        SharedButtonStyle(
            foregroundColor: .white,
            backgroundColor: .blue,
            cornerRadius: 30,
            shadow: true
        )
    }
}

// Preview
struct SellView_Previews: PreviewProvider {
    static var previews: some View {
        SellView()
    }
}
