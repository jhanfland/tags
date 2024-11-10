import SwiftUI

struct NewConversationView: View {
    @State private var searchText = ""
    @StateObject private var viewModel = NewConversationViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.filteredUsers(searchText: searchText)) { user in
                    Button(action: { startConversation(with: user) }) {
                        HStack {
                            CircleImage(url: user.profileImageURL)
                                .frame(width: 40, height: 40)
                            Text(user.name)
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            .searchable(text: $searchText, prompt: "Search for users")
            .navigationTitle("New Conversation")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func startConversation(with user: User) {
        Task {
            await viewModel.startConversation(with: user)
            presentationMode.wrappedValue.dismiss()
        }
    }
}

class NewConversationViewModel: ObservableObject {
    @Published var users: [User] = []
    private let userManager = UserManager.shared
    private let messageManager = MessageManager.shared
    
    init() {
        loadUsers()
    }
    
    private func loadUsers() {
        Task {
            users = await userManager.getAllUsers()
        }
    }
    
    func filteredUsers(searchText: String) -> [User] {
        if searchText.isEmpty {
            return users
        } else {
            return users.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    func startConversation(with user: User) async {
        await messageManager.createConversation(with: user)
    }
}
