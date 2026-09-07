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

    @State private var activeVideoID: String?

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

                    RIVENPagedFeed(
                        videos: videos,
                        activeVideoID: $activeVideoID
                    )
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                }
            }
        }
        .task {

            if videos.isEmpty {
                loadVideos()
            }
        }
        .onDisappear {
            activeVideoID = nil
        }
    }

    private func loadVideos() {

        isLoading = true
        errorMessage = nil
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

                    activeVideoID =
                        videos.first?.id
                }
            }
    }
}

// MARK: - Native iOS 15 Paging Feed

struct RIVENPagedFeed: UIViewRepresentable {

    let videos: [RIVENVideo]

    @Binding var activeVideoID: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(
        context: Context
    ) -> UIScrollView {

        let scrollView = UIScrollView()

        scrollView.backgroundColor = .black

        scrollView.isPagingEnabled = true
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = false

        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false

        scrollView.directionalLockEnabled = true

        scrollView.decelerationRate =
            .fast

        scrollView.delegate =
            context.coordinator

        buildPages(
            in: scrollView,
            coordinator: context.coordinator
        )

        return scrollView
    }

    func updateUIView(
        _ scrollView: UIScrollView,
        context: Context
    ) {

        context.coordinator.parent =
            self

        let needsRebuild =
            context.coordinator.videoIDs !=
            videos.map(\.id)

        if needsRebuild {

            buildPages(
                in: scrollView,
                coordinator: context.coordinator
            )
        }

        DispatchQueue.main.async {

            if
                let activeVideoID,
                let index =
                    videos.firstIndex(
                        where: {
                            $0.id == activeVideoID
                        }
                    )
            {

                let pageHeight =
                    scrollView.bounds.height

                guard pageHeight > 0 else {
                    return
                }

                let targetY =
                    CGFloat(index)
                    * pageHeight

                if abs(
                    scrollView.contentOffset.y
                    - targetY
                ) > 1 {

                    scrollView.setContentOffset(
                        CGPoint(
                            x: 0,
                            y: targetY
                        ),
                        animated: false
                    )
                }
            }
        }
    }

    private func buildPages(
        in scrollView: UIScrollView,
        coordinator: Coordinator
    ) {

        scrollView.subviews.forEach {
            $0.removeFromSuperview()
        }

        coordinator.videoIDs =
            videos.map(\.id)

        guard !videos.isEmpty else {
            return
        }

        let pageWidth =
            scrollView.bounds.width

        let pageHeight =
            scrollView.bounds.height

        guard
            pageWidth > 0,
            pageHeight > 0
        else {
            return
        }

        let hostingController =
            UIHostingController(
                rootView:
                    RIVENPagedFeedContent(
                        videos: videos,
                        activeVideoID:
                            $activeVideoID
                    )
            )

        hostingController.view.backgroundColor =
            .black

        hostingController.view.frame =
            CGRect(
                x: 0,
                y: 0,
                width: pageWidth,
                height:
                    pageHeight
                    * CGFloat(videos.count)
            )

        scrollView.addSubview(
            hostingController.view
        )

        coordinator.hostingController =
            hostingController

        scrollView.contentSize =
            CGSize(
                width: pageWidth,
                height:
                    pageHeight
                    * CGFloat(videos.count)
            )

        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero

        if let activeVideoID,
           let index =
                videos.firstIndex(
                    where: {
                        $0.id == activeVideoID
                    }
                ) {

            scrollView.contentOffset =
                CGPoint(
                    x: 0,
                    y:
                        CGFloat(index)
                        * pageHeight
                )
        } else {

            activeVideoID =
                videos.first?.id
        }
    }

    final class Coordinator:
        NSObject,
        UIScrollViewDelegate {

        var parent: RIVENPagedFeed

        var videoIDs: [String] = []

        var hostingController:
            UIViewController?

        init(
            _ parent: RIVENPagedFeed
        ) {
            self.parent = parent
        }

        func scrollViewDidEndDecelerating(
            _ scrollView: UIScrollView
        ) {

            updateActiveVideo(
                scrollView
            )
        }

        func scrollViewDidEndDragging(
            _ scrollView: UIScrollView,
            willDecelerate decelerate: Bool
        ) {

            if !decelerate {

                updateActiveVideo(
                    scrollView
                )
            }
        }

        func scrollViewDidEndScrollingAnimation(
            _ scrollView: UIScrollView
        ) {

            updateActiveVideo(
                scrollView
            )
        }

        private func updateActiveVideo(
            _ scrollView: UIScrollView
        ) {

            let pageHeight =
                scrollView.bounds.height

            guard pageHeight > 0 else {
                return
            }

            let rawIndex =
                scrollView.contentOffset.y
                / pageHeight

            let index =
                Int(
                    round(rawIndex)
                )

            guard
                index >= 0,
                index < parent.videos.count
            else {
                return
            }

            let videoID =
                parent.videos[index].id

            if parent.activeVideoID !=
                videoID {

                DispatchQueue.main.async {

                    self.parent.activeVideoID =
                        videoID
                }
            }
        }
    }
}

// MARK: - SwiftUI Page Content

private struct RIVENPagedFeedContent:
    View {

    let videos: [RIVENVideo]

    @Binding var activeVideoID: String?

    var body: some View {

        GeometryReader { geometry in

            VStack(
                spacing: 0
            ) {

                ForEach(videos) { video in

                    VideoPostView(
                        video: video,
                        isActive:
                            activeVideoID == video.id
                    )
                    .frame(
                        width:
                            geometry.size.width,
                        height:
                            geometry.size.height
                    )
                }
            }
        }
    }
}
