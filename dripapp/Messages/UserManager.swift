import Foundation

class UserManager {
    static let shared = UserManager()
    
    let currentUserId = UUID()
    
    private init() {}
    
    func getAllUsers() async -> [User] {
        // TODO: Implement API call to fetch all users from the backend
        // For now, we'll return sample data
        return [
            User(id: UUID(), name: "Alice Brown", profileImageURL: URL(string: "https://example.com/alice.jpg")!),
            User(id: UUID(), name: "Bob Wilson", profileImageURL: URL(string: "https://example.com/bob.jpg")!),
            User(id: UUID(), name: "Charlie Davis", profileImageURL: URL(string: "https://example.com/charlie.jpg")!)
        ]
    }
}
