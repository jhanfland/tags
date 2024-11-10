import Foundation
import SwiftUI

class CartManager: ObservableObject {
    static let shared = CartManager()
    
    @Published private(set) var items: [ItemData] = []
    @Published private(set) var isProcessingPayment = false
    
    var itemCount: Int { items.count }
    var total: Double {
        items.reduce(0) { $0 + (Double($1.price ?? "0") ?? 0) }
    }
    

    func addToCart(_ item: ItemData) {
        // Modify items on the main thread
        Task {
            await MainActor.run {
                if !isInCart(item) {
                    items.append(item)
                }
            }
        }
    }
    func updateCart(_ item: ItemData, remove: Bool = false) {
        Task {
            await MainActor.run {
                if remove {
                    items.removeAll { $0.id == item.id }
                } else if !items.contains(where: { $0.id == item.id }) {
                    items.append(item)
                }
            }
        }
    }

    func clearCart() {
        Task {
            await MainActor.run {
                items.removeAll()
            }
        }
    }

    // Remove item from the cart
    func removeFromCart(_ item: ItemData) {
        Task {
            await MainActor.run {
                items.removeAll { $0.id == item.id }
            }
        }
    }

    // Check if item is in the cart
    func isInCart(_ item: ItemData) -> Bool {
        items.contains { $0.id == item.id }
    }
}
