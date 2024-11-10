import SwiftUI

struct Cart: View {
    @EnvironmentObject private var cartManager: CartManager
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedItem: ItemData?
    @State private var isDetailViewPresented = false
    @State private var isCheckoutPresented = false

    var body: some View {
        ZStack {
            Color(.systemBackground).edgesIgnoringSafeArea(.all)
            VStack(spacing: 0) {
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                        Text("Back")
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    Text("Cart")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.leading, -60)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 10)

                if cartManager.items.isEmpty {
                    emptyCartView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(cartManager.items) { item in
                                CartItemView(item: item, onRemove: { cartManager.removeFromCart(item) })
                                    .onTapGesture {
                                        selectedItem = item
                                        isDetailViewPresented = true
                                    }
                            }
                        }
                        .padding(.top, 10)
                        .padding(.horizontal)
                    }
                }
                Spacer(minLength: 0)
                
                if !cartManager.items.isEmpty {
                    VStack(spacing: 15) {
                        HStack {
                            Text("Total")
                                .font(.headline)
                            Spacer()
                            Text("$\(String(format: "%.2f", cartManager.total))")
                                .font(.headline)
                        }
                        .padding(.horizontal)
                        
                        Button(action: {
                            isCheckoutPresented = true
                        }) {
                            Text("Proceed to Checkout")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 20)
                    .background(Color(.systemGray6))
                    .cornerRadius(20, corners: [.topLeft, .topRight])
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -5)
                    .edgesIgnoringSafeArea(.bottom)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $isDetailViewPresented) {
            if let item = selectedItem {
                ItemDetailView(item: item)
            }
        }
        .fullScreenCover(isPresented: $isCheckoutPresented) {
            CheckoutView()
        }
    }

    private var emptyCartView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("Your cart is empty")
                .font(.title2)
                .fontWeight(.medium)
            Text("Add some items to get started!")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

import Kingfisher

struct CartItemView: View {
    let item: ItemData
    let onRemove: () -> Void
    @State private var offset: CGFloat = 0
    @State private var isSwiped = false
    @State private var showAlert = false
    @State private var currentImageIndex = 0

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button
            if isSwiped {
                Button(action: { showAlert = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.white)
                        .frame(width: 80, height: 220)
                        .background(Color.red)
                        .cornerRadius(15, corners: [.topRight, .bottomRight])
                }
            }
            
            // Main content
            VStack(spacing: 10) {
                // Image carousel
                imageCarousel
                    .padding(.top, 10)
                
                // Item details
                itemDetails
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
            }
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        withAnimation(.spring()) {
                            offset = max(value.translation.width, -80)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring()) {
                            if value.translation.width < -40 {
                                isSwiped = true
                                offset = -80
                            } else {
                                isSwiped = false
                                offset = 0
                            }
                        }
                    }
            )
        }
        .frame(height: 220)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Remove Item"),
                message: Text("Are you sure you want to remove this item from your cart?"),
                primaryButton: .destructive(Text("Remove")) {
                    onRemove()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private var imageCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                if let imageUrls = item.imageUrls, !imageUrls.isEmpty {
                    ForEach(imageUrls, id: \.self) { urlString in
                        if let url = URL(string: urlString) {
                            KFImage(url)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                } else {
                    // Placeholder image if no images are available
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .foregroundColor(.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal, 10)
        }
        .frame(height: 120)
    }
    
    private var itemDetails: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(item.description)
                .font(.subheadline)
                .lineLimit(2)
            Text(item.brand)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack {
                Text(item.size)
                Spacer()
                Text("$\(item.price ?? "N/A")")
                    .fontWeight(.semibold)
            }
            .font(.footnote)
        }
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
