import UIKit
import SwiftUI

final class RIVENEdgeToEdgeWindow: UIWindow {

    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)

        configureEdgeToEdge()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        configureEdgeToEdge()
    }

    private func configureEdgeToEdge() {
        backgroundColor = .black

        // Use the physical scene bounds.
        if let scene = windowScene {
            frame = scene.coordinateSpace.bounds
            bounds = scene.coordinateSpace.bounds
        }

        windowLevel = .normal
        clipsToBounds = false

        // Prevent the window from behaving like a presented sheet.
        rootViewController?.modalPresentationStyle = .fullScreen
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let scene = windowScene else {
            return
        }

        let screenBounds = scene.coordinateSpace.bounds

        if frame != screenBounds {
            frame = screenBounds
        }

        if bounds != screenBounds {
            bounds = screenBounds
        }

        rootViewController?.view.frame = bounds
    }
}


// MARK: - Fullscreen Hosting Controller

final class RIVENFullscreenController<Content: View>: UIHostingController<Content> {

    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        []
    }

    override var prefersStatusBarHidden: Bool {
        false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        // The SwiftUI hierarchy itself fills the UIKit controller.
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let superview = view.superview else {
            return
        }

        view.frame = superview.bounds
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        // Don't let the safe-area inset become a layout constraint
        // for the RIVEN root UI.
        additionalSafeAreaInsets = .zero
    }
}
