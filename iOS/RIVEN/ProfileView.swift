import SwiftUI
import UIKit
import AVFoundation
import AVKit
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {

    let uid: String

    @State private var username = "RIVEN User"
    @State private var handle = ""
    @State private var bio = ""
    @State private var profileImageURL = ""

    @State private var videos: [ProfileVideo] = []
    @State private var isLoading = true
    @State private var selectedVideo: ProfileVideo?

    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {

                    profileHeader

                    Divider()
                        .opacity(0.35)

                    if isLoading {

                        ProgressView()
                            .padding(.top, 40)

                    } else if videos.isEmpty {

                        VStack(spacing: 10) {
                            Image(systemName: "video.slash")
                                .font(.system(size: 38))

                            Text("No videos yet")
                                .font(.headline)

                            Text("Videos posted by this user will appear here.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 45)
                        .padding(.horizontal, 30)

                    } else {

                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 2),
                                GridItem(.flexible(), spacing: 2),
                                GridItem(.flexible(), spacing: 2)
                            ],
                            spacing: 2
                        ) {
                            ForEach(videos) { video in
                                Button {
                                    selectedVideo = video
                                } label: {
                                    RIVENVideoThumbnail(video: video)
                                        .aspectRatio(
                                            9.0 / 16.0,
                                            contentMode: .fill
                                        )
                                        .frame(
                                            maxWidth: .infinity
                                        )
                                        .clipped()
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationBarTitle(
                "Profile",
                displayMode: .inline
            )
        }
        .navigationViewStyle(
            StackNavigationViewStyle()
        )
        .onAppear {
            loadProfile()
            loadVideos()
        }
        .fullScreenCover(item: $selectedVideo) { video in
            RIVENProfileVideoPlayer(video: video)
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 12) {

            if !profileImageURL.isEmpty,
               let url = URL(string: profileImageURL) {

                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .foregroundColor(.secondary)
                }
                .frame(
                    width: 90,
                    height: 90
                )
                .clipShape(Circle())

            } else {

                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .foregroundColor(.secondary)
                    .frame(
                        width: 90,
                        height: 90
                    )
            }

            Text(username)
                .font(.title2.weight(.bold))

            if !handle.isEmpty {
                Text("@\(handle)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if !bio.isEmpty {
                Text(bio)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 30)
            }
        }
        .padding(.top, 20)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Load Profile

    private func loadProfile() {

        db.collection("users")
            .document(uid)
            .getDocument { snapshot, error in

                guard let data = snapshot?.data(),
                      error == nil
                else {
                    return
                }

                DispatchQueue.main.async {

                    username =
                        data["username"] as? String
                        ?? data["displayName"] as? String
                        ?? "RIVEN User"

                    handle =
                        data["handle"] as? String
                        ?? data["username"] as? String
                        ?? ""

                    bio =
                        data["bio"] as? String
                        ?? ""

                    profileImageURL =
                        data["profileImageURL"] as? String
                        ?? data["profileImageUrl"] as? String
                        ?? data["photoURL"] as? String
                        ?? ""
                }
            }
    }

    // MARK: - Load Videos

    private func loadVideos() {

        isLoading = true

        db.collection("videos")
            .whereField("uid", isEqualTo: uid)
            .getDocuments { snapshot, error in

                DispatchQueue.main.async {

                    isLoading = false

                    guard
                        let documents = snapshot?.documents,
                        error == nil
                    else {
                        videos = []
                        return
                    }

                    videos = documents.compactMap { document in

                        let data = document.data()

                        guard
                            let videoURL =
                                data["videoUrl"] as? String,
                            !videoURL.isEmpty
                        else {
                            return nil
                        }

                        let caption =
                            data["caption"] as? String
                            ?? ""

                        let likesBy =
                            data["likesBy"] as? [String]
                            ?? []

                        return ProfileVideo(
                            id: document.documentID,
                            videoURL: videoURL,
                            caption: caption,
                            likesBy: likesBy
                        )
                    }

                    videos.sort { first, second in
                        first.id > second.id
                    }
                }
            }
    }
}


// MARK: - Profile Video Model

struct ProfileVideo: Identifiable {
    let id: String
    let videoURL: String
    let caption: String
    let likesBy: [String]
}


// MARK: - Video Thumbnail

struct RIVENVideoThumbnail: View {

    let video: ProfileVideo

    @State private var thumbnail: UIImage?

    var body: some View {

        ZStack {

            Color.black

            if let thumbnail {

                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                    .clipped()

            } else {

                ProgressView()
                    .tint(.white)
            }
        }
        .aspectRatio(
            9.0 / 16.0,
            contentMode: .fit
        )
        .clipped()
        .onAppear {
            generateThumbnail()
        }
    }

    private func generateThumbnail() {

        guard
            thumbnail == nil,
            let url = URL(string: video.videoURL)
        else {
            return
        }

        let asset = AVAsset(url: url)

        let generator =
            AVAssetImageGenerator(asset: asset)

        generator.appliesPreferredTrackTransform = true

        generator.maximumSize =
            CGSize(
                width: 500,
                height: 900
            )

        let time =
            CMTime(
                seconds: 0.5,
                preferredTimescale: 600
            )

        generator.generateCGImagesAsynchronously(
            forTimes: [NSValue(time: time)]
        ) { _, image, _, _, _ in

            guard let image else {
                return
            }

            let uiImage =
                UIImage(cgImage: image)

            DispatchQueue.main.async {
                thumbnail = uiImage
            }
        }
    }
}


// MARK: - Fullscreen Profile Video

struct RIVENProfileVideoPlayer: View {

    let video: ProfileVideo

    @Environment(\.presentationMode)
    private var presentationMode

    @State private var player: AVPlayer?

    var body: some View {

        ZStack {

            Color.black
                .ignoresSafeArea()

            if let player {

                RIVENCustomVideoSurface(
                    player: player
                )
                .ignoresSafeArea()
            }

            VStack {

                HStack {

                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(
                                .system(
                                    size: 18,
                                    weight: .bold
                                )
                            )
                            .foregroundColor(.white)
                            .frame(
                                width: 42,
                                height: 42
                            )
                            .background(
                                Circle()
                                    .fill(
                                        Color.black.opacity(0.45)
                                    )
                            )
                    }

                    Spacer()
                }
                .padding()

                Spacer()
            }
        }
        .onAppear {
            startPlayer()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    private func startPlayer() {

        guard
            let url = URL(string: video.videoURL)
        else {
            return
        }

        let newPlayer =
            AVPlayer(url: url)

        newPlayer.actionAtItemEnd = .none

        player = newPlayer

        newPlayer.play()

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: newPlayer.currentItem,
            queue: .main
        ) { _ in

            newPlayer.seek(to: .zero)
            newPlayer.play()
        }
    }
}
