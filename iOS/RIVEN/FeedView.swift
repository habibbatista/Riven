import SwiftUI
import AVKit
import FirebaseFirestore

struct RIVENVideo: Identifiable {
    let id: String
    let videoURL: String
    let username: String
    let handle: String
    let caption: String
    let avatarURL: String
}

final class FeedViewModel: ObservableObject {

    @Published var videos: [RIVENVideo] = []

    private let db = Firestore.firestore()

    func loadFeed() {

        db.collection("videos")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments { snapshot, error in

                guard let documents = snapshot?.documents else {
                    return
                }

                DispatchQueue.main.async {

                    self.videos = documents.compactMap { document in

                        let data = document.data()

                        guard let url = data["videoUrl"] as? String else {
                            return nil
                        }

                        return RIVENVideo(
                            id: document.documentID,
                            videoURL: url,
                            username: data["authorName"] as? String ?? "User",
                            handle: data["authorHandle"] as? String ?? "user",
                            caption: data["caption"] as? String ?? "",
                            avatarURL: data["authorPfp"] as? String ?? ""
                        )
                    }
                }
            }
    }
}

struct FeedView: View {

    @StateObject private var model = FeedViewModel()

    var body: some View {
        NavigationView {
            ZStack {

                Color.black
                    .edgesIgnoringSafeArea(.all)

                if model.videos.isEmpty {

                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .foregroundColor(.white)

                } else {

                    TabView {
                        ForEach(model.videos) { video in
                            VideoPostView(video: video)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            model.loadFeed()
        }
    }
}
