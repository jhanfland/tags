import Foundation

actor MessageManager: ObservableObject {
    static let shared = MessageManager()
    
    @MainActor @Published private(set) var conversations: [Conversation] = []
    
    private init() {
        loadConversations()
    }
    
    @MainActor
    private func loadConversations() {
        // TODO: Implement API call to fetch conversations from the backend
        // For now, we'll use sample data
        conversations = [
            Conversation(id: UUID(), otherUser: User(id: UUID(), name: "John Doe", profileImageURL: URL(string: "https://example.com/john.jpg")!), lastMessage: "Hey, is this item still available?", lastMessageTime: Date(), type: "Buy"),
            Conversation(id: UUID(), otherUser: User(id: UUID(), name: "Jane Smith", profileImageURL: URL(string: "https://example.com/jane.jpg")!), lastMessage: "Thanks for the purchase!", lastMessageTime: Date().addingTimeInterval(-86400), type: "Sell")
        ]
    }
    
    func getMessages(for conversation: Conversation) async -> [Message] {
        // TODO: Implement API call to fetch messages for a specific conversation
        // For now, we'll return sample data
        return [
            Message(id: UUID(), senderId: UserManager.shared.currentUserId, content: "Hello!", timestamp: Date().addingTimeInterval(-3600)),
            Message(id: UUID(), senderId: conversation.otherUser.id, content: "Hi there!", timestamp: Date().addingTimeInterval(-3500)),
            Message(id: UUID(), senderId: UserManager.shared.currentUserId, content: "Is the item still available?", timestamp: Date().addingTimeInterval(-3400))
        ]
    }
    
    func sendMessage(content: String, in conversation: Conversation) async {
        // TODO: Implement API call to send a message to the backend
        // For now, we'll just print the message
        print("Sending message: \(content) to \(conversation.otherUser.name)")
    }
    
    @MainActor
    func deleteConversation(_ conversation: Conversation) {
        // TODO: Implement API call to delete the conversation on the backend
        conversations.removeAll { $0.id == conversation.id }
    }
    
    func createConversation(with user: User) async {
        // TODO: Implement API call to create a new conversation on the backend
        // For now, we'll just add a new conversation to the list
        await MainActor.run {
            let newConversation = Conversation(id: UUID(), otherUser: user, lastMessage: "", lastMessageTime: Date(), type: "Buy")
            conversations.append(newConversation)
        }
    }
}

struct Conversation: Identifiable {
    let id: UUID
    let otherUser: User
    let lastMessage: String
    let lastMessageTime: Date
    let type: String
}

struct Message: Identifiable {
    let id: UUID
    let senderId: UUID
    let content: String
    let timestamp: Date
}

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
