import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct InboxView: View {

    @State private var conversations: [Conversation] = []
    @State private var isLoading = true

    private let db = Firestore.firestore()

    var body: some View {

        NavigationView {

            Group {

                if isLoading {

                    ProgressView()

                } else if conversations.isEmpty {

                    VStack(spacing: 10) {

                        Image(systemName: "message")
                            .font(.system(size: 34))
                            .foregroundColor(.secondary)

                        Text("No messages yet")
                            .font(.headline)

                        Text("Your conversations will appear here.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 30)

                } else {

                    List(conversations) { conversation in

                        NavigationLink(
                            destination: ChatView(
                                userID: conversation.userID,
                                username: conversation.username
                            )
                        ) {

                            HStack(spacing: 12) {

                                Image(
                                    systemName:
                                        "person.circle.fill"
                                )
                                .font(
                                    .system(size: 45)
                                )
                                .foregroundColor(
                                    .secondary
                                )

                                VStack(
                                    alignment: .leading,
                                    spacing: 4
                                ) {

                                    Text(
                                        conversation.username
                                    )
                                    .font(.headline)

                                    Text(
                                        conversation.lastMessage
                                    )
                                    .foregroundColor(
                                        .secondary
                                    )
                                    .lineLimit(1)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationBarTitle(
                "Inbox",
                displayMode: .inline
            )
        }
        .navigationViewStyle(
            StackNavigationViewStyle()
        )
        .onAppear {
            loadConversations()
        }
    }

    private func loadConversations() {

        guard
            let currentUID =
                Auth.auth().currentUser?.uid
        else {

            conversations = []
            isLoading = false
            return
        }

        isLoading = true

        db.collection("chats")
            .whereField(
                "participants",
                arrayContains: currentUID
            )
            .getDocuments { snapshot, error in

                if let error {

                    print(
                        "RIVEN Inbox error:",
                        error.localizedDescription
                    )

                    DispatchQueue.main.async {
                        conversations = []
                        isLoading = false
                    }

                    return
                }

                guard
                    let documents =
                        snapshot?.documents
                else {

                    DispatchQueue.main.async {
                        conversations = []
                        isLoading = false
                    }

                    return
                }

                if documents.isEmpty {

                    DispatchQueue.main.async {
                        conversations = []
                        isLoading = false
                    }

                    return
                }

                let group =
                    DispatchGroup()

                var loadedConversations:
                    [Conversation] = []

                let lock =
                    NSLock()

                for document in documents {

                    let data =
                        document.data()

                    guard
                        let participants =
                            data["participants"]
                            as? [String]
                    else {
                        continue
                    }

                    guard
                        let otherUID =
                            participants.first(
                                where: {
                                    $0 != currentUID
                                }
                            )
                    else {
                        continue
                    }

                    group.enter()

                    db.collection("users")
                        .document(otherUID)
                        .getDocument {
                            userSnapshot,
                            _
                            in

                            let userData =
                                userSnapshot?.data()

                            let username =
                                userData?["name"]
                                as? String
                                ?? userData?["username"]
                                as? String
                                ?? userData?["handle"]
                                as? String
                                ?? "RIVEN User"

                            let messagesRef =
                                self.db
                                    .collection("chats")
                                    .document(
                                        document.documentID
                                    )
                                    .collection("messages")

                            messagesRef
                                .order(
                                    by: "createdAt",
                                    descending: true
                                )
                                .limit(to: 1)
                                .getDocuments {
                                    messageSnapshot,
                                    _
                                    in

                                    let lastMessage =
                                        messageSnapshot?
                                            .documents
                                            .first?
                                            .data()["text"]
                                            as? String
                                        ?? ""

                                    let conversation =
                                        Conversation(
                                            id:
                                                document.documentID,
                                            userID:
                                                otherUID,
                                            username:
                                                username,
                                            lastMessage:
                                                lastMessage
                                        )

                                    lock.lock()

                                    loadedConversations
                                        .append(
                                            conversation
                                        )

                                    lock.unlock()

                                    group.leave()
                                }
                        }
                }

                group.notify(
                    queue: .main
                ) {

                    conversations =
                        loadedConversations

                    isLoading = false
                }
            }
    }
}

struct Conversation: Identifiable {

    let id: String
    let userID: String
    let username: String
    let lastMessage: String
}
