import SwiftUI
import AVFoundation
import FirebaseFirestore

struct RIVENVideo: Identifiable {
    let id: String
    let uid: String
    let authorName: String
    let authorHandle: String
    let authorPfp: String
    let videoURL: String
    let caption: String
    var likesBy: [String]
    var commentsCount: Int
    var isPrivate: Bool

    init(
        id: String,
        uid: String = "",
        authorName: String = "User",
        authorHandle: String = "user",
        authorPfp: String = "",
        videoURL: String,
        caption: String = "",
        likesBy: [String] = [],
        commentsCount: Int = 0,
        isPrivate: Bool = false
    ) {
        self.id = id
        self.uid = uid
        self.authorName = authorName
        self.authorHandle = authorHandle
        self.authorPfp = authorPfp
        self.videoURL = videoURL
        self.caption = caption
        self.likesBy = likesBy
        self.commentsCount = commentsCount
        self.isPrivate = isPrivate
    }
}

struct FeedView: View {
    @State private var videos: [RIVENVideo] = []
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
                            FYPVideoPage(
                                video: video,
                                isCurrent: currentIndex == index
                            )
                            .tag(index)
                            .frame(
                                width: geometry.size.width,
                                height: geometry.size.height
                            )
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                }
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
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

                return RIVENVideo(
                    id: document.documentID,
                    uid: data["uid"] as? String ?? "",
                    authorName: data["authorName"] as? String ?? "User",
                    authorHandle: data["authorHandle"] as? String ?? "user",
                    authorPfp: data["authorPfp"] as? String ?? "",
                    videoURL: videoURL,
                    caption: data["caption"] as? String ?? "",
                    likesBy: data["likesBy"] as? [String] ?? [],
                    commentsCount: data["commentsCount"] as? Int ?? 0,
                    isPrivate: data["isPrivate"] as? Bool ?? false
                )
            }
        } catch {
            print("FYP load error:", error)
        }
    }
}

struct FYPVideoPage: View {
    let video: RIVENVideo
    let isCurrent: Bool

    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var isMuted = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()

                if let player {
                    FYPPlayerView(player: player)
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height
                        )
                        .clipped()
                        .ignoresSafeArea()
                }

                VStack {
                    Spacer()

                    HStack(alignment: .bottom) {
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

                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 105)
                }

                VStack {
                    Spacer()

                    HStack {
                        Spacer()

                        VStack(spacing: 28) {
                            Button {
                                // Like
                            } label: {
                                Image(systemName: "heart")
                                    .font(.system(size: 31))
                                    .foregroundStyle(.white)
                            }

                            Button {
                                // Comments
                            } label: {
                                Image(systemName: "bubble.right")
                                    .font(.system(size: 30))
                                    .foregroundStyle(.white)
                            }

                            Button {
                                // Share
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

                VStack {
                    HStack {
                        Spacer()

                        Button {
                            isMuted.toggle()
                            player?.isMuted = isMuted
                        } label: {
                            Image(
                                systemName: isMuted
                                    ? "speaker.slash.fill"
                                    : "speaker.wave.2.fill"
                            )
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
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
            .clipped()
            .ignoresSafeArea()
            .onAppear {
                let newPlayer = AVPlayer(
                    url: URL(string: video.videoURL)!
                )

                newPlayer.actionAtItemEnd = .none
                newPlayer.isMuted = isMuted

                player = newPlayer

                if isCurrent {
                    newPlayer.play()
                    isPlaying = true
                }

                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: newPlayer.currentItem,
                    queue: .main
                ) { _ in
                    newPlayer.seek(to: .zero)

                    if isCurrent {
                        newPlayer.play()
                    }
                }
            }
            .onChange(of: isCurrent) { active in
                if active {
                    player?.play()
                    isPlaying = true
                } else {
                    player?.pause()
                    isPlaying = false
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

    func makeUIView(context: Context) -> FYPPlayerUIView {
        let view = FYPPlayerUIView()
        view.player = player
        return view
    }

    func updateUIView(
        _ uiView: FYPPlayerUIView,
        context: Context
    ) {
        uiView.player = player
    }
}

final class FYPPlayerUIView: UIView {
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    private var playerLayer: AVPlayerLayer {
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
