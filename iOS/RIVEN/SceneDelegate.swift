import UIKit
import SwiftUI
import GoogleSignIn

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        let window = UIWindow(windowScene: windowScene)

        let rootView = ContentView()

        let hostingController = UIHostingController(
            rootView: rootView
        )

        // Force the hosting controller to behave like a normal
        // full-screen iPhone application.
        hostingController.modalPresentationStyle = .fullScreen

        hostingController.view.backgroundColor = .systemBackground
        hostingController.view.frame = windowScene.coordinateSpace.bounds

        window.rootViewController = hostingController

        self.window = window

        window.frame = windowScene.coordinateSpace.bounds
        window.backgroundColor = .systemBackground

        window.makeKeyAndVisible()
    }

    func scene(
        _ scene: UIScene,
        openURLContexts URLContexts: Set<UIOpenURLContext>
    ) {
        guard let url = URLContexts.first?.url else {
            return
        }

        GIDSignIn.sharedInstance.handle(url)
    }
}
