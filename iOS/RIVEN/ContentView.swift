import SwiftUI
import FirebaseAuth

struct ContentView: View {

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            FeedView()
                .tabItem {
                    Image(systemName: "house.fill")
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
                    Image(systemName: "plus.circle.fill")
                    Text("Create")
                }
                .tag(2)

            InboxView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Inbox")
                }
                .tag(3)

            profileTab
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(4)
        }
    }

    @ViewBuilder
    private var profileTab: some View {
        if let uid = Auth.auth().currentUser?.uid {
            ProfileView(uid: uid)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .font(.system(size: 42))

                Text("Not signed in")
                    .font(.headline)

                Text("Please sign in to view your profile.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}
