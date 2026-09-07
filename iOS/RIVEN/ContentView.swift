import SwiftUI
import FirebaseAuth

struct ContentView: View {

    @State private var selectedTab = 0

    var body: some View {
        Group {
            if Auth.auth().currentUser != nil {
                mainInterface
            } else {
                LoginView()
            }
        }
        .accentColor(.primary)
    }

    private var mainInterface: some View {
        TabView(selection: $selectedTab) {

            FeedView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
                .tag(0)

            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .tag(1)

            CreateView()
                .tabItem {
                    Image(systemName: "plus")
                    Text("Create")
                }
                .tag(2)

            InboxView()
                .tabItem {
                    Image(systemName: "message")
                    Text("Inbox")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
                .tag(4)
        }
    }
}
