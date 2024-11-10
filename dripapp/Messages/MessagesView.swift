import SwiftUI

// Add comment: Simplified MessagesView with minimal logic but same visual appearance
struct MessagesView: View {
    @State private var selectedTab = "All"
    @State private var searchText = ""
    @State private var isSearching = false
    private let tabs = ["All", "Buy", "Sell"]
    
    // Add comment: Sample placeholder data - would be replaced with real data in future
    private let sampleConversations = [
        PlaceholderConversation(id: "1", name: "John Doe", lastMessage: "Hey, is this still available?", time: "2m"),
        PlaceholderConversation(id: "2", name: "Jane Smith", lastMessage: "Thanks for the offer!", time: "1h")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Inbox")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: { isSearching.toggle() }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.black)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // Search bar
                if isSearching {
                    SearchBarView(searchText: $searchText)
                }
                
                // Tabs
                HStack {
                    Spacer()
                    ForEach(tabs, id: \.self) { tab in
                        TabButton(title: tab, isSelected: selectedTab == tab) {
                            selectedTab = tab
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 10)
                
                // Messages list
                if sampleConversations.isEmpty {
                    NoMessagesView(for: selectedTab)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(sampleConversations) { conversation in
                                NavigationLink(destination: ConversationView()) {
                                    MessageRow(conversation: conversation)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.top, 10)
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}
struct NoMessagesView: View {
    let tabName: String
    
    init(for tab: String) {
        self.tabName = tab
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No \(tabName.lowercased()) messages")
                .font(.headline)
            
            Text("When you receive new \(tabName.lowercased()) messages, they'll appear here.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}
// Add comment: Simple placeholder model for demo purposes
struct PlaceholderConversation: Identifiable {
    let id: String
    let name: String
    let lastMessage: String
    let time: String
}

// Add comment: Reusable search bar component
struct SearchBarView: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search messages", text: $searchText)
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(25)
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
}

// Add comment: Reusable tab button component
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .frame(minWidth: 110)
                .background(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6))
                .foregroundColor(isSelected ? .blue : .gray)
                .cornerRadius(20)
        }
    }
}

// Add comment: Message row component with simplified data
struct MessageRow: View {
    let conversation: PlaceholderConversation
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.name)
                        .font(.headline)
                    Spacer()
                    Text(conversation.time)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text(conversation.lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
