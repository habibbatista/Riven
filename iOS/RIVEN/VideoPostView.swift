import SwiftUI
import AVFoundation
import FirebaseAuth
import FirebaseFirestore

struct VideoPostView: View {

    let video: RIVENVideo

    @State private var player: AVPlayer?
    @State private var liked = false
    @State private var muted = false
    @State private var isPlaying = true
    @State private var showComments = false
    @State private var showShare = false
    @State private var showControls = true
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0

    @State private var hideControlsTask: DispatchWorkItem?

    private let db = Firestore.firestore()

    var body: some View {

        GeometryReader { geometry in

            ZStack {

                Color.black
                    .ignoresSafeArea()

                if let player {

                    RIVENCustomVideoSurface(
                        player: player
                    )
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        togglePlaybackControls()
                    }
                }

                if showControls {

                    playbackControls(
                        geometry: geometry,
                        player: player
                    )
                }

                if player == nil {

                    ProgressView()
                        .tint(.white)
                }
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
            .clipped()
        }
        .onAppear {
            startPlayer()
        }
        .onDisappear {
            stopPlayer()
        }
        .sheet(isPresented: $showComments) {
            CommentsView(
                videoID: video.id
            )
        }
        .sheet(isPresented: $showShare) {
            ShareView(
                videoURL: video.videoURL
            )
        }
    }

    // MARK: - Playback UI

    private func playbackControls(
        geometry: GeometryProxy,
        player: AVPlayer?
    ) -> some View {

        ZStack {

            VStack {

                Spacer()

                HStack(
                    alignment: .bottom,
                    spacing: 12
                ) {

                    captionSection

                    Spacer(minLength: 0)

                    actionBar(
                        player: player
                    )
                }
                .padding(.horizontal, 16)
                .padding(
                    .bottom,
                    max(
                        geometry.safeAreaInsets.bottom + 12,
                        18
                    )
                )
            }

            if !isPlaying {

                Image(systemName: "play.fill")
                    .font(
                        .system(
                            size: 28,
                            weight: .bold
                        )
                    )
                    .foregroundColor(.white)
                    .frame(
                        width: 70,
                        height: 70
                    )
                    .background(
                        Circle()
                            .fill(.black.opacity(0.45))
                    )
                    .allowsHitTesting(false)
            }

            VStack {

                Spacer()

                progressBar(
                    player: player
                )
                .padding(.horizontal, 16)
                .padding(
                    .bottom,
                    max(
                        geometry.safeAreaInsets.bottom + 4,
                        8
                    )
                )
            }
        }
        .transition(
            .opacity
        )
    }

    private var captionSection: some View {

        VStack(
            alignment: .leading,
            spacing: 7
        ) {

            Text("@\(video.handle)")
                .font(
                    .headline.weight(.semibold)
                )
                .foregroundColor(.white)

            if !video.caption.isEmpty {

                Text(video.caption)
                    .font(.body)
                    .foregroundColor(.white)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(
            maxWidth: 260,
            alignment: .leading
        )
        .shadow(
            color: .black.opacity(0.7),
            radius: 4,
            x: 0,
            y: 1
        )
    }

    private func actionBar(
        player: AVPlayer?
    ) -> some View {

        VStack(spacing: 22) {

            rivenActionButton(
                icon: liked
                    ? "heart.fill"
                    : "heart",
                color: liked
                    ? .red
                    : .white
            ) {
                toggleLike()
            }

            rivenActionButton(
                icon: "bubble.right",
                color: .white
            ) {
                showComments = true
            }

            rivenActionButton(
                icon: "square.and.arrow.up",
                color: .white
            ) {
                showShare = true
            }

            rivenActionButton(
                icon: muted
                    ? "speaker.slash"
                    : "speaker.wave.2",
                color: .white
            ) {
                toggleMute(
                    player: player
                )
            }
        }
        .padding(.bottom, 4)
    }

    private func rivenActionButton(
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {

        Button(
            action: action
        ) {

            Image(systemName: icon)
                .font(
                    .system(
                        size: 27,
                        weight: .semibold
                    )
                )
                .foregroundColor(color)
                .frame(
                    width: 52,
                    height: 52
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    // MARK: - Progress

    private func progressBar(
        player: AVPlayer?
    ) -> some View {

        VStack(spacing: 4) {

            if duration > 0 {

                Slider(
                    value: Binding(
                        get: {
                            currentTime
                        },
                        set: { newValue in
                            currentTime = newValue
                            player?.seek(
                                to: CMTime(
                                    seconds: newValue,
                                    preferredTimescale: 600
                                )
                            )
                        }
                    ),
                    in: 0...max(duration, 0.1)
                )
                .tint(.white)
            }
        }
    }

    // MARK: - Player

    private func startPlayer() {

        guard
            let url = URL(
                string: video.videoURL
            )
        else {
            return
        }

        let newPlayer = AVPlayer(
            url: url
        )

        newPlayer.actionAtItemEnd = .none
        newPlayer.isMuted = muted

        player = newPlayer

        if let currentUser = Auth.auth().currentUser {

            liked = video.likesBy.contains(
                currentUser.uid
            )
        }

        newPlayer.play()

        isPlaying = true

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: newPlayer.currentItem,
            queue: .main
        ) { _ in

            newPlayer.seek(
                to: .zero
            )

            newPlayer.play()

            DispatchQueue.main.async {
                currentTime = 0
                isPlaying = true
            }
        }

        observePlayerDuration(
            newPlayer
        )

        scheduleControlsHide()
    }

    private func stopPlayer() {

        hideControlsTask?.cancel()

        NotificationCenter.default.removeObserver(
            self,
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )

        player?.pause()
        player = nil
    }

    private func togglePlayback() {

        guard let player else {
            return
        }

        if player.timeControlStatus == .playing {

            player.pause()
            isPlaying = false

        } else {

            player.play()
            isPlaying = true
        }

        scheduleControlsHide()
    }

    private func togglePlaybackControls() {

        if showControls {

            togglePlayback()

        } else {

            withAnimation(.easeInOut(duration: 0.18)) {
                showControls = true
            }

            scheduleControlsHide()
        }
    }

    private func scheduleControlsHide() {

        hideControlsTask?.cancel()

        let task = DispatchWorkItem {

            DispatchQueue.main.async {

                if isPlaying {

                    withAnimation(
                        .easeInOut(
                            duration: 0.2
                        )
                    ) {
                        showControls = false
                    }
                }
            }
        }

        hideControlsTask = task

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 3,
            execute: task
        )
    }

    private func toggleMute(
        player: AVPlayer?
    ) {

        muted.toggle()

        player?.isMuted = muted

        scheduleControlsHide()
    }

    // MARK: - Time

    private func observePlayerDuration(
        _ player: AVPlayer
    ) {

        Timer.scheduledTimer(
            withTimeInterval: 0.25,
            repeats: true
        ) { timer in

            guard self.player === player else {
                timer.invalidate()
                return
            }

            let current =
                player.currentTime()
                    .seconds

            let total =
                player.currentItem?
                    .duration.seconds
                    ?? 0

            DispatchQueue.main.async {

                if current.isFinite {
                    self.currentTime = max(
                        current,
                        0
                    )
                }

                if total.isFinite,
                   total > 0 {

                    self.duration = total
                }
            }
        }
    }

    // MARK: - Like

    private func toggleLike() {

        guard
            let user = Auth.auth().currentUser
        else {
            return
        }

        let wasLiked = liked

        liked.toggle()

        if wasLiked {

            video.likesBy.removeAll {
                $0 == user.uid
            }

        } else {

            if !video.likesBy.contains(user.uid) {
                video.likesBy.append(
                    user.uid
                )
            }
        }

        let update: [String: Any] = [
            "likesBy": liked
                ? FieldValue.arrayUnion(
                    [user.uid]
                )
                : FieldValue.arrayRemove(
                    [user.uid]
                )
        ]

        db.collection("videos")
            .document(video.id)
            .updateData(update) { error in

                if let error {

                    DispatchQueue.main.async {
                        liked = wasLiked
                    }

                    print(
                        "RIVEN like error:",
                        error.localizedDescription
                    )
                }
            }
    }
}

// MARK: - Custom RIVEN Video Surface

struct RIVENCustomVideoSurface: UIViewRepresentable {

    let player: AVPlayer

    func makeUIView(
        context: Context
    ) -> RIVENPlayerView {

        let view = RIVENPlayerView()

        view.backgroundColor = .black

        // IMPORTANT:
        // resizeAspect preserves the entire video.
        // It does NOT crop to fill the screen.
        view.playerLayer.videoGravity =
            .resizeAspect

        view.player = player

        return view
    }

    func updateUIView(
        _ uiView: RIVENPlayerView,
        context: Context
    ) {

        uiView.player = player

        uiView.playerLayer.videoGravity =
            .resizeAspect
    }

    static func dismantleUIView(
        _ uiView: RIVENPlayerView,
        coordinator: ()
    ) {

        uiView.player?.pause()
        uiView.player = nil
    }
}

final class RIVENPlayerView: UIView {

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
