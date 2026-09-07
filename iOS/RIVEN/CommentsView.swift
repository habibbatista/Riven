import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct RIVENComment: Identifiable {

    let id: String

    let uid: String
    let name: String
    let handle: String
    let pfp: String

    let text: String

    var likesBy: [String]
    var dislikesBy: [String]

    var replies: [RIVENReply]

    let createdAt: Timestamp?
    let imageURL: String?
}

struct RIVENReply: Identifiable {

    let id: String

    let uid: String
    let name: String
    let handle: String
    let pfp: String

    let text: String

    var likesBy: [String]
    var dislikesBy: [String]

    let createdAt: Timestamp?
}

struct CommentsView: View {

    let videoID: String

    @Environment(\.dismiss)
    private var dismiss

    @State private var comment = ""
    @State private var comments: [RIVENComment] = []

    @State private var isLoading = true
    @State private var isSending = false

    private let db = Firestore.firestore()

    var body: some View {

        NavigationView {

            VStack(spacing: 0) {

                if isLoading {

                    ProgressView()
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity
                        )

                } else if comments.isEmpty {

                    VStack(spacing: 10) {

                        Image(systemName: "bubble.right")
                            .font(
                                .system(
                                    size: 34
                                )
                            )
                            .foregroundColor(
                                .secondary
                            )

                        Text("No comments yet")
                            .font(.headline)

                        Text("Be the first to comment.")
                            .font(.subheadline)
                            .foregroundColor(
                                .secondary
                            )
                    }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )

                } else {

                    ScrollView {

                        LazyVStack(
                            alignment: .leading,
                            spacing: 20
                        ) {

                            ForEach(
                                $comments
                            ) { $item in

                                commentRow(
                                    item: $item
                                )
                            }
                        }
                        .padding(
                            .horizontal,
                            16
                        )
                        .padding(
                            .vertical,
                            18
                        )
                    }
                }

                Divider()

                composer
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(
                    placement: .navigationBarLeading
                ) {

                    Button {
                        dismiss()
                    } label: {

                        Image(
                            systemName: "xmark"
                        )
                    }
                }
            }
            .task {
                loadComments()
            }
        }
    }

    // MARK: - Comment Row

    private func commentRow(
        item: Binding<RIVENComment>
    ) -> some View {

        let currentUserID =
            Auth.auth().currentUser?.uid

        let isLiked =
            currentUserID.map {
                item.wrappedValue.likesBy.contains($0)
            }
            ?? false

        let isDisliked =
            currentUserID.map {
                item.wrappedValue.dislikesBy.contains($0)
            }
            ?? false

        return VStack(
            alignment: .leading,
            spacing: 10
        ) {

            HStack(
                alignment: .top,
                spacing: 10
            ) {

                avatar(
                    url: item.wrappedValue.pfp
                )

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text(
                        "@\(item.wrappedValue.handle.isEmpty
                          ? "user"
                          : item.wrappedValue.handle)"
                    )
                    .font(
                        .subheadline.weight(
                            .semibold
                        )
                    )

                    Text(
                        item.wrappedValue.text
                    )
                    .font(.body)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )

                    if let imageURL =
                        item.wrappedValue.imageURL,
                       !imageURL.isEmpty,
                       let url = URL(
                            string: imageURL
                       ) {

                        AsyncImage(url: url) { image in

                            image
                                .resizable()
                                .scaledToFit()

                        } placeholder: {

                            ProgressView()
                        }
                        .frame(
                            maxWidth: 240,
                            maxHeight: 240
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 12
                            )
                        )
                    }

                    HStack(spacing: 18) {

                        Button {

                            toggleCommentReaction(
                                item.wrappedValue.id,
                                type: "like"
                            )

                        } label: {

                            Label(
                                "\(item.wrappedValue.likesBy.count)",
                                systemImage:
                                    isLiked
                                    ? "hand.thumbsup.fill"
                                    : "hand.thumbsup"
                            )
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(
                            isLiked
                            ? .blue
                            : .secondary
                        )

                        Button {

                            toggleCommentReaction(
                                item.wrappedValue.id,
                                type: "dislike"
                            )

                        } label: {

                            Label(
                                "\(item.wrappedValue.dislikesBy.count)",
                                systemImage:
                                    isDisliked
                                    ? "hand.thumbsdown.fill"
                                    : "hand.thumbsdown"
                            )
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(
                            isDisliked
                            ? .red
                            : .secondary
                        )

                        Button {

                            // Reply UI can be expanded here
                            // without changing the Firestore
                            // reply structure.

                        } label: {

                            Text("Reply")
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(
                            .secondary
                        )
                    }
                    .font(.caption)
                }

                Spacer()
            }

            if !item.wrappedValue.replies.isEmpty {

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    ForEach(
                        item.wrappedValue.replies
                    ) { reply in

                        replyRow(
                            reply
                        )
                        .padding(
                            .leading,
                            48
                        )
                    }
                }
            }
        }
    }

    // MARK: - Reply

    private func replyRow(
        _ reply: RIVENReply
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 8
        ) {

            avatar(
                url: reply.pfp
            )
            .frame(
                width: 30,
                height: 30
            )

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text(
                    "@\(reply.handle.isEmpty
                      ? "user"
                      : reply.handle)"
                )
                .font(
                    .caption.weight(
                        .semibold
                    )
                )

                Text(reply.text)
                    .font(.subheadline)
            }
        }
    }

    // MARK: - Avatar

    private func avatar(
        url: String
    ) -> some View {

        Group {

            if
                !url.isEmpty,
                let imageURL = URL(
                    string: url
                ) {

                AsyncImage(
                    url: imageURL
                ) { phase in

                    switch phase {

                    case .success(let image):

                        image
                            .resizable()
                            .scaledToFill()

                    case .failure:

                        placeholderAvatar

                    case .empty:

                        ProgressView()

                    @unknown default:

                        placeholderAvatar
                    }
                }

            } else {

                placeholderAvatar
            }
        }
        .frame(
            width: 38,
            height: 38
        )
        .clipShape(Circle())
    }

    private var placeholderAvatar: some View {

        ZStack {

            Circle()
                .fill(
                    Color.secondary.opacity(
                        0.2
                    )
                )

            Image(
                systemName: "person.fill"
            )
            .foregroundColor(
                .secondary
            )
        }
    }

    // MARK: - Composer

    private var composer: some View {

        HStack(spacing: 10) {

            TextField(
                "Add a comment...",
                text: $comment,
                axis: .vertical
            )
            .textFieldStyle(
                .roundedBorder
            )
            .lineLimit(
                1...4
            )

            Button {

                sendComment()

            } label: {

                Image(
                    systemName:
                        "arrow.up.circle.fill"
                )
                .font(
                    .system(
                        size: 29
                    )
                )
            }
            .disabled(
                comment
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty
                || isSending
            )
        }
        .padding()
        .background(
            Color(uiColor:
                .systemBackground
            )
        )
    }

    // MARK: - Load Comments

    private func loadComments() {

        isLoading = true

        db.collection("videos")
            .document(videoID)
            .collection("comments")
            .order(
                by: "createdAt",
                descending: false
            )
            .getDocuments { snapshot, error in

                DispatchQueue.main.async {

                    isLoading = false

                    guard
                        let documents =
                            snapshot?.documents
                    else {
                        comments = []
                        return
                    }

                    comments =
                        documents.map {
                            document in

                            let data =
                                document.data()

                            return parseComment(
                                id: document.documentID,
                                data: data
                            )
                        }
                }
            }
    }

    // MARK: - Parse Web RIVEN Comment

    private func parseComment(
        id: String,
        data: [String: Any]
    ) -> RIVENComment {

        let rawReplies =
            data["replies"] as? [[String: Any]]
            ?? []

        let replies =
            rawReplies.enumerated().map {
                index,
                data -> RIVENReply in

                RIVENReply(
                    id:
                        "\(data["uid"] as? String ?? "")_\(data["createdAt"] as? Int ?? index)",
                    uid:
                        data["uid"] as? String
                        ?? "",
                    name:
                        data["name"] as? String
                        ?? "User",
                    handle:
                        data["handle"] as? String
                        ?? "user",
                    pfp:
                        data["pfp"] as? String
                        ?? "",
                    text:
                        data["text"] as? String
                        ?? "",
                    likesBy:
                        data["likesBy"] as? [String]
                        ?? [],
                    dislikesBy:
                        data["dislikesBy"] as? [String]
                        ?? [],
                    createdAt:
                        timestamp(
                            from: data["createdAt"]
                        )
                )
            }

        return RIVENComment(
            id: id,
            uid:
                data["uid"] as? String
                ?? "",
            name:
                data["name"] as? String
                ?? "User",
            handle:
                data["handle"] as? String
                ?? "user",
            pfp:
                data["pfp"] as? String
                ?? "",
            text:
                data["text"] as? String
                ?? "",
            likesBy:
                data["likesBy"] as? [String]
                ?? [],
            dislikesBy:
                data["dislikesBy"] as? [String]
                ?? [],
            replies: replies,
            createdAt:
                timestamp(
                    from: data["createdAt"]
                ),
            imageURL:
                data["imageUrl"] as? String
        )
    }

    private func timestamp(
        from value: Any?
    ) -> Timestamp? {

        if let timestamp =
            value as? Timestamp {

            return timestamp
        }

        if let milliseconds =
            value as? Int {

            return Timestamp(
                date:
                    Date(
                        timeIntervalSince1970:
                            Double(
                                milliseconds
                            ) / 1000
                    )
            )
        }

        return nil
    }

    // MARK: - Send Comment

    private func sendComment() {

        let text =
            comment.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !text.isEmpty else {
            return
        }

        guard
            let user =
                Auth.auth().currentUser
        else {
            return
        }

        isSending = true

        db.collection("users")
            .document(user.uid)
            .getDocument { snapshot, _ in

                let profile =
                    snapshot?.data()

                let name =
                    profile?["name"] as? String
                    ?? user.displayName
                    ?? "User"

                let handle =
                    profile?["handle"] as? String
                    ?? "user"

                let pfp =
                    profile?["pfp"] as? String
                    ?? user.photoURL?
                        .absoluteString
                    ?? ""

                let commentData: [String: Any] = [

                    "uid": user.uid,

                    "name": name,

                    "handle": handle,

                    "pfp": pfp,

                    "text": text,

                    "likesBy": [],

                    "dislikesBy": [],

                    "replies": [],

                    "createdAt":
                        FieldValue.serverTimestamp()
                ]

                db.collection("videos")
                    .document(videoID)
                    .collection("comments")
                    .addDocument(
                        data: commentData
                    ) { error in

                        DispatchQueue.main.async {

                            isSending = false

                            guard error == nil
                            else {
                                return
                            }

                            comment = ""

                            db.collection("videos")
                                .document(videoID)
                                .updateData(
                                    [
                                        "commentsCount":
                                            FieldValue
                                                .increment(
                                                    Int64(1)
                                                )
                                    ]
                                )

                            loadComments()
                        }
                    }
            }
    }

    // MARK: - Comment Reactions

    private func toggleCommentReaction(
        _ commentID: String,
        type: String
    ) {

        guard
            let uid =
                Auth.auth()
                    .currentUser?
                    .uid
        else {
            return
        }

        guard
            let index =
                comments.firstIndex(
                    where: {
                        $0.id == commentID
                    }
                )
        else {
            return
        }

        let currentlyLiked =
            comments[index]
                .likesBy
                .contains(uid)

        let currentlyDisliked =
            comments[index]
                .dislikesBy
                .contains(uid)

        if type == "like" {

            if currentlyLiked {

                comments[index]
                    .likesBy
                    .removeAll {
                        $0 == uid
                    }

            } else {

                comments[index]
                    .likesBy
                    .append(uid)

                comments[index]
                    .dislikesBy
                    .removeAll {
                        $0 == uid
                    }
            }

        } else {

            if currentlyDisliked {

                comments[index]
                    .dislikesBy
                    .removeAll {
                        $0 == uid
                    }

            } else {

                comments[index]
                    .dislikesBy
                    .append(uid)

                comments[index]
                    .likesBy
                    .removeAll {
                        $0 == uid
                    }
            }
        }

        let updates: [String: Any] = [

            "likesBy":
                comments[index]
                    .likesBy,

            "dislikesBy":
                comments[index]
                    .dislikesBy
        ]

        db.collection("videos")
            .document(videoID)
            .collection("comments")
            .document(commentID)
            .updateData(updates)
    }
}
