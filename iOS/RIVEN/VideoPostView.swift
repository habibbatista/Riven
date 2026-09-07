import SwiftUI
import UIKit
import AVFoundation
import FirebaseAuth
import FirebaseFirestore
struct VideoPostView: View {
    let video: RIVENVideo
    let isActive: Bool
    @State private var player: AVPlayer?
    @State private var liked = false
    @State private var muted = false
    @State private var isPlaying = false
    @State private var showComments = false
    @State private var showShare = false
    @State private var showControls = true
    @State private var hideControlsTask: DispatchWorkItem?
    private let db = Firestore.firestore()
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()
                if let player = player {
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
            applyActiveState()
        }
        .onDisappear {
            stopPlayer()
        }
        .onChange(of: isActive) { _ in
            applyActiveState()
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
    // MARK: - Active Video
    private func applyActiveState() {
        guard let player = player else {
            return
        }
        if isActive {
            player.play()
            isPlaying = true
            scheduleControlsHide()
        } else {
            player.pause()
            isPlaying = false
            hideControlsTask?.cancel()
            hideControlsTask = nil
            withAnimation(
                .easeInOut(duration: 0.15)
            ) {
                showControls = true
            }
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
                        geometry.safeAreaInsets.bottom + 76,
                        86
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
                            .fill(
                                Color.black.opacity(0.45)
                            )
                    )
                    .allowsHitTesting(false)
            }
        }
        .transition(.opacity)
    }
    private var captionSection: some View {
        VStack(
            alignment: .leading,
            spacing: 7
        ) {
            Text("@\(video.authorHandle)")
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
            color: Color.black.opacity(0.7),
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
        Button(action: action) {
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
        if let currentUser =
            Auth.auth().currentUser {
            liked = video.likesBy.contains(
                currentUser.uid
            )
        }
        // Do NOT automatically play every VideoPostView.
        // FeedView controls playback through isActive.
        isPlaying = false
        NotificationCenter.default.addObserver(
            forName:
                .AVPlayerItemDidPlayToEndTime,
            object:
                newPlayer.currentItem,
            queue:
                .main
        ) { _ in
            // Only loop if this is still the active video.
            guard isActive else {
                return
            }
            newPlayer.seek(
                to: .zero
            ) { _ in
                if isActive {
                    newPlayer.play()
                    isPlaying = true
                }
            }
        }
        if isActive {
            newPlayer.play()
            isPlaying = true
            scheduleControlsHide()
        }
    }
    private func stopPlayer() {
        hideControlsTask?.cancel()
        hideControlsTask = nil
        if let currentItem =
            player?.currentItem {
            NotificationCenter.default.removeObserver(
                self,
                name:
                    .AVPlayerItemDidPlayToEndTime,
                object:
                    currentItem
            )
        }
        player?.pause()
        player?.replaceCurrentItem(
            with: nil
        )
        player = nil
        isPlaying = false
    }
    // MARK: - Playback Controls
    private func togglePlayback() {
        guard
            let player = player,
            isActive
        else {
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
            withAnimation(
                .easeInOut(duration: 0.18)
            ) {
                showControls = true
            }
            scheduleControlsHide()
        }
    }
    private func scheduleControlsHide() {
        hideControlsTask?.cancel()
        guard isActive else {
            return
        }
        let task = DispatchWorkItem {
            if isPlaying {
                withAnimation(
                    .easeInOut(duration: 0.2)
                ) {
                    showControls = false
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
    // MARK: - Like
    private func toggleLike() {
        guard
            let user =
                Auth.auth().currentUser
        else {
            return
        }
        let wasLiked = liked
        liked.toggle()
        let update: [String: Any]
        if liked {
            update = [
                "likesBy":
                    FieldValue.arrayUnion(
                        [user.uid]
                    )
            ]
        } else {
            update = [
                "likesBy":
                    FieldValue.arrayRemove(
                        [user.uid]
                    )
            ]
        }
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
struct RIVENCustomVideoSurface:
    UIViewRepresentable {
    let player: AVPlayer
    func makeUIView(
        context: Context
    ) -> RIVENPlayerView {
        let view =
            RIVENPlayerView()
        view.backgroundColor =
            .black
        // resizeAspect keeps the complete video
        // visible and centers it inside the view.
        view.playerLayer.videoGravity =
            .resizeAspect
        view.player =
            player
        return view
    }
    func updateUIView(
        _ uiView: RIVENPlayerView,
        context: Context
    ) {
        uiView.player =
            player
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
// MARK: - Player View
final class RIVENPlayerView:
    UIView {
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }
    var playerLayer:
        AVPlayerLayer {
        layer as! AVPlayerLayer
    }
    var player: AVPlayer? {
        get {
            playerLayer.player
        }
        set {
            playerLayer.player =
                newValue
        }
    }
}
