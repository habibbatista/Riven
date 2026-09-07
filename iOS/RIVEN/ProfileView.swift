import SwiftUI
import UIKit
import AVFoundation
import AVKit
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @State private var name = ""
    @State private var handle = ""
    @State private var profileImageURL = ""

    @State private var followingCount = 0
    @State private var followersCount = 0
    @State private var likesCount = 0

    @State private var videos: [RIVENProfileVideo] = []

    @State private var isLoadingProfile = true
    @State private var selectedVideo: RIVENProfileVideo?

    private let db = Firestore.firestore()

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {

                profileHeader

                statsSection

                Divider()
                    .padding(.top, 18)

                videosSection
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
        .sheet(item: $selectedVideo) { video in
            RIVENVideoPlayerView(url: video.videoURL)
        }
        .onAppear {
            loadProfile()
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 12) {

            Group {
                if !profileImageURL.isEmpty,
                   let url = URL(string: profileImageURL) {

                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()

                        case .failure:
                            profilePlaceholder

                        case .empty:
                            ProgressView()

                        @unknown default:
                            profilePlaceholder
                        }
                    }

                } else {
                    profilePlaceholder
                }
            }
            .frame(width: 96, height: 96)
            .clipShape(Circle())

            if isLoadingProfile {
                ProgressView()
                    .padding(.top, 4)
            } else {
                Text(name.isEmpty ? "RIVEN User" : name)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.primary)

                Text(handle.isEmpty ? "@user" : "@\(handle)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Button {
                // Profile customization screen already exists.
            } label: {
                Text("Edit Profile")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: 180)
                    .frame(height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                Color(uiColor: .separator),
                                lineWidth: 1
                            )
                    )
            }
        }
        .padding(.top, 24)
        .padding(.horizontal, 20)
    }

    private var profilePlaceholder: some View {
        ZStack {
            Circle()
                .fill(Color(uiColor: .secondarySystemBackground))

            Image(systemName: "person.fill")
                .font(.system(size: 38))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 0) {
            profileStat(
                value: videos.count,
                title: "Posts"
            )

            profileStat(
                value: followersCount,
                title: "Followers"
            )

            profileStat(
                value: followingCount,
                title: "Following"
            )

            profileStat(
                value: likesCount,
                title: "Likes"
            )
        }
        .padding(.top, 24)
        .padding(.horizontal, 12)
    }

    private func profileStat(
        value: Int,
        title: String
    ) -> some View {
        VStack(spacing: 5) {
            Text("\(value)")
                .font(.headline.weight(.bold))
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Videos

    private var videosSection: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack {
                Text("Videos")
                    .font(.headline.weight(.bold))

                Spacer()

                if !videos.isEmpty {
                    Text("\(videos.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)

            if isLoadingProfile {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 30)

            } else if videos.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "video.slash")
                        .font(.system(size: 30))
                        .foregroundColor(.secondary)

                    Text("No videos yet")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 35)

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
                        RIVENVideoThumbnail(video: video)
                            .aspectRatio(0.72, contentMode: .fill)
                            .clipped()
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedVideo = video
                            }
                    }
                }
            }
        }
    }

    // MARK: - Firebase

    private func loadProfile() {
        guard let user = Auth.auth().currentUser else {
            isLoadingProfile = false
            return
        }

        isLoadingProfile = true

        let userRef = db.collection("users").document(user.uid)

        userRef.getDocument { snapshot, error in
            DispatchQueue.main.async {

                if let data = snapshot?.data() {
                    self.name =
                        data["name"] as? String
                        ?? user.displayName
                        ?? ""

                    self.handle =
                        data["handle"] as? String
                        ?? ""

                    self.profileImageURL =
                        data["pfp"] as? String
                        ?? user.photoURL?.absoluteString
                        ?? ""

                    if let following = data["following"] as? [String] {
                        self.followingCount = following.count
                    } else if let following = data["following"] as? [Any] {
                        self.followingCount = following.count
                    }

                    if let count = data["followersCount"] as? Int {
                        self.followersCount = count
                    } else if let followers = data["followers"] as? [String] {
                        self.followersCount = followers.count
                    } else if let followers = data["followers"] as? [Any] {
                        self.followersCount = followers.count
                    }
                } else {
                    self.name = user.displayName ?? ""
                    self.profileImageURL =
                        user.photoURL?.absoluteString ?? ""
                }

                self.loadVideos(uid: user.uid)
            }
        }
    }

    private func loadVideos(uid: String) {
        db.collection("videos")
            .whereField("uid", isEqualTo: uid)
            .getDocuments { snapshot, error in

                DispatchQueue.main.async {

                    guard let documents = snapshot?.documents else {
                        self.videos = []
                        self.likesCount = 0
                        self.isLoadingProfile = false
                        return
                    }

                    var loadedVideos: [RIVENProfileVideo] = []

                    for document in documents {
                        let data = document.data()

                        guard let videoURLString = data["videoUrl"] as? String,
                              let videoURL = URL(string: videoURLString)
                        else {
                            continue
                        }

                        let caption =
                            data["caption"] as? String ?? ""

                        let likesBy =
                            data["likesBy"] as? [String] ?? []

                        let timestamp =
                            data["createdAt"] as? Timestamp

                        let video = RIVENProfileVideo(
                            id: document.documentID,
                            videoURL: videoURL,
                            caption: caption,
                            likes: likesBy.count,
                            createdAt: timestamp?.dateValue()
                        )

                        loadedVideos.append(video)
                    }

                    loadedVideos.sort {
                        ($0.createdAt ?? .distantPast)
                        >
                        ($1.createdAt ?? .distantPast)
                    }

                    self.videos = loadedVideos

                    self.likesCount = loadedVideos.reduce(0) {
                        $0 + $1.likes
                    }

                    self.isLoadingProfile = false
                }
            }
    }
}

// MARK: - Video Model

private struct RIVENProfileVideo: Identifiable {
    let id: String
    let videoURL: URL
    let caption: String
    let likes: Int
    let createdAt: Date?
}

// MARK: - Thumbnail

private struct RIVENVideoThumbnail: View {
    let video: RIVENProfileVideo

    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack(alignment: .bottomLeading) {

            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                Color(uiColor: .secondarySystemBackground)

                ProgressView()
            }

            LinearGradient(
                gradient: Gradient(
                    colors: [
                        .clear,
                        .black.opacity(0.45)
                    ]
                ),
                startPoint: .top,
                endPoint: .bottom
            )

            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 10))

                Text("\(video.likes)")
                    .font(.caption2.weight(.semibold))
            }
            .foregroundColor(.white)
            .padding(7)
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .clipped()
        .task {
            await generateThumbnail()
        }
    }

    private func generateThumbnail() async {
        let asset = AVURLAsset(url: video.videoURL)

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(
            width: 500,
            height: 700
        )

        let time = CMTime(
            seconds: 0.5,
            preferredTimescale: 600
        )

        do {
            let image = try generator.copyCGImage(
                at: time,
                actualTime: nil
            )

            let uiImage = UIImage(cgImage: image)

            await MainActor.run {
                self.thumbnail = uiImage
            }
        } catch {
            // The placeholder remains visible if the remote video
            // cannot provide a thumbnail.
        }
    }
}

// MARK: - Video Player

private struct RIVENVideoPlayerView: View {
    let url: URL

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {

            Color.black
                .ignoresSafeArea()

            VideoPlayer(
                player: AVPlayer(url: url)
            )
            .ignoresSafeArea()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(.black.opacity(0.55))
                    )
            }
            .padding(.top, 12)
            .padding(.trailing, 16)
        }
    }
}
