import SwiftUI
import AVKit
import AVFoundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - Video Model

struct RIVENVideo: Identifiable {
    let id: String
    let uid: String
    let authorName: String
    let handle: String
    let authorPfp: String
    let videoURL: String
    let caption: String
    var likesBy: [String]
    var commentsCount: Int
    var isPrivate: Bool

    // Compatibility with code that uses authorHandle
    var authorHandle: String {
        handle
    }
}

// MARK: - Feed View

struct FeedView: View {
    @State private var videos: [RIVENVideo] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .tint(.white)
            } else if let errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 34))
                        .foregroundColor(.white)

                    Text(errorMessage)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)

                    Button("Retry") {
                        loadVideos()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }
            } else if videos.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "video.slash")
                        .font(.system(size: 36))
                        .foregroundColor(.white)

                    Text("No videos yet")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Videos will appear here when people post.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 30)
            } else {
                TabView {
                    ForEach(videos) { video in
                        VideoPostView(video: video)
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: .infinity
                            )
                            .background(Color.black)
                            .ignoresSafeArea()
                            .tag(video.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
                .ignoresSafeArea()
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .ignoresSafeArea()
        .task {
            if videos.isEmpty {
                loadVideos()
            }
        }
    }

    // MARK: - Load Videos

    private func loadVideos() {
        isLoading = true
        errorMessage = nil

        Firestore.firestore()
            .collection("videos")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in

                DispatchQueue.main.async {
                    isLoading = false

                    if let error {
                        errorMessage = error.localizedDescription
                        return
                    }

                    guard let documents = snapshot?.documents else {
                        videos = []
                        return
                    }

                    videos = documents.compactMap { document in
                        let data = document.data()

                        guard let videoURL = data["videoUrl"] as? String,
                              !videoURL.isEmpty else {
                            return nil
                        }

                        let uid = data["uid"] as? String ?? ""

                        let authorName =
                            data["authorName"] as? String ?? "RIVEN User"

                        let handle =
                            data["authorHandle"] as? String
                            ?? data["handle"] as? String
                            ?? ""

                        let authorPfp =
                            data["authorPfp"] as? String ?? ""

                        let caption =
                            data["caption"] as? String ?? ""

                        let likesBy =
                            data["likesBy"] as? [String] ?? []

                        let commentsCount =
                            data["commentsCount"] as? Int ?? 0

                        let isPrivate =
                            data["isPrivate"] as? Bool ?? false

                        // Don't show private videos unless they belong
                        // to the currently signed-in user.
                        if isPrivate {
                            let currentUID =
                                Auth.auth().currentUser?.uid ?? ""

                            if uid != currentUID {
                                return nil
                            }
                        }

                        return RIVENVideo(
                            id: document.documentID,
                            uid: uid,
                            authorName: authorName,
                            handle: handle,
                            authorPfp: authorPfp,
                            videoURL: videoURL,
                            caption: caption,
                            likesBy: likesBy,
                            commentsCount: commentsCount,
                            isPrivate: isPrivate
                        )
                    }
                }
            }
    }
}

// MARK: - Fullscreen Video Player

struct FYPPlayerView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.backgroundColor = .black
        view.playerLayer.videoGravity = .resizeAspectFill

        let player = AVPlayer(url: url)
        player.actionAtItemEnd = .none

        view.player = player
        player.play()

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }

        return view
    }

    func updateUIView(
        _ uiView: PlayerView,
        context: Context
    ) {
        uiView.playerLayer.videoGravity = .resizeAspectFill
    }

    static func dismantleUIView(
        _ uiView: PlayerView,
        coordinator: ()
    ) {
        uiView.player?.pause()
        uiView.player = nil
    }
}

// MARK: - AVPlayer Layer Container

final class PlayerView: UIView {
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }

    var player: AVPlayer? {
        get {
            playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }
}
