import SwiftUI
import Kingfisher

struct HomeView: View {
    @State private var selectedCategory: String = "For You"
    @State private var selectedGender: Gender = .mens
    @State private var scrollViewProxy: ScrollViewProxy?
    @Namespace private var animation
    @StateObject private var cartManager = CartManager.shared
    @State private var navigationPath = NavigationPath()
    
    // Added state variables for infinite scrolling and loading states
    @State private var isLoading = false
    @State private var currentPage = 1
    @State private var hasMoreItems = true
    @State private var items: [Gender: [String: [ItemData]]] = [.mens: [:], .womens: [:]]
    
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
                // Updated to use TabView with swipeable grid
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
    
    // MARK: - Subviews
    
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
    
    // MARK: - Helper Methods
    
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
        // Comment: Using unique IDs for each placeholder item
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            for gender in Gender.allCases {
                let categoriesForGender = gender == .mens ? categories : categories
                for (category, _) in categoriesForGender {
                    // Updated: Generate placeholders with unique IDs
                    let placeholderItems = (0..<20).map { index in
                        var item = ItemData.placeholder()
                        item.id = "\(gender)-\(category)-\(index)-\(UUID().uuidString)"
                        return item
                    }
                    items[gender, default: [:]][category] = placeholderItems
                }
            }
            isLoading = false
            currentPage = 1
        }
    }

    private func loadMoreItems(for category: String) {
        guard !isLoading && hasMoreItems else { return }
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Comment: Generate new placeholders with unique IDs based on current count
            let currentCount = self.items[selectedGender, default: [:]][category, default: []].count
            let newPlaceholderItems = (0..<20).map { index in
                var item = ItemData.placeholder()
                item.id = "\(selectedGender)-\(category)-\(currentCount + index)-\(UUID().uuidString)"
                return item
            }
            items[selectedGender, default: [:]][category, default: []].append(contentsOf: newPlaceholderItems)
            
            currentPage += 1
            isLoading = false
            
            if currentPage >= 5 {
                hasMoreItems = false
            }
        }
    }
    
    private func handleGenderChange() {
        currentPage = 1
        hasMoreItems = true
        loadInitialItems()
    }
}

// MARK: - Supporting Views

struct ItemView: View {
    let item: ItemData
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    if let firstImageUrl = item.imageUrls?.first,
                       let url = URL(string: firstImageUrl) {
                        KFImage(url)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(0.85, contentMode: .fit)
                            .cornerRadius(10)
                    }

                    Text("$\(item.price ?? "N/A")")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.7))
                        .clipShape(Capsule())
                        .padding([.leading, .bottom], 8)
                }
            }
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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
                GridItem(.flexible(), spacing: 5),
                GridItem(.flexible(), spacing: 5),
                GridItem(.flexible(), spacing: 5)
            ], spacing: 5) {
                ForEach(items) { item in
                    ItemView(item: item) {
                        selectedItem = item
                        showingItemDetail = true
                    }
                    .onAppear {
                        if self.items.last?.id == item.id && hasMoreItems {
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
            .padding(.horizontal, 12)
        }
        .sheet(isPresented: $showingItemDetail) {
            if let item = selectedItem {
                ItemDetailView(item: item)
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(CartManager.shared)
    }
}
