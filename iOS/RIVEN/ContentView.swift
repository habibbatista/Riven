import SwiftUI
import UIKit

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case 0:
                    FeedView()

                case 1:
                    SearchView()

                case 2:
                    CreateView()

                case 3:
                    InboxView()

                case 4:
                    ProfileView()

                default:
                    FeedView()
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )

            RIVENUIKitTabBar(selection: $selectedTab)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .background(Color.black)
        .ignoresSafeArea()
    }
}

// MARK: - Native iOS Tab Bar

struct RIVENUIKitTabBar: UIViewControllerRepresentable {
    @Binding var selection: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }

    func makeUIViewController(
        context: Context
    ) -> RIVENTabBarViewController {
        let controller = RIVENTabBarViewController()

        controller.onSelectionChanged = { index in
            context.coordinator.selection.wrappedValue = index
        }

        controller.setSelectedIndex(selection)

        return controller
    }

    func updateUIViewController(
        _ uiViewController: RIVENTabBarViewController,
        context: Context
    ) {
        uiViewController.setSelectedIndex(selection)

        uiViewController.onSelectionChanged = { index in
            context.coordinator.selection.wrappedValue = index
        }
    }

    final class Coordinator {
        var selection: Binding<Int>

        init(selection: Binding<Int>) {
            self.selection = selection
        }
    }
}

// MARK: - UIKit Tab Bar Controller

final class RIVENTabBarViewController: UIViewController {

    private let tabBar = UITabBar()

    var onSelectionChanged: ((Int) -> Void)?

    private var hasConfigured = false

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        view.isOpaque = false

        configureTabBar()
    }

    private func configureTabBar() {
        guard !hasConfigured else {
            return
        }

        hasConfigured = true

        tabBar.delegate = self
        tabBar.translatesAutoresizingMaskIntoConstraints = false

        tabBar.items = [
            UITabBarItem(
                title: "Home",
                image: UIImage(
                    systemName: "house"
                ),
                selectedImage: UIImage(
                    systemName: "house.fill"
                )
            ),

            UITabBarItem(
                title: "Search",
                image: UIImage(
                    systemName: "magnifyingglass"
                ),
                selectedImage: UIImage(
                    systemName: "magnifyingglass"
                )
            ),

            UITabBarItem(
                title: "Create",
                image: UIImage(
                    systemName: "plus"
                ),
                selectedImage: UIImage(
                    systemName: "plus"
                )
            ),

            UITabBarItem(
                title: "Inbox",
                image: UIImage(
                    systemName: "bubble.left.and.bubble.right"
                ),
                selectedImage: UIImage(
                    systemName: "bubble.left.and.bubble.right.fill"
                )
            ),

            UITabBarItem(
                title: "Profile",
                image: UIImage(
                    systemName: "person"
                ),
                selectedImage: UIImage(
                    systemName: "person.fill"
                )
            )
        ]

        tabBar.selectedItem = tabBar.items?.first

        let appearance = UITabBarAppearance()

        appearance.configureWithDefaultBackground()

        appearance.backgroundEffect = UIBlurEffect(
            style: .systemChromeMaterialDark
        )

        appearance.backgroundColor = UIColor(
            white: 0.08,
            alpha: 0.82
        )

        appearance.shadowColor = UIColor(
            white: 1.0,
            alpha: 0.12
        )

        let normal = appearance.stackedLayoutAppearance.normal

        normal.iconColor = .white.withAlphaComponent(0.78)

        normal.titleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.78),
            .font: UIFont.systemFont(
                ofSize: 12,
                weight: .medium
            )
        ]

        let selected = appearance.stackedLayoutAppearance.selected

        selected.iconColor = .white

        selected.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(
                ofSize: 12,
                weight: .semibold
            )
        ]

        tabBar.standardAppearance = appearance

        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }

        tabBar.isTranslucent = true

        view.addSubview(tabBar)

        NSLayoutConstraint.activate([
            tabBar.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 14
            ),

            tabBar.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -14
            ),

            tabBar.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -8
            ),

            tabBar.heightAnchor.constraint(
                equalToConstant: 72
            )
        ])

        tabBar.layer.cornerRadius = 36
        tabBar.layer.masksToBounds = true
    }

    func setSelectedIndex(_ index: Int) {
        guard
            let items = tabBar.items,
            index >= 0,
            index < items.count
        else {
            return
        }

        tabBar.selectedItem = items[index]
    }
}

extension RIVENTabBarViewController: UITabBarDelegate {

    func tabBar(
        _ tabBar: UITabBar,
        didSelect item: UITabBarItem
    ) {
        guard
            let items = tabBar.items,
            let index = items.firstIndex(of: item)
        else {
            return
        }

        onSelectionChanged?(index)
    }
}
