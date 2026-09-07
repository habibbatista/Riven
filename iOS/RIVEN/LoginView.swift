import SwiftUI
import UIKit
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

struct LoginView: View {

    @State private var isSigningIn = false
    @State private var errorMessage = ""
    @State private var isSignedIn = false

    var body: some View {
        Group {
            if isSignedIn {
                ContentView()
            } else {
                loginScreen
            }
        }
    }

    private var loginScreen: some View {
        ZStack {

            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {

                Spacer()

                VStack(spacing: 10) {

                    Text("RIVEN")
                        .font(.system(size: 48, weight: .bold))

                    Text("Your world. Your videos.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(spacing: 14) {

                    Button {
                        signInWithGoogle()
                    } label: {

                        HStack(spacing: 12) {

                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 22))

                            Text(
                                isSigningIn
                                ? "Signing in..."
                                : "Continue with Google"
                            )
                            .font(.headline)

                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSigningIn)

                    if !errorMessage.isEmpty {

                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
                    .frame(height: 30)
            }
        }
    }

    private func signInWithGoogle() {

        guard !isSigningIn else {
            return
        }

        guard let clientID = FirebaseApp.app()?.options.clientID else {

            errorMessage = "Firebase client ID is missing."
            return
        }

        guard let presentingViewController = getPresentingViewController() else {

            errorMessage = "Could not open Google Sign-In."
            return
        }

        isSigningIn = true
        errorMessage = ""

        let configuration = GIDConfiguration(
            clientID: clientID
        )

        GIDSignIn.sharedInstance.configuration = configuration

        GIDSignIn.sharedInstance.signIn(
            withPresenting: presentingViewController
        ) { result, error in

            if let error = error {

                DispatchQueue.main.async {
                    isSigningIn = false
                    errorMessage = error.localizedDescription
                }

                return
            }

            guard
                let user = result?.user,
                let idToken = user.idToken?.tokenString
            else {

                DispatchQueue.main.async {
                    isSigningIn = false
                    errorMessage = "Google did not return a valid ID token."
                }

                return
            }

            let accessToken = user.accessToken.tokenString

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: accessToken
            )

            Auth.auth().signIn(
                with: credential
            ) { _, firebaseError in

                DispatchQueue.main.async {

                    isSigningIn = false

                    if let firebaseError = firebaseError {

                        errorMessage = firebaseError.localizedDescription
                        return
                    }

                    isSignedIn = true
                }
            }
        }
    }

    private func getPresentingViewController() -> UIViewController? {

        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        let window = scenes
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }

        guard let rootViewController = window?.rootViewController else {
            return nil
        }

        return topViewController(
            from: rootViewController
        )
    }

    private func topViewController(
        from viewController: UIViewController
    ) -> UIViewController {

        if let presented = viewController.presentedViewController {
            return topViewController(from: presented)
        }

        if let navigationController =
            viewController as? UINavigationController,
           let visible = navigationController.visibleViewController {

            return topViewController(from: visible)
        }

        if let tabBarController =
            viewController as? UITabBarController,
           let selected = tabBarController.selectedViewController {

            return topViewController(from: selected)
        }

        return viewController
    }
}
