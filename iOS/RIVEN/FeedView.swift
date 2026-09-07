import SwiftUI
import AVFoundation
import AVKit
import FirebaseFirestore

struct FeedView: View {
    @State private var videos: [FeedVideo] = []
    @State private var currentIndex = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()

                if videos.isEmpty {
                    ProgressView()
                        .tint(.white)
                } else {
                    TabView(selection: $currentIndex) {
                        ForEach(Array(videos.enumerated()), id: \.element.id) { index, video in
                            FYPVideoPage(video: video)
                                .tag(index)
                                .frame(
                                    width: geometry.size.width,
                                    height: geometry.size.height
                                )
                                .clipped()
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                }
            }
        }
        .ignoresSafeArea()
        .task {
            await loadVideos()
        }
    }

    private func loadVideos() async {
        do {
            let snapshot = try await Firestore.firestore()
                .collection("videos")
                .order(by: "createdAt", descending: true)
                .getDocuments()

            videos = snapshot.documents.compactMap { document in
                let data = document.data()

                guard let videoURL = data["videoUrl"] as? String,
                      !videoURL.isEmpty else {
                    return nil
                }

                return FeedVideo(
                    id: document.documentID,
                    authorName: data["authorName"] as? String ?? "",
                    authorHandle: data["authorHandle"] as? String ?? "",
                    authorPfp: data["authorPfp"] as? String ?? "",
                    videoURL: videoURL,
                    caption: data["caption"] as? String ?? "",
                    likes: data["likesBy"] as? [String] ?? []
                )
            }
        } catch {
            print("Failed to load FYP:", error)
        }
    }
}

struct FeedVideo: Identifiable {
    let id: String
    let authorName: String
    let authorHandle: String
    let authorPfp: String
    let videoURL: String
    let caption: String
    let likes: [String]
}

struct FYPVideoPage: View {
    let video: FeedVideo

    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var isMuted = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()

                if let player {
                    FYPPlayerView(
                        player: player,
                        isPlaying: $isPlaying
                    )
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .clipped()
                    .ignoresSafeArea()
                }

                VStack {
                    Spacer()

                    HStack(alignment: .bottom, spacing: 12) {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("@\(video.authorHandle)")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(.white)

                            if !video.caption.isEmpty {
                                Text(video.caption)
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white)
                                    .lineLimit(3)
                            }
                        }

                        Spacer(minLength: 70)
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 105)
                }

                VStack {
                    Spacer()

                    HStack {
                        Spacer()

                        VStack(spacing: 25) {
                            Button {
                                // Like action
                            } label: {
                                Image(systemName: "heart")
                                    .font(.system(size: 31))
                                    .foregroundStyle(.white)
                            }

                            Button {
                                // Comments action
                            } label: {
                                Image(systemName: "bubble.right")
                                    .font(.system(size: 30))
                                    .foregroundStyle(.white)
                            }

                            Button {
                                // Share action
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 30))
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(.trailing, 18)
                        .padding(.bottom, 125)
                    }
                }

                if !isPlaying {
                    Button {
                        player?.play()
                        isPlaying = true
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(.white)
                            .frame(width: 92, height: 92)
                            .background(.black.opacity(0.35))
                            .clipShape(Circle())
                    }
                }

                VStack {
                    HStack {
                        Spacer()

                        Button {
                            isMuted.toggle()
                            player?.isMuted = isMuted
                        } label: {
                            Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 52, height: 52)
                                .background(.black.opacity(0.35))
                                .clipShape(Circle())
                        }
                        .padding(.top, 60)
                        .padding(.trailing, 18)
                    }

                    Spacer()
                }
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
            .clipped()
            .onAppear {
                let newPlayer = AVPlayer(
                    url: URL(string: video.videoURL)!
                )
                newPlayer.actionAtItemEnd = .none
                player = newPlayer
                newPlayer.play()
                isPlaying = true

                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: newPlayer.currentItem,
                    queue: .main
                ) { _ in
                    newPlayer.seek(to: .zero)
                    newPlayer.play()
                }
            }
            .onDisappear {
                player?.pause()
                player = nil
            }
        }
        .ignoresSafeArea()
    }
}

struct FYPPlayerView: UIViewRepresentable {
    let player: AVPlayer
    @Binding var isPlaying: Bool

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.player = player
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        uiView.player = player
    }
}

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
            playerLayer.videoGravity = .resizeAspectFill
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
        playerLayer.videoGravity = .resizeAspectFill
    }
}
