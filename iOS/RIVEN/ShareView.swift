import SwiftUI
import FirebaseFirestore

struct SearchView: View {

    @State private var searchText = ""
    @State private var results: [UserResult] = []

    var body: some View {

        NavigationView {

            VStack {

                TextField("Search RIVEN", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onChange(of: searchText) { value in
                        search(value)
                    }

                List(results) { user in

                    HStack {

                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))

                        VStack(alignment: .leading) {
                            Text(user.name)
                                .font(.headline)

                            Text("@\(user.handle)")
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                }

                Spacer()
            }
            .navigationBarTitle("Search", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func search(_ text: String) {

        guard !text.isEmpty else {
            results = []
            return
        }

        Firestore.firestore()
            .collection("users")
            .whereField(
                "handle",
                isGreaterThanOrEqualTo: text.lowercased()
            )
            .limit(to: 20)
            .getDocuments { snapshot, _ in

                guard let documents = snapshot?.documents else {
                    return
                }

                results = documents.map {
                    UserResult(
                        id: $0.documentID,
                        name: $0.data()["name"] as? String ?? "User",
                        handle: $0.data()["handle"] as? String ?? "user"
                    )
                }
            }
    }
}

struct UserResult: Identifiable {
    let id: String
    let name: String
    let handle: String
}
