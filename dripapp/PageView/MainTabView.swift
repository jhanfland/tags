import SwiftUI

struct MainTabView: View {
    @StateObject private var colorSchemeManager = ColorSchemeManager()
        @EnvironmentObject private var authManager: AuthenticationManager
        @State private var selectedTab: Int = 0
        @State private var navigationPath = NavigationPath()
        @StateObject private var cartManager = CartManager.shared
        @State private var hideTabBar = false
    init() {
        // Customize the tab bar appearance
        UITabBar.appearance().unselectedItemTintColor = .gray
        UITabBar.appearance().tintColor = .black
    }
    
    var body: some View {
            NavigationStack(path: $navigationPath) {
                TabView(selection: $selectedTab) {
                    HomeView()
                        .tabItem {
                            Image("basket")
                                .renderingMode(.template)
                            Text("Shop")
                        }
                        .tag(0)
                SearchView()
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("Search")
                    }
                    .tag(1)
                
                SellView()
                    .tabItem {
                        Image("dollarsign.bank.building")
                            .renderingMode(.template)
                        Text("Sell")
                    }
                    .tag(2)
                
                MessagesView()
                    .tabItem {
                        Image("bubble")
                            .renderingMode(.template)
                        Text("Messages")
                    }
                    .tag(3)
                
                    ProfileView()
                                        .tabItem {
                                            Image("person")
                                                .renderingMode(.template)
                                            Text("Profile")
                                        }
                                        .tag(4)
                                        .environmentObject(authManager) // Pass authManager to ProfileView
                }
                            .accentColor(colorSchemeManager.accentColor)
                            .preferredColorScheme(colorSchemeManager.colorScheme)
                            .toolbar(hideTabBar ? .hidden : .visible, for: .tabBar)
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "Cart":
                    Cart()
                        .onAppear { hideTabBar = true }
                        .onDisappear { hideTabBar = false }
                case "Checkout":
                    CheckoutView()
                        .onAppear { hideTabBar = true }
                        .onDisappear { hideTabBar = false }
                default:
                    EmptyView()
                }
            }
        }
    
            .environmentObject(cartManager)
            .environmentObject(colorSchemeManager)
        }
    }

struct BackButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button(action: {
            dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back")
            }
        }
    }
}

// Extension to handle custom transitions
extension View {
    func withoutTabBar() -> some View {
        self
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButton()
                }
            }
    }
}
