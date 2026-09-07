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

    @State private var currentIndex = 0
    @State private var dragOffset: CGFloat = 0

    var body: some View {

        GeometryReader { geometry in

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

                    VStack(spacing: 0) {

                        ForEach(
                            Array(videos.enumerated()),
                            id: \.element.id
                        ) { index, video in

                            VideoPostView(
                                video: video,
                                isActive: currentIndex == index
                            )
                            .frame(
                                width: geometry.size.width,
                                height: geometry.size.height
                            )
                        }
                    }
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height,
                        alignment: .center
                    )
                    .offset(
                        y:
                            -CGFloat(currentIndex)
                            * geometry.size.height
                            + dragOffset
                    )
                    .animation(
                        .interactiveSpring(
                            response: 0.32,
                            dampingFraction: 0.86,
                            blendDuration: 0.12
                        ),
                        value: currentIndex
                    )
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(
                            minimumDistance: 10,
                            coordinateSpace: .local
                        )
                        .onChanged { value in

                            dragOffset = value.translation.height
                        }
                        .onEnded { value in

                            let translation =
                                value.translation.height

                            let predicted =
                                value.predictedEndTranslation.height

                            let threshold =
                                geometry.size.height * 0.18

                            var newIndex =
                                currentIndex

                            if translation < -threshold ||
                                predicted < -geometry.size.height * 0.35 {

                                newIndex =
                                    min(
                                        currentIndex + 1,
                                        videos.count - 1
                                    )

                            } else if translation > threshold ||
                                      predicted > geometry.size.height * 0.35 {

                                newIndex =
                                    max(
                                        currentIndex - 1,
                                        0
                                    )
                            }

                            dragOffset = 0
                            currentIndex = newIndex
                        }
                    )
                    .clipped()
                }
            }
        }
        .task {

            if videos.isEmpty {
                loadVideos()
            }
        }
        .onDisappear {

            dragOffset = 0
            currentIndex = 0
        }
    }

    private func loadVideos() {

        isLoading = true
        errorMessage = nil
        currentIndex = 0
        dragOffset = 0

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
                }
            }
    }
}
