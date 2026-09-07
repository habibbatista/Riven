import SwiftUI

struct ShareView: UIViewControllerRepresentable {

    let videoURL: String

    func makeUIViewController(
        context: Context
    ) -> UIActivityViewController {

        let items: [Any] = [
            URL(string: videoURL) as Any
        ]

        return UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ controller: UIActivityViewController,
        context: Context
    ) {}
}
