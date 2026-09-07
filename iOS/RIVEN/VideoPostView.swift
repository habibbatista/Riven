import SwiftUI
import AVKit

struct VideoPostView: View {

    let video: RIVENVideo

    @State private var player: AVPlayer?
    @State private var liked = false
    @State private var muted = false
    @State private var showComments = false
    @State private var showShare = false

    var body: some View {

        ZStack {

            Color.black
                .edgesIgnoringSafeArea(.all)

            if let player = player {

                VideoPlayer(player: player)
                    .edgesIgnoringSafeArea(.all)
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            }

            VStack {

                Spacer()

                HStack(alignment: .bottom) {

                    VStack(alignment: .leading, spacing: 8) {

                        Text("@\(video.handle)")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text(video.caption)
                            .font(.body)
                            .foregroundColor(.white)
                            .lineLimit(4)

                    }

                    Spacer()

                    VStack(spacing: 22) {

                        Button {
                            liked.toggle()
                        } label: {
                            Image(systemName: liked ? "heart.fill" : "heart")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        }

                        Button {
                            showComments = true
                        } label: {
                            Image(systemName: "bubble.right")
                                .font(.system(size: 27))
                                .foregroundColor(.white)
                        }

                        Button {
                            showShare = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 27))
                                .foregroundColor(.white)
                        }

                        Button {
                            muted.toggle()
                            player?.isMuted = muted
                        } label: {
                            Image(
                                systemName: muted
                                    ? "speaker.slash"
                                    : "speaker.wave.2"
                            )
                            .font(.system(size: 27))
                            .foregroundColor(.white)
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            guard let url = URL(string: video.videoURL) else {
                return
            }

            let newPlayer = AVPlayer(url: url)
            newPlayer.isMuted = muted
            player = newPlayer

            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: newPlayer.currentItem,
                queue: .main
            ) { _ in
                newPlayer.seek(to: .zero)
                newPlayer.play()
            }
        }
        .sheet(isPresented: $showComments) {
            CommentsView(videoID: video.id)
        }
        .sheet(isPresented: $showShare) {
            ShareView(videoURL: video.videoURL)
        }
    }
}
