import SwiftUI

// Add comment: Simplified ConversationView with minimal logic but same visual appearance
struct ConversationView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var messageText = ""
    @State private var showingImagePicker = false
    @State private var showingActionSheet = false
    @State private var showingSettings = false
    
    // Add comment: Sample messages for demo purposes
    private let sampleMessages = [
        PlaceholderMessage(isFromCurrentUser: false, content: "Hi, is this still available?", time: "2:30 PM"),
        PlaceholderMessage(isFromCurrentUser: true, content: "Yes, it is!", time: "2:31 PM")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation bar
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.primary)
                }
                Spacer()
                Text("John Doe")
                    .font(.headline)
                Spacer()
                Button(action: { showingSettings.toggle() }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Messages
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(sampleMessages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }
            
            // Input bar
            HStack(spacing: 8) {
                Button(action: { showingActionSheet = true }) {
                    Image(systemName: "camera")
                        .foregroundColor(.blue)
                }
                
                TextField("Message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {}) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .confirmationDialog("Add Photo", isPresented: $showingActionSheet) {
            Button("Take Photo") { showingImagePicker = true }
            Button("Choose from Library") { showingImagePicker = true }
        }
        .overlay(
            Group {
                if showingSettings {
                    SettingsOverlay()
                        .frame(width: 120)
                        .offset(x: UIScreen.main.bounds.width - 160, y: 60)
                }
            }
        )
    }
}

// Add comment: Simple message model for demo purposes
struct PlaceholderMessage: Identifiable {
    let id = UUID()
    let isFromCurrentUser: Bool
    let content: String
    let time: String
}

// Add comment: Message bubble component
struct MessageBubble: View {
    let message: PlaceholderMessage
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser { Spacer() }
            
            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading) {
                Text(message.content)
                    .padding(12)
                    .background(message.isFromCurrentUser ? Color.blue.opacity(0.7) : Color(.systemGray6))
                    .foregroundColor(message.isFromCurrentUser ? .white : .primary)
                    .cornerRadius(20)
                
                Text(message.time)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            if !message.isFromCurrentUser { Spacer() }
        }
    }
}

// Add comment: Settings overlay component
struct SettingsOverlay: View {
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {}) {
                Text("Delete Message")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            Divider()
            Button(action: {}) {
                Text("Block")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            Divider()
            Button(action: {}) {
                Text("Report")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}
