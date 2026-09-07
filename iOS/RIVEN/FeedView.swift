import SwiftUI
import AVKit
import AVFoundation
import FirebaseAuth
import FirebaseFirestore

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

    var authorHandle: String {
        handle
    }
}

struct FeedView: View {

    @State private var videos: [RIVENVideo] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    // Only this video is allowed to be playing.
    @State private var activeVideoID: String?

    var body: some View {

        GeometryReader { geometry in

            ZStack {

                Color.black
                    .ignoresSafeArea(edges: .horizontal)

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

                    ScrollView(
                        .vertical,
                        showsIndicators: false
                    ) {

                        LazyVStack(
                            spacing: 0
                        ) {

                            ForEach(videos) { video in

                                VideoPostView(
                                    video: video,
                                    isActive: activeVideoID == video.id
                                )
                                .frame(
                                    width: geometry.size.width,
                                    height: geometry.size.height
                                )
                                .background(Color.black)
                                .id(video.id)

                                // When this post becomes visible,
                                // make it the ONLY active video.
                                .onAppear {

                                    activeVideoID = video.id
                                }

                                // When the active post leaves the
                                // screen, deactivate it.
                                .onDisappear {

                                    if activeVideoID == video.id {
                                        activeVideoID = nil
                                    }
                                }
                            }
                        }
                    }
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .scrollTargetBehaviorCompat()
                    .onScrollPositionChangeCompat { visibleID in

                        guard let visibleID else {
                            activeVideoID = nil
                            return
                        }

                        // Switching this value automatically makes
                        // the previous VideoPostView inactive.
                        if activeVideoID != visibleID {
                            activeVideoID = visibleID
                        }
                    }
                }
            }
        }
        .task {

            if videos.isEmpty {
                loadVideos()
            }
        }
        .onDisappear {

            // Leaving the feed stops whichever video is playing.
            activeVideoID = nil
        }
    }

    private func loadVideos() {

        isLoading = true
        errorMessage = nil

        // Stop any currently playing video while reloading.
        activeVideoID = nil

        Firestore.firestore()
            .collection("videos")
            .order(
                by: "createdAt",
                descending: true
            )
            .limit(to: 60)
            .getDocuments { snapshot, error in

                DispatchQueue.main.async {

                    isLoading = false

                    if let error {

                        errorMessage =
                            error.localizedDescription

                        return
                    }

                    guard let documents =
                            snapshot?.documents
                    else {

                        videos = []
                        activeVideoID = nil
                        return
                    }

                    videos =
                        documents.compactMap { document in

                            let data =
                                document.data()

                            guard
                                let videoURL =
                                    data["videoUrl"] as? String,
                                !videoURL.isEmpty
                            else {
                                return nil
                            }

                            let uid =
                                data["uid"] as? String
                                ?? ""

                            let authorName =
                                data["authorName"] as? String
                                ?? "RIVEN User"

                            let handle =
                                data["authorHandle"] as? String
                                ?? data["handle"] as? String
                                ?? ""

                            let authorPfp =
                                data["authorPfp"] as? String
                                ?? ""

                            let caption =
                                data["caption"] as? String
                                ?? ""

                            let likesBy =
                                data["likesBy"] as? [String]
                                ?? []

                            let commentsCount =
                                data["commentsCount"] as? Int
                                ?? 0

                            let isPrivate =
                                data["isPrivate"] as? Bool
                                ?? false

                            if isPrivate {

                                let currentUID =
                                    Auth.auth()
                                        .currentUser?
                                        .uid
                                        ?? ""

                                if uid != currentUID {
                                    return nil
                                }
                            }

                            return RIVENVideo(
                                id:
                                    document.documentID,
                                uid:
                                    uid,
                                authorName:
                                    authorName,
                                handle:
                                    handle,
                                authorPfp:
                                    authorPfp,
                                videoURL:
                                    videoURL,
                                caption:
                                    caption,
                                likesBy:
                                    likesBy,
                                commentsCount:
                                    commentsCount,
                                isPrivate:
                                    isPrivate
                            )
                        }

                    // Start only the first video after loading.
                    activeVideoID =
                        videos.first?.id
                }
            }
    }
}


// MARK: - iOS 15 Compatibility

private extension View {

    @ViewBuilder
    func scrollTargetBehaviorCompat() -> some View {
        self
    }

    @ViewBuilder
    func onScrollPositionChangeCompat(
        _ action: @escaping (String?) -> Void
    ) -> some View {
        self
    }
}
