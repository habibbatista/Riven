import SwiftUI
import UIKit
import AVFoundation
import AVKit
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {

    @State private var username = ""
    @State private var handle = ""
    @State private var bio = ""
    @State private var profileImageURL = ""

    @State private var videos: [ProfileVideo] = []
    @State private var isLoading = true

    @State private var selectedVideo: ProfileVideo?

    private let db = Firestore.firestore()

    private let columns = [
        GridItem(
            .flexible(),
            spacing: 2
        ),
        GridItem(
            .flexible(),
            spacing: 2
        ),
        GridItem(
            .flexible(),
            spacing: 2
        )
    ]

    var body: some View {

        NavigationView {

            ScrollView {

                VStack(
                    spacing: 18
                ) {

                    profileHeader

                    Divider()
                        .padding(.horizontal)

                    if isLoading {

                        ProgressView()
                            .padding(.top, 30)

                    } else {

                        LazyVGrid(
                            columns: columns,
                            spacing: 2
                        ) {

                            ForEach(videos) { video in

                                Button {

                                    selectedVideo =
                                        video

                                } label: {

                                    RIVENVideoThumbnail(
                                        video: video
                                    )
                                    .frame(
                                        maxWidth: .infinity
                                    )
                                    .aspectRatio(
                                        9.0 / 16.0,
                                        contentMode: .fit
                                    )
                                    .clipped()
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.top, 20)
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
        }
        .fullScreenCover(
            item: $selectedVideo
        ) { video in

            RIVENVideoPlayerView(
                video: video
            )
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {

        VStack(
            spacing: 12
        ) {

            if !profileImageURL.isEmpty,
               let url = URL(
                    string: profileImageURL
               ) {

                AsyncImage(
                    url: url
                ) { image in

                    image
                        .resizable()
                        .scaledToFill()

                } placeholder: {

                    Image(
                        systemName:
                            "person.circle.fill"
                    )
                    .resizable()
                    .scaledToFill()
                    .foregroundColor(
                        .secondary
                    )
                }
                .frame(
                    width: 92,
                    height: 92
                )
                .clipShape(
                    Circle()
                )

            } else {

                Image(
                    systemName:
                        "person.circle.fill"
                )
                .resizable()
                .scaledToFill()
                .frame(
                    width: 92,
                    height: 92
                )
                .foregroundColor(
                    .secondary
                )
            }

            Text(
                username.isEmpty
                    ? "RIVEN User"
                    : username
            )
            .font(
                .title2.weight(.bold)
            )

            if !handle.isEmpty {

                Text("@\(handle)")
                    .foregroundColor(
                        .secondary
                    )
            }

            if !bio.isEmpty {

                Text(bio)
                    .font(.body)
                    .multilineTextAlignment(
                        .center
                    )
                    .padding(
                        .horizontal,
                        30
                    )
            }

            HStack(
                spacing: 30
            ) {

                VStack {

                    Text(
                        "\(videos.count)"
                    )
                    .font(
                        .headline.weight(.bold)
                    )

                    Text("Videos")
                        .font(
                            .caption
                        )
                        .foregroundColor(
                            .secondary
                        )
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Load Profile

    private func loadProfile() {

        guard
            let uid =
                Auth.auth()
                    .currentUser?
                    .uid
        else {

            isLoading = false
            return
        }

        isLoading = true

        db.collection("users")
            .document(uid)
            .getDocument { snapshot, error in

                DispatchQueue.main.async {

                    if let data =
                        snapshot?.data() {

                        username =
                            data["username"]
                                as? String
                                ?? data["displayName"]
                                as? String
                                ?? ""

                        handle =
                            data["handle"]
                                as? String
                                ?? data["username"]
                                as? String
                                ?? ""

                        bio =
                            data["bio"]
                                as? String
                                ?? ""

                        profileImageURL =
                            data["profileImageURL"]
                                as? String
                                ?? data["photoURL"]
                                as? String
                                ?? data["profileImageUrl"]
                                as? String
                                ?? ""
                    }

                    loadVideos(
                        uid: uid
                    )
                }
            }
    }

    // MARK: - Load Videos

    private func loadVideos(
        uid: String
    ) {

        db.collection("videos")
            .whereField(
                "uid",
                isEqualTo: uid
            )
            .getDocuments { snapshot, error in

                DispatchQueue.main.async {

                    isLoading = false

                    guard
                        let documents =
                            snapshot?.documents
                    else {

                        videos = []
                        return
                    }

                    videos =
                        documents
                            .compactMap {
                                document in

                                let data =
                                    document.data()

                                guard
                                    let videoURL =
                                        data[
                                            "videoUrl"
                                        ] as? String,
                                    !videoURL.isEmpty
                                else {
                                    return nil
                                }

                                let caption =
                                    data[
                                        "caption"
                                    ] as? String
                                    ?? ""

                                let likesBy =
                                    data[
                                        "likesBy"
                                    ] as? [String]
                                    ?? []

                                let createdAt =
                                    data[
                                        "createdAt"
                                    ] as? Timestamp

                                return ProfileVideo(
                                    id:
                                        document
                                            .documentID,
                                    videoURL:
                                        videoURL,
                                    caption:
                                        caption,
                                    likesBy:
                                        likesBy,
                                    createdAt:
                                        createdAt
                                )
                            }
                            .sorted {

                                ($0.createdAt?
                                    .dateValue()
                                    ?? .distantPast)
                                >
                                ($1.createdAt?
                                    .dateValue()
                                    ?? .distantPast)
                            }
                }
            }
    }
}

// MARK: - Profile Video

struct ProfileVideo:
    Identifiable {

    let id: String
    let videoURL: String
    let caption: String
    let likesBy: [String]
    let createdAt: Timestamp?
}

// MARK: - Video Thumbnail

struct RIVENVideoThumbnail:
    View {

    let video: ProfileVideo

    @State private var thumbnail:
        UIImage?

    var body: some View {

        ZStack {

            Color.black

            if let thumbnail {

                Image(
                    uiImage: thumbnail
                )
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
        .task {

            generateThumbnail()
        }
    }

    private func generateThumbnail() {

        guard
            let url = URL(
                string: video.videoURL
            )
        else {
            return
        }

        let asset =
            AVAsset(
                url: url
            )

        let generator =
            AVAssetImageGenerator(
                asset: asset
            )

        generator.appliesPreferredTrackTransform =
            true

        generator.maximumSize =
            CGSize(
                width: 500,
                height: 889
            )

        let time =
            CMTime(
                seconds: 0.5,
                preferredTimescale: 600
            )

        generator.generateCGImagesAsynchronously(
            forTimes: [time]
        ) { _, image, _, _, _ in

            guard
                let image
            else {
                return
            }

            let uiImage =
                UIImage(
                    cgImage: image
                )

            DispatchQueue.main.async {

                thumbnail =
                    uiImage
            }
        }
    }
}

// MARK: - Video Player

struct RIVENVideoPlayerView:
    View {

    let video: ProfileVideo

    @Environment(
        \.dismiss
    )
    private var dismiss

    @State private var player:
        AVPlayer?

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

                        dismiss()

                    } label: {

                        Image(
                            systemName:
                                "xmark"
                        )
                        .font(
                            .system(
                                size: 18,
                                weight: .bold
                            )
                        )
                        .foregroundColor(
                            .white
                        )
                        .frame(
                            width: 42,
                            height: 42
                        )
                        .background(
                            Color.black
                                .opacity(0.45)
                        )
                        .clipShape(
                            Circle()
                        )
                    }

                    Spacer()
                }
                .padding()

                Spacer()
            }
        }
        .onAppear {

            guard
                let url =
                    URL(
                        string:
                            video.videoURL
                    )
            else {
                return
            }

            let newPlayer =
                AVPlayer(
                    url: url
                )

            newPlayer.isMuted = false

            player =
                newPlayer

            newPlayer.play()
        }
        .onDisappear {

            player?.pause()
            player = nil
        }
    }
}
