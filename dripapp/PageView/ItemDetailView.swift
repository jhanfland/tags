import SwiftUI
import Kingfisher

// Add comment: Simplified ItemDetailView using shared components
struct ItemDetailView: View {
    let item: ItemData
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var cartManager: CartManager
    @State private var isSaved = false
    @State private var showingMessageInput = false
    @State private var messageText = ""
    @AppStorage("savedItems") private var savedItemsData: Data = Data()
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 8) {
                    ImageCarouselView(
                        imageUrls: item.imageUrls,
                        height: 300,
                        width: UIScreen.main.bounds.width * 0.8
                    )
                    .padding(.top, 15)
                    
                    if !isLoading {
                        PriceAndActionsView(
                            price: item.price ?? "N/A",
                            itemId: item.id,
                            sellerId: item.userId,
                            itemImageUrls: item.imageUrls ?? [],
                            isSaved: $isSaved,
                            onMessageTap: { showingMessageInput = true },
                            onSaveTap: toggleSaved
                        )
                        
                        Text(item.description)
                            .font(.system(size: 14))
                            .foregroundColor(.black)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 5)
                        
                        itemAttributesGrid
                        
                        SharedButtonStyles.primaryButton(
                            title: "Add to Cart",
                            action: addToCart
                        )
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                }
            }
            
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            }
            
            if showingMessageInput {
                MessageInput(
                    isShowing: $showingMessageInput,
                    messageText: $messageText,
                    onSend: sendMessage
                )
            }
        }
        .navigationBarTitle("Item Details", displayMode: .inline)
        .navigationBarItems(trailing: Button("Done") { presentationMode.wrappedValue.dismiss() })
        .onAppear {
            checkIfSaved()
            isLoading = false
        }
    }
    
    private var itemAttributesGrid: some View {
        let attributes = [
            ("Size", item.size),
            ("Brand", item.brand),
            ("Gender", item.gender),
            ("Category", item.category),
            ("Subcategory", item.subcategory),
            ("Condition", item.condition),
            ("Color", item.color),
            ("Source", item.source),
            ("Age", item.age),
            ("Style", item.style.joined(separator: ", "))
        ]
        
        return VStack(alignment: .leading, spacing: 8) {
            ForEach(0..<attributes.chunked(into: 3).count, id: \.self) { rowIndex in
                let rowAttributes = attributes.chunked(into: 3)[rowIndex]
                HStack(spacing: 8) {
                    ForEach(rowAttributes, id: \.0) { attribute in
                        ItemAttribute(title: attribute.0, value: attribute.1)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func addToCart() {
        cartManager.addToCart(item)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func toggleSaved() {
        isSaved.toggle()
        if isSaved {
            saveItem()
        } else {
            removeFromSaved()
        }
    }
    
    private func sendMessage() {
        // Existing message sending logic
        messageText = ""
        showingMessageInput = false
    }
    
    private func checkIfSaved() {
        let savedItems = getSavedItems()
        isSaved = savedItems.contains(where: { $0.id == item.id })
    }
    
    private func getSavedItems() -> [ItemData] {
        guard let decodedItems = try? JSONDecoder().decode([ItemData].self, from: savedItemsData) else {
            return []
        }
        return decodedItems
    }
    
    private func saveItem() {
        var savedItems = getSavedItems()
        savedItems.append(item)
        saveToPersistentStore(items: savedItems)
    }
    
    private func removeFromSaved() {
        var savedItems = getSavedItems()
        savedItems.removeAll(where: { $0.id == item.id })
        saveToPersistentStore(items: savedItems)
    }
    
    private func saveToPersistentStore(items: [ItemData]) {
        if let encodedData = try? JSONEncoder().encode(items) {
            savedItemsData = encodedData
        }
    }
}

struct PriceAndActionsView: View {
    let price: String
    let itemId: String?
    let sellerId: String
    let itemImageUrls: [String]
    @Binding var isSaved: Bool
    @State private var offerAmount: String = ""
    @State private var isTagSelected: Bool = false
    let onMessageTap: () -> Void
    let onSaveTap: () -> Void
    private let cashAppGreen = Color(red: 0, green: 202/255, blue: 64/255)
    
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("$\(price)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.blue)
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        isTagSelected.toggle()
                    }) {
                        HStack {
                            Image(systemName: isTagSelected ? "tag.fill" : "tag")
                                .foregroundColor(cashAppGreen)
                            
                            TextField("Send Offer", text: $offerAmount)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(cashAppGreen)
                                .keyboardType(.numberPad)
                                .onChange(of: offerAmount) { _, newValue in
                                    offerAmount = newValue.filter { "0123456789".contains($0) }
                                }
                                .padding(.leading, 0)
                        }
                        .padding(9)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(10)
                    }
                    .frame(maxWidth: 140) // Set the max width to 100
                    
                    Spacer()
                }
                // .padding(.leading, 40) // Remove the leading padding since centering is handled by Spacers
                HStack(spacing: 12) {
                    // Message button
                    Button(action: onMessageTap) {
                        Image(systemName: "message")
                            .foregroundColor(.blue)
                            .font(.system(size: 20))
                            .frame(width: 40, height: 40)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(10)
                    }
                    
                    // Save button
                    Button(action: onSaveTap) {
                        Image(systemName: isSaved ? "star.fill" : "star")
                            .foregroundColor(isSaved ? .yellow : .gray)
                            .font(.system(size: 20))
                            .frame(width: 40, height: 40)
                            .background( Color.yellow.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal, 20)
            

        }
    }
    
}


