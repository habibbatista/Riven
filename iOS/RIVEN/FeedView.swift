import SwiftUI
import AVKit
import AVFoundation
import FirebaseAuth
import FirebaseFirestore
import UIKit

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

                    RIVENPagedFeed(
                        videos: videos,
                        activeVideoID: $activeVideoID,
                        pageSize: geometry.size
                    )
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .background(Color.black)
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
                        documents.compactMap {
                            document in

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


// MARK: - One-Video-Per-Swipe Feed

struct RIVENPagedFeed: UIViewRepresentable {

    let videos: [RIVENVideo]

    @Binding var activeVideoID: String?

    let pageSize: CGSize

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(
        context: Context
    ) -> UIScrollView {

        let scrollView = UIScrollView()

        scrollView.backgroundColor = .black

        scrollView.isPagingEnabled = true
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false

        scrollView.bounces = true
        scrollView.decelerationRate = .fast

        // Correct UIKit property name.
        scrollView.isDirectionalLockEnabled = true

        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero

        scrollView.delegate = context.coordinator

        let hostedView =
            context.coordinator.hostingController.view!

        hostedView.backgroundColor = .black
        hostedView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(hostedView)

        context.coordinator.hostedView = hostedView

        NSLayoutConstraint.activate([

            hostedView.leadingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.leadingAnchor
            ),

            hostedView.trailingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.trailingAnchor
            ),

            hostedView.topAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.topAnchor
            ),

            hostedView.bottomAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.bottomAnchor
            ),

            hostedView.widthAnchor.constraint(
                equalTo: scrollView.frameLayoutGuide.widthAnchor
            )
        ])

        return scrollView
    }

    func updateUIView(
        _ scrollView: UIScrollView,
        context: Context
    ) {

        context.coordinator.parent = self

        context.coordinator.hostingController.rootView =
            RIVENPagedFeedContent(
                videos: videos,
                activeVideoID: $activeVideoID,
                pageSize: pageSize
            )

        let expectedHeight =
            pageSize.height * CGFloat(videos.count)

        if scrollView.contentSize.height != expectedHeight {

            scrollView.contentSize = CGSize(
                width: pageSize.width,
                height: expectedHeight
            )
        }

        guard
            let activeVideoID,
            let index = videos.firstIndex(
                where: { $0.id == activeVideoID }
            )
        else {
            return
        }

        let targetY =
            CGFloat(index) * pageSize.height

        let currentY =
            scrollView.contentOffset.y

        // Only reposition when we're not already essentially
        // on the requested page. This prevents SwiftUI updates
        // from fighting the user's swipe.
        if abs(currentY - targetY) > 2,
           !context.coordinator.isUserDragging {

            scrollView.setContentOffset(
                CGPoint(
                    x: 0,
                    y: targetY
                ),
                animated: false
            )
        }
    }

    final class Coordinator:
        NSObject,
        UIScrollViewDelegate {

        var parent: RIVENPagedFeed

        let hostingController:
            UIHostingController<RIVENPagedFeedContent>

        weak var hostedView: UIView?

        var isUserDragging = false

        init(
            _ parent: RIVENPagedFeed
        ) {

            self.parent = parent

            let initialContent =
                RIVENPagedFeedContent(
                    videos: parent.videos,
                    activeVideoID:
                        parent.$activeVideoID,
                    pageSize:
                        parent.pageSize
                )

            self.hostingController =
                UIHostingController(
                    rootView: initialContent
                )

            super.init()
        }

        // MARK: Dragging

        func scrollViewWillBeginDragging(
            _ scrollView: UIScrollView
        ) {

            isUserDragging = true
        }

        func scrollViewWillEndDragging(
            _ scrollView: UIScrollView,
            withVelocity velocity: CGPoint,
            targetContentOffset:
                UnsafeMutablePointer<CGPoint>
        ) {

            let pageHeight =
                max(scrollView.bounds.height, 1)

            let currentPage =
                Int(
                    round(
                        scrollView.contentOffset.y
                        / pageHeight
                    )
                )

            var targetPage = currentPage

            // Only ever allow ONE page per swipe.
            if velocity.y > 0.1 {

                targetPage = currentPage + 1

            } else if velocity.y < -0.1 {

                targetPage = currentPage - 1

            } else {

                targetPage =
                    Int(
                        round(
                            targetContentOffset.pointee.y
                            / pageHeight
                        )
                    )

                // Even without meaningful velocity,
                // clamp the movement to one page.
                if targetPage > currentPage + 1 {
                    targetPage = currentPage + 1
                }

                if targetPage < currentPage - 1 {
                    targetPage = currentPage - 1
                }
            }

            targetPage =
                max(
                    0,
                    min(
                        targetPage,
                        parent.videos.count - 1
                    )
                )

            targetContentOffset.pointee =
                CGPoint(
                    x: 0,
                    y: CGFloat(targetPage) * pageHeight
                )
        }

        // MARK: Paging Finished

        func scrollViewDidEndDragging(
            _ scrollView: UIScrollView,
            willDecelerate decelerate: Bool
        ) {

            if !decelerate {
                updateActivePage(scrollView)
                isUserDragging = false
            }
        }

        func scrollViewDidEndDecelerating(
            _ scrollView: UIScrollView
        ) {

            updateActivePage(scrollView)
            isUserDragging = false
        }

        func scrollViewDidEndScrollingAnimation(
            _ scrollView: UIScrollView
        ) {

            updateActivePage(scrollView)
        }

        // MARK: Active Video

        private func updateActivePage(
            _ scrollView: UIScrollView
        ) {

            guard !parent.videos.isEmpty else {
                return
            }

            let pageHeight =
                max(scrollView.bounds.height, 1)

            var index =
                Int(
                    round(
                        scrollView.contentOffset.y
                        / pageHeight
                    )
                )

            index =
                max(
                    0,
                    min(
                        index,
                        parent.videos.count - 1
                    )
                )

            let newID =
                parent.videos[index].id

            if parent.activeVideoID != newID {

                DispatchQueue.main.async {
                    self.parent.activeVideoID = newID
                }
            }
        }
    }
}


// MARK: - Hosted SwiftUI Feed Content

struct RIVENPagedFeedContent: View {

    let videos: [RIVENVideo]

    @Binding var activeVideoID: String?

    let pageSize: CGSize

    var body: some View {

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
                    width: pageSize.width,
                    height: pageSize.height
                )
                .background(Color.black)
                .clipped()
            }
        }
        .frame(
            width: pageSize.width,
            height:
                pageSize.height
                * CGFloat(videos.count),
            alignment: .top
        )
    }
}
