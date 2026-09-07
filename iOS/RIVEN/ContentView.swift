import SwiftUI
import UIKit
import FirebaseAuth

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var isSignedIn = Auth.auth().currentUser != nil

    var body: some View {
        Group {
            if isSignedIn {
                mainInterface
            } else {
                LoginView()
            }
        }
        .onAppear {
            isSignedIn = Auth.auth().currentUser != nil
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
        ) { _ in
            isSignedIn = Auth.auth().currentUser != nil
        }
    }

    private var mainInterface: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case 0:
                    NavigationView {
                        FeedView()
                            .navigationBarTitleDisplayMode(.inline)
                    }

                case 1:
                    NavigationView {
                        SearchView()
                            .navigationBarTitleDisplayMode(.inline)
                    }

                case 2:
                    NavigationView {
                        CreateView()
                            .navigationBarTitleDisplayMode(.inline)
                    }

                case 3:
                    NavigationView {
                        InboxView()
                            .navigationBarTitleDisplayMode(.inline)
                    }

                case 4:
                    NavigationView {
                        ProfileView()
                            .navigationBarTitleDisplayMode(.inline)
                    }

                default:
                    FeedView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemBackground))
            .padding(.bottom, 82)

            RIVENUIKitTabBar(selectedTab: $selectedTab)
                .frame(height: 82)
                .ignoresSafeArea(edges: .bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Native Apple UIKit Tab Bar

private struct RIVENUIKitTabBar: UIViewControllerRepresentable {
    @Binding var selectedTab: Int

    func makeUIViewController(context: Context) -> RIVENUIKitTabBarController {
        let controller = RIVENUIKitTabBarController()

        controller.selectedTab = selectedTab

        controller.onSelectionChanged = { index in
            DispatchQueue.main.async {
                selectedTab = index
            }
        }

        return controller
    }

    func updateUIViewController(
        _ controller: RIVENUIKitTabBarController,
        context: Context
    ) {
        controller.selectedTab = selectedTab
    }
}

private final class RIVENUIKitTabBarController: UIViewController, UITabBarDelegate {

    private let tabBar = UITabBar()

    var onSelectionChanged: ((Int) -> Void)?

    var selectedTab: Int = 0 {
        didSet {
            guard let items = tabBar.items else {
                return
            }

            guard items.indices.contains(selectedTab) else {
                return
            }

            if tabBar.selectedItem !== items[selectedTab] {
                tabBar.selectedItem = items[selectedTab]
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear

        configureTabBar()
        configureAppearance()
        configureLayout()
    }

    private func configureTabBar() {
        let homeItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )

        let searchItem = UITabBarItem(
            title: "Search",
            image: UIImage(systemName: "magnifyingglass"),
            selectedImage: UIImage(systemName: "magnifyingglass")
        )

        let createItem = UITabBarItem(
            title: "Create",
            image: UIImage(systemName: "plus"),
            selectedImage: UIImage(systemName: "plus")
        )

        let inboxItem = UITabBarItem(
            title: "Inbox",
            image: UIImage(systemName: "bubble.left.and.bubble.right"),
            selectedImage: UIImage(systemName: "bubble.left.and.bubble.right.fill")
        )

        let profileItem = UITabBarItem(
            title: "Profile",
            image: UIImage(systemName: "person"),
            selectedImage: UIImage(systemName: "person.fill")
        )

        tabBar.items = [
            homeItem,
            searchItem,
            createItem,
            inboxItem,
            profileItem
        ]

        tabBar.selectedItem = homeItem
        tabBar.delegate = self

        tabBar.isTranslucent = true
    }

    private func configureAppearance() {
        let appearance = UITabBarAppearance()

        // Classic Apple blur instead of Liquid Glass.
        appearance.configureWithTransparentBackground()

        appearance.backgroundEffect = UIBlurEffect(
            style: .systemChromeMaterial
        )

        appearance.backgroundColor = UIColor.clear

        appearance.shadowColor = UIColor.separator.withAlphaComponent(0.35)

        appearance.stackedLayoutAppearance.normal.iconColor =
            UIColor.secondaryLabel

        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.secondaryLabel,
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]

        appearance.stackedLayoutAppearance.selected.iconColor =
            UIColor.label

        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]

        tabBar.standardAppearance = appearance

        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
    }

    private func configureLayout() {
        view.addSubview(tabBar)

        tabBar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabBar.topAnchor.constraint(equalTo: view.topAnchor),
            tabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func tabBar(
        _ tabBar: UITabBar,
        didSelect item: UITabBarItem
    ) {
        guard let items = tabBar.items else {
            return
        }

        guard let index = items.firstIndex(of: item) else {
            return
        }

        onSelectionChanged?(index)
    }
}
