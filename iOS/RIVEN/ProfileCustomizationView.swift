import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileCustomizationView: View {

    @State private var fontWeight = 0.5
    @State private var letterSpacing = 0.0
    @State private var nameAlignment = 0.5
    @State private var avatarAlignment = 0.5

    var body: some View {

        NavigationView {

            Form {

                Section(header: Text("Name")) {

                    HStack {
                        Text("Weight")

                        Slider(
                            value: $fontWeight,
                            in: 0...1
                        )
                    }

                    HStack {
                        Text("Letter Spacing")

                        Slider(
                            value: $letterSpacing,
                            in: -2...8
                        )
                    }

                    HStack {
                        Text("Name Alignment")

                        Slider(
                            value: $nameAlignment,
                            in: 0...1
                        )
                    }
                }

                Section(header: Text("Avatar")) {

                    HStack {
                        Text("Avatar Alignment")

                        Slider(
                            value: $avatarAlignment,
                            in: 0...1
                        )
                    }
                }

                Button("Save") {
                    save()
                }
            }
            .navigationBarTitle(
                "Customize Profile",
                displayMode: .inline
            )
        }
    }

    private func save() {

        guard let uid =
            Auth.auth().currentUser?.uid else {
            return
        }

        let customization: [String: Any] = [
            "fontWeight": fontWeight,
            "letterSpacing": letterSpacing,
            "nameAlignment": nameAlignment,
            "avatarAlignment": avatarAlignment
        ]

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .setData([
                "customization": customization
            ], merge: true)
    }
}
