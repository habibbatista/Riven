import SwiftUI
import UIKit
import AVKit

struct CreateView: View {

    @State private var showPicker = false
    @State private var selectedURL: URL?
    @State private var caption = ""
    @State private var showPreview = false

    var body: some View {

        NavigationView {

            VStack(spacing: 20) {

                if let url = selectedURL {

                    VideoPlayer(
                        player: AVPlayer(url: url)
                    )
                    .frame(height: 400)
                    .cornerRadius(16)

                    TextField(
                        "Write a caption...",
                        text: $caption
                    )
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button("Post") {
                        uploadVideo()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary)
                    .foregroundColor(Color(UIColor.systemBackground))
                    .cornerRadius(12)

                } else {

                    Button {
                        showPicker = true
                    } label: {

                        VStack(spacing: 12) {

                            Image(systemName: "video")
                                .font(.system(size: 45))

                            Text("Choose Video")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(50)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationBarTitle("Create", displayMode: .inline)
        }
        .sheet(isPresented: $showPicker) {
            VideoPicker(selectedURL: $selectedURL)
        }
    }

    private func uploadVideo() {
        // Cloudinary upload goes here.
        // The HTML version already uses Cloudinary for media.
    }
}

struct VideoPicker: UIViewControllerRepresentable {

    @Binding var selectedURL: URL?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(
        context: Context
    ) -> UIImagePickerController {

        let picker = UIImagePickerController()

        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.movie"]
        picker.delegate = context.coordinator

        return picker
    }

    func updateUIViewController(
        _ controller: UIImagePickerController,
        context: Context
    ) {}

    final class Coordinator: NSObject,
        UIImagePickerControllerDelegate,
        UINavigationControllerDelegate {

        let parent: VideoPicker

        init(_ parent: VideoPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [
                UIImagePickerController.InfoKey : Any
            ]
        ) {

            if let url = info[
                .mediaURL
            ] as? URL {

                parent.selectedURL = url
            }

            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(
            _ picker: UIImagePickerController
        ) {
            picker.dismiss(animated: true)
        }
    }
}
