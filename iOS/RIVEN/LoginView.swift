import SwiftUI
import FirebaseAuth

struct LoginView: View {

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {

                Spacer()

                Text("RIVEN")
                    .font(.system(size: 42, weight: .bold))
                    .tracking(2)

                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                }

                Button("Sign In") {
                    signIn()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.primary)
                .foregroundColor(Color(UIColor.systemBackground))
                .cornerRadius(12)

                Spacer()
            }
            .padding(24)
            .navigationBarHidden(true)
        }
    }

    private func signIn() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Enter your email and password."
            return
        }

        Auth.auth().signIn(
            withEmail: email,
            password: password
        ) { _, error in

            if let error = error {
                errorMessage = error.localizedDescription
            }
        }
    }
}
