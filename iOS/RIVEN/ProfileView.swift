import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {

    @State private var name = "User"
    @State private var handle = "user"
    @State private var avatarURL = ""

    @State private var showCustomization = false

    var body: some View {

        NavigationView {

            ScrollView {

                VStack(spacing: 16) {

                    if let url = URL(string: avatarURL),
                       !avatarURL.isEmpty {

                        AsyncImageCompat(url: url)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())

                    } else {

                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 100))
                    }

                    Text(name)
                        .font(.system(size: 28, weight: .bold))

                    Text("@\(handle)")
                        .foregroundColor(.secondary)

                    HStack(spacing: 35) {

                        StatView(title: "Posts", value: "0")
                        StatView(title: "Followers", value: "0")
                        StatView(title: "Following", value: "0")
                    }

                    Button("Customize Profile") {
                        showCustomization = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary)
                    .foregroundColor(Color(UIColor.systemBackground))
                    .cornerRadius(12)

                }
                .padding()
            }
            .navigationBarTitle("Profile", displayMode: .inline)
            .sheet(isPresented: $showCustomization) {
                ProfileCustomizationView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            loadProfile()
        }
    }

    private func loadProfile() {

        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .getDocument { snapshot, _ in

                guard let data = snapshot?.data() else {
                    return
                }

                name = data["name"] as? String ?? "User"
                handle = data["handle"] as? String ?? "user"
                avatarURL = data["pfp"] as? String ?? ""
            }
    }
}

struct StatView: View {

    let title: String
    let value: String

    var body: some View {

        VStack {

            Text(value)
                .font(.headline)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
