import SwiftUI


struct SearchResultsView: View {
    @Binding var searchCriteria: SearchCriteria
    @State private var searchText: String = ""
    @StateObject private var cartManager = CartManager.shared

    let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 5), count: 3)

    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding()

                // Grid of Placeholder Items
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(0..<20) { index in
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .aspectRatio(0.85, contentMode: .fit)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 10)
                }

                Spacer()
            }
            .navigationBarTitle("Results", displayMode: .inline)
            .navigationBarItems(
                leading: Button(action: {
                    // Back action
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                },
                trailing: NavigationLink(destination: CartView()) {
                    ZStack {
                        Image(systemName: "cart")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
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
            )
        }
    }
}

// MARK: - SearchBar

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search...", text: $text)
                .foregroundColor(.primary)
            if !text.isEmpty {
                Button(action: {
                    self.text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - CartView

struct CartView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var cartManager = CartManager.shared

    var body: some View {
        VStack {
            Text("Cart")
                .font(.largeTitle)
                .padding()

            Text("Items in cart: \(cartManager.itemCount)")
                .padding()

            Spacer()

            Button("Close") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
    }
}

// MARK: - Preview

struct SearchResultsView_Previews: PreviewProvider {
    static var previews: some View {
        SearchResultsView(searchCriteria: .constant(SearchCriteria()))
    }
}
