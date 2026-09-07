import SwiftUI
import UIKit

struct AsyncImageCompat: View {

    let url: URL

    @State private var image: UIImage?

    var body: some View {

        Group {

            if let image = image {

                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()

            } else {

                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFill()
            }
        }
        .onAppear {
            load()
        }
    }

    private func load() {

        URLSession.shared.dataTask(with: url) {
            data, _, _ in

            guard let data = data,
                  let downloaded = UIImage(data: data) else {
                return
            }

            DispatchQueue.main.async {
                image = downloaded
            }

        }.resume()
    }
}
