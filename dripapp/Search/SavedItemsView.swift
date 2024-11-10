import SwiftUI
import Kingfisher

struct SavedItemsView: View {
    @State private var savedItems: [ItemData] = []
    @State private var selectedItem: ItemData?
    @State private var showingItemDetail = false
    @AppStorage("savedItems") private var savedItemsData: Data = Data()
    let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 10), count: 2)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(savedItems) { item in
                    SavedItemCell(item: item)
                        .onTapGesture {
                            selectedItem = item
                            showingItemDetail = true
                        }
                }
            }
            .padding()
        }
        .navigationTitle("Saved Items")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadSavedItems)
        .sheet(isPresented: $showingItemDetail) {
            if let item = selectedItem {
                ItemDetailView(item: item)
            }
        }
    }
    
    private func loadSavedItems() {
        guard let decodedItems = try? JSONDecoder().decode([ItemData].self, from: savedItemsData) else {
            savedItems = []
            return
        }
        savedItems = decodedItems
    }
}

struct SavedItemCell: View {
    let item: ItemData
    
    var body: some View {
        VStack(alignment: .leading) {
            if let firstImageUrl = item.imageUrls?.first {
                KFImage(URL(string: firstImageUrl))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 150)
                    .clipped()
                    .cornerRadius(10)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1, contentMode: .fit)
                    .cornerRadius(10)
            }
            
            Text(item.description)
                .font(.caption)
                .lineLimit(2)
                .padding(.top, 5)
            
            Text("$\(item.price ?? "N/A")")
                .font(.caption)
                .fontWeight(.bold)
        }
    }
}
