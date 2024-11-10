import SwiftUI
import Kingfisher

struct HomeView: View {
    @State private var selectedCategory: String = "For You"
    @State private var selectedGender: Gender = .mens
    @State private var scrollViewProxy: ScrollViewProxy?
    @Namespace private var animation
    @StateObject private var cartManager = CartManager.shared
    @State private var navigationPath = NavigationPath()
    @State private var isLoading = false
    @State private var currentPage = 1
    @State private var hasMoreItems = true
    @State private var items: [Gender: [String: [ItemData]]] = [.mens: [:], .womens: [:]]
    @StateObject private var firebaseManager = FirebaseProductManager()

    enum Gender: String, CaseIterable {
        case mens = "Men's"
        case womens = "Women's"
    }

    var categories: [(String, String)] {
        switch selectedGender {
        case .mens:
            return [
                ("For You", "sparkles"),
                ("Shirts", "tshirt"),
                ("Jackets", "jacket"),
                ("Bottoms", "pants"),
                ("Sweatshirts", "sweatshirt"),
                ("Shoes", "shoe"),
                ("Hats", "hat.cap"),
                ("Accessories", "accessories")
            ]
        case .womens:
            return [
                ("For You", "sparkles"),
                ("Tops", "blouse"),
                ("Bottoms", "jean_shorts"),
                ("Swimwear", "swim"),
                ("Dresses", "dress"),
                ("Outerwear", "outerwear"),
                ("Shoes", "shoe"),
                ("Accessories", "accessories")
            ]
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                headerView
                categoryScrollView
                itemGridView
            }
            .navigationBarHidden(true)
            .onAppear {
                loadInitialItems()
            }
            .onChange(of: selectedGender) { _, _ in
                withAnimation(.easeOut(duration: 0.4)) {
                    selectedCategory = "For You"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.4)) {
                            scrollViewProxy?.scrollTo("For You", anchor: .trailing)
                        }
                    }
                }
                handleGenderChange()
            }
        }
    }

    private var headerView: some View {
        GeometryReader { geometry in
            HStack {
                Text("Shop")
                    .font(.largeTitle)
                    .bold()
                
                Spacer()
                
                Button(action: toggleGender) {
                    Text(selectedGender.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 2)
                        )
                        .cornerRadius(18)
                }
                .frame(height: 36)
                .padding(.leading, (geometry.size.width / 2) - 225)
                
                Spacer()
                
                cartButton
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .frame(width: geometry.size.width)
        }
        .frame(height: 50)
    }
    
    private var cartButton: some View {
        NavigationLink(destination: Cart()) {
            Image(systemName: "cart")
                .font(.title2)
                .foregroundColor(.black)
                .padding(.trailing, 20)
                .overlay(cartBadge)
        }
    }
    
    private var cartBadge: some View {
        Group {
            if cartManager.itemCount > 0 {
                Text("\(cartManager.itemCount)")
                    .font(.caption2)
                    .padding(5)
                    .background(Color.red)
                    .clipShape(Circle())
                    .foregroundColor(.white)
                    .offset(x: 10, y: -10)
            }
        }
    }
    
    private var categoryScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { proxy in
                HStack(spacing: 13) {
                    ForEach(categories, id: \.0) { name, icon in
                        categoryButton(name: name, icon: icon)
                    }
                }
                .padding(.horizontal, 20)
                .onAppear {
                    scrollViewProxy = proxy
                    proxy.scrollTo("For You", anchor: .trailing)
                }
                .onChange(of: selectedCategory) { _, newValue in
                    withAnimation {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
        .frame(height: 80)
        .id(selectedGender)
    }
    
    // Added swipeable grid view using TabView
    private var itemGridView: some View {
        TabView(selection: $selectedCategory) {
            ForEach(categories, id: \.0) { category, _ in
                InfiniteScrollView(
                    items: items[selectedGender]?[category] ?? [],
                    hasMoreItems: hasMoreItems,
                    isLoading: isLoading,
                    loadMore: { loadMoreItems(for: category) }
                )
                .tag(category)
                .id(category)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .animation(.easeInOut, value: selectedCategory)
    }

    private func categoryButton(name: String, icon: String) -> some View {
        Button(action: { selectCategory(name) }) {
            VStack {
                ZStack {
                    Circle()
                        .fill(selectedCategory == name ? Color.blue.opacity(0.1) : Color.clear)
                        .frame(width: 60, height: 60)
                    
                    Image(icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .foregroundColor(selectedCategory == name ? .blue : .primary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
    
                Text(name)
                    .font(.caption)
                    .foregroundColor(selectedCategory == name ? .blue : .primary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(maxWidth: .infinity)
        }
        .id(name)
    }
    
    
    private func toggleGender() {
        selectedGender = selectedGender == .mens ? .womens : .mens
        selectedCategory = "For You"
    }
    
    private func selectCategory(_ name: String) {
        withAnimation(.easeInOut(duration: 0.1)) {
            selectedCategory = name
        }
    }

    private func loadInitialItems() {
        Task {
            do {
                isLoading = true
                let products = try await firebaseManager.fetchAllProducts()
                var mensProducts: [String: [ItemData]] = [:]
                var womensProducts: [String: [ItemData]] = [:]
                for product in products {
                    if product.gender == "Men's" {
                        mensProducts[product.category, default: []].append(product)
                        mensProducts["For You", default: []].append(product) // Add this line
                    } else {
                        womensProducts[product.category, default: []].append(product)
                        womensProducts["For You", default: []].append(product) // Add this line
                    }
                }
                
                // Update UI on main thread
                await MainActor.run {
                    items = [
                        .mens: mensProducts,
                        .womens: womensProducts
                    ]
                    isLoading = false
                    currentPage = 1
                    hasMoreItems = !products.isEmpty
                }
            } catch {
                await MainActor.run {
                    print("Error loading initial items: \(error.localizedDescription)")
                    isLoading = false
                    hasMoreItems = false
                }
            }
        }
    }

    private func loadMoreItems(for category: String) {
        guard !isLoading && hasMoreItems else { return }
        
        Task {
            do {
                isLoading = true
                
                // Get current items count for pagination
                let currentItems = items[selectedGender]?[category] ?? []
                
                // Fetch next batch of products
                let products = try await firebaseManager.fetchAllProducts()
                
                // Filter products for selected gender and category
                let newProducts = products.filter { product in
                    product.gender == selectedGender.rawValue &&
                    product.category == category &&
                    !currentItems.contains(where: { $0.id == product.id })
                }
                
                await MainActor.run {
                    // Create new dictionary for the update
                    var updatedGenderItems = items[selectedGender] ?? [:]
                    var updatedCategoryItems = updatedGenderItems[category] ?? []
                    updatedCategoryItems.append(contentsOf: newProducts)
                    updatedGenderItems[category] = updatedCategoryItems
                    
                    // Update the main items dictionary
                    var newItems = items
                    newItems[selectedGender] = updatedGenderItems
                    items = newItems
                    
                    currentPage += 1
                    isLoading = false
                    
                    // Update hasMoreItems based on whether we got a full page of results
                    hasMoreItems = !newProducts.isEmpty
                }
            } catch {
                await MainActor.run {
                    print("Error loading more items: \(error.localizedDescription)")
                    isLoading = false
                    hasMoreItems = false
                }
            }
        }
    }
    
    private func handleGenderChange() {
        currentPage = 1
        hasMoreItems = true
        loadInitialItems()
    }
}

struct ItemView: View {
    let item: ItemData
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                // Image container with fixed aspect ratio
                ZStack(alignment: .bottomLeading) {
                    if let firstImageUrl = item.imageUrls?.first,
                       let url = URL(string: firstImageUrl) {
                        KFImage(url)
                            .placeholder {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width / 3 - 20, height: 150)
                            .clipped()
                            .cornerRadius(10)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: UIScreen.main.bounds.width / 3 - 20, height: 150)
                            .cornerRadius(10)
                    }

                    // Price tag overlay
                    if let price = item.price {
                        Text("$\(price)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(15)
                            .padding(8)
                    }
                }

                // Item details
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.brand)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(item.description)
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 8)
            }
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
}

struct InfiniteScrollView: View {
    let items: [ItemData]
    let hasMoreItems: Bool
    let isLoading: Bool
    let loadMore: () -> Void
    @State private var selectedItem: ItemData?
    @State private var showingItemDetail = false

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                ForEach(items) { item in
                    ItemView(item: item) {
                        selectedItem = item
                        showingItemDetail = true
                    }
                    .onAppear {
                        if items.last?.id == item.id && hasMoreItems {
                            loadMore()
                        }
                    }
                }

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 10)
        }
        .sheet(item: $selectedItem) { item in
            ItemDetailView(item: item) 
                .environmentObject(CartManager.shared)
        }
    }
}
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(CartManager.shared)
    }
}
