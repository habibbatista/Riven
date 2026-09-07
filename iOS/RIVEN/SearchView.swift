import SwiftUI

struct SearchView: View {
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 42))
                            .foregroundColor(.secondary)

                        Text("Search")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Search for people and videos on RIVEN.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary)

                        Text("Searching for")
                            .font(.headline)

                        Text(searchText)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .searchable(text: $searchText, prompt: "Search RIVEN")
            .navigationTitle("Search")
        }
    }
}
