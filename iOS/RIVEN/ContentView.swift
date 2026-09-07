import SwiftUI

struct ContentView: View {

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            FeedView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)

            CreateView()
                .tabItem {
                    Label("Create", systemImage: "plus")
                }
                .tag(2)

            InboxView()
                .tabItem {
                    Label("Inbox", systemImage: "bubble.left.and.bubble.right")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(4)
        }
        .tint(.blue)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .background(Color.black)
    }
}
