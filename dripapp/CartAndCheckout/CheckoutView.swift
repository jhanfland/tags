import SwiftUI
import PassKit
import Kingfisher
import Foundation

struct CheckoutView: View {
    @EnvironmentObject var cartManager: CartManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAddressSelector = false
    @State private var isProcessingPayment = false
    @State private var paymentSuccess = false
    @State private var paymentError: Error?
    @AppStorage("userAddress") private var savedAddress: String = ""
    @AppStorage("userName") private var userName: String = ""
    @StateObject private var addressCompleter = AddressCompleter()
    @State private var searchText: String = ""
    @State private var isEditing = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
        private let appUtilities = AppUtilities.shared
    private let shippingFee: Double = 6.29
    private let taxAndFeesRate: Double = 0.15
    private let merchantAccountId = "merchant_account_123"
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Custom navigation bar
                        HStack {
                            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            Text("Checkout")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.leading, 18)
                            Spacer()
                            Button(action: {
                                isEditing.toggle()
                            }) {
                                Text(isEditing ? "Done" : "Edit")
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 0)
                        .padding(.bottom, 10)
                        
                        OrderSummaryView(
                            subtotal: cartManager.total,
                            shipping: shippingFee,
                            taxesAndFees: calculateTaxesAndFees(),
                            total: calculateTotal(),
                            itemCount: cartManager.itemCount
                        )
                        
                        AddressView(
                            name: userName,
                            address: $savedAddress,
                            addressCompleter: addressCompleter
                        )
                        
                        CartItemsPreview(
                            items: cartManager.items,
                            isEditing: isEditing,
                            onDelete: deleteItem
                        )
                        
                        Spacer().frame(height: 100)
                    }
                    .padding()
                }
                
                // Added comment: Using PaymentButton for consistent styling
                VStack {
                    Spacer()
                    VStack(spacing: 15) {
                        PaymentButton(
                            title: "Apple Pay",
                            icon: "applelogo",
                            color: .black,
                            action: processApplePayment
                        )
                        
                        PaymentButton(
                            title: "Nessie Pay",
                            icon: "dollarsign.circle.fill",
                            color: .blue,
                            action: handleNessiePayment
                        )
                        
                        PaymentButton(
                            title: "Pay with Venmo",
                            imageName: "venmo",
                            color: Color(red: 0.11, green: 0.69, blue: 0.95),
                            action: processVenmoPayment
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    .disabled(isProcessingPayment)
                    .opacity(isProcessingPayment ? 0.5 : 1)
                }
            }
            .keyboardAware() // Added comment: Using shared keyboard awareness modifier
            .navigationBarHidden(true)
        }
        .alert(isPresented: .constant(paymentError != nil)) {
            Alert(
                title: Text("Payment Error"),
                message: Text(paymentError?.localizedDescription ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK")) {
                    paymentError = nil
                }
            )
        }
        .onChange(of: paymentSuccess) { _, success in
            if success {
                cartManager.clearCart()
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    // Added comment: Calculation methods using AppUtilities
    private func calculateTaxesAndFees() -> Double {
        return cartManager.total * taxAndFeesRate
    }
    
    private func calculateTotal() -> Double {
        return cartManager.total + shippingFee + calculateTaxesAndFees()
    }
    
    private func deleteItem(_ item: ItemData) {
        cartManager.removeFromCart(item)
    }
    
    // Added comment: Payment processing methods
    private func processApplePayment() {
        // Implement Apple Pay
    }
    
    private func processVenmoPayment() {
    }
    
    private func handleNessiePayment() {
        guard let userId = authManager.getCurrentUserId() else {
            paymentError = PaymentError.insufficientFunds
            return
        }
        
        isProcessingPayment = true
        
        Task {
            do {
                let success = try await NessiePaymentManager.shared.processPayment(
                    fromAccount: userId,
                    toAccount: merchantAccountId,
                    amount: calculateTotal()
                )
                
                await MainActor.run {
                    isProcessingPayment = false
                    if success {
                        paymentSuccess = true
                        guard let url = URL(string: "http://api.nessieisreal.com/customers/\(userId)/transfers?key=84f3ca014fca8e0f3b24488da4fe1192")
                        else {
                            print("Invalid URL")
                            return
                        }
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        let transferDetails: [String: Any] = [
                                                "medium": "balance",
                                                "payee_id": merchantAccountId,
                                                "transaction_date": dateFormatter.string(from: Date()),
                                                "status": "pending",
                                                "description": "Initiated Sale"
                                            ]
                        
                        var request = URLRequest(url: url)
                        request.httpMethod = "POST"
                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        do {
                            request.httpBody = try JSONSerialization.data(withJSONObject: transferDetails, options: [])
                        } catch {
                            print("Error serializing JSON: \(error)")
                                return
                            }
                               
                        // Send the request
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
                        
                        cartManager.clearCart()
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        paymentError = PaymentError.insufficientFunds
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessingPayment = false
                    paymentError = error
                }
            }
        }
    }
}

// Preview all cart items
struct CartItemsPreview: View {
    let items: [ItemData]
    let isEditing: Bool
    let onDelete: (ItemData) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            ForEach(items) { item in
                HStack {
                    if isEditing {
                        Button(action: {
                            onDelete(item)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    ItemPreviewView(item: item)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

struct ItemPreviewView: View {
    let item: ItemData

    var body: some View {
        HStack(spacing: 15) {
            if let firstImageUrlString = item.imageUrls?.first,
               let imageUrl = URL(string: firstImageUrlString) {
                KFImage(imageUrl)
                    .placeholder {
                        // Placeholder image while loading
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.gray)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
            } else {
                // Placeholder image if no URL is available
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.gray)
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(item.description)
                    .font(.subheadline)
                    .lineLimit(1)

                Text("\(item.size) | $\(item.price ?? "")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Address view with name
struct AddressView: View {
    let name: String
    @Binding var address: String
    @ObservedObject var addressCompleter: AddressCompleter
    @State private var searchText: String = ""
    @State private var isEditing = false
    @State private var showingDropdown = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geometry in
                Button(action: {
                    isEditing.toggle()
                    if isEditing {
                        searchText = ""
                        isTextFieldFocused = true
                    } else {
                        isTextFieldFocused = false
                    }
                }) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "map")
                            .foregroundColor(.black)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(name.isEmpty ? "Add Name" : name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(address.isEmpty ? "Add address" : address)
                                .font(.subheadline)
                                .foregroundColor(address.isEmpty ? .secondary : .primary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            if isEditing {
                                TextField("Search address", text: $searchText)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding(.top, 5)
                                    .focused($isTextFieldFocused)
                                    .onChange(of: searchText) { _, newValue in
                                        addressCompleter.updateQueryFragment(newValue)
                                        showingDropdown = !newValue.isEmpty
                                    }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Image(systemName: isEditing ? "pencil.circle.fill" : (address.isEmpty ? "pencil.circle.fill" : "checkmark.circle.fill"))
                            .foregroundColor(isEditing ? .blue : (address.isEmpty ? .blue : .green))
                            .font(.system(size: 24))
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .frame(minHeight: isEditing ? 120 : 80)

            if isEditing && showingDropdown {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(addressCompleter.results) { suggestion in
                            AddressSuggestionRow(suggestion: suggestion)
                                .onTapGesture {
                                    address = suggestion.fullAddress
                                    searchText = ""
                                    isEditing = false
                                    showingDropdown = false
                                }
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 200)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                .padding(.horizontal)
            }
        }
    }
}

// Order summary view
struct OrderSummaryView: View {
    let subtotal: Double
    let shipping: Double
    let taxesAndFees: Double
    let total: Double
    let itemCount: Int
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(isExpanded ? "Order Summary" : "Total")
                        .font(.headline)
                    Spacer()
                    if !isExpanded {
                        Text("$\(total, specifier: "%.2f")")
                            .font(.subheadline)
                            .alignmentGuide(.trailing) { d in d[.trailing] }
                    }
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
            }
            .foregroundColor(.primary)
            
            if isExpanded {
                Group {
                    SummaryRow(title: "Subtotal", value: subtotal)
                    SummaryRow(title: "Shipping", value: shipping)
                    SummaryRow(title: "Taxes and Fees", value: taxesAndFees)
                    Divider()
                    SummaryRow(title: "Total", value: total, isTotal: true)
                }
                .transition(.opacity)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

// Individual summary row
struct SummaryRow: View {
    let title: String
    let value: Double
    var isTotal: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
                .fontWeight(isTotal ? .bold : .regular)
            Spacer()
            Text("$\(value, specifier: "%.2f")")
                .fontWeight(isTotal ? .bold : .regular)
        }
    }
}


struct CheckoutView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock CartManager with placeholder items
        let cartManager = CartManager()
        
        // Add multiple placeholder items to simulate a more realistic cart
        for _ in 0..<3 {
            let placeholderItem = ItemData.placeholder()
            cartManager.addToCart(placeholderItem)
        }

        return CheckoutView()
            .environmentObject(cartManager)
    }
}
