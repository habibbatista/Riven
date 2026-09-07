import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ChatMessage: Identifiable {
    let id: String
    let text: String
    let senderID: String
}

struct ChatView: View {

    let userID: String
    let username: String

    @State private var message = ""
    @State private var messages: [ChatMessage] = []

    var body: some View {

        VStack {

            ScrollView {

                VStack(spacing: 8) {

                    ForEach(messages) { item in

                        HStack {

                            if item.senderID ==
                                Auth.auth().currentUser?.uid {

                                Spacer()
                            }

                            Text(item.text)
                                .padding(10)
                                .background(
                                    item.senderID ==
                                    Auth.auth().currentUser?.uid
                                    ? Color.blue
                                    : Color.gray.opacity(0.25)
                                )
                                .foregroundColor(
                                    item.senderID ==
                                    Auth.auth().currentUser?.uid
                                    ? .white
                                    : .primary
                                )
                                .cornerRadius(14)

                            if item.senderID !=
                                Auth.auth().currentUser?.uid {

                                Spacer()
                            }
                        }
                    }
                }
                .padding()
            }

            HStack {

                TextField(
                    "Message...",
                    text: $message
                )
                .textFieldStyle(
                    RoundedBorderTextFieldStyle()
                )

                Button {
                    send()
                } label: {

                    Image(
                        systemName:
                            "arrow.up.circle.fill"
                    )
                    .font(
                        .system(size: 28)
                    )
                }
                .disabled(
                    message
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        )
                        .isEmpty
                )
            }
            .padding()
        }
        .navigationBarTitle(
            username,
            displayMode: .inline
        )
        .onAppear {
            listen()
        }
    }

    private func chatID() -> String {

        guard
            let me =
                Auth.auth().currentUser?.uid
        else {
            return ""
        }

        return [
            me,
            userID
        ]
        .sorted()
        .joined(
            separator: "_"
        )
    }

    private func listen() {

        let id = chatID()

        guard !id.isEmpty else {
            return
        }

        Firestore.firestore()
            .collection("chats")
            .document(id)
            .collection("messages")
            .order(
                by: "createdAt"
            )
            .addSnapshotListener {
                snapshot,
                error in

                if let error {

                    print(
                        "RIVEN Chat error:",
                        error.localizedDescription
                    )

                    return
                }

                guard
                    let documents =
                        snapshot?.documents
                else {
                    return
                }

                let loadedMessages =
                    documents.map { document in

                        let data =
                            document.data()

                        return ChatMessage(
                            id:
                                document.documentID,

                            text:
                                data["text"]
                                as? String
                                ?? "",

                            senderID:
                                data["senderID"]
                                as? String
                                ?? ""
                        )
                    }

                DispatchQueue.main.async {

                    messages =
                        loadedMessages
                }
            }
    }

    private func send() {

        let trimmedMessage =
            message
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        guard
            !trimmedMessage.isEmpty,
            let uid =
                Auth.auth().currentUser?.uid
        else {
            return
        }

        let id = chatID()

        guard !id.isEmpty else {
            return
        }

        Firestore.firestore()
            .collection("chats")
            .document(id)
            .collection("messages")
            .addDocument(
                data: [
                    "text":
                        trimmedMessage,

                    "senderID":
                        uid,

                    "createdAt":
                        Timestamp()
                ]
            ) { error in

                if let error {

                    print(
                        "RIVEN Send DM error:",
                        error.localizedDescription
                    )

                    return
                }

                DispatchQueue.main.async {
                    message = ""
                }
            }
    }
}
