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

                TextField("Message...", text: $message)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button {
                    send()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                }
            }
            .padding()
        }
        .navigationBarTitle(username, displayMode: .inline)
        .onAppear {
            listen()
        }
    }

    private func chatID() -> String {

        let me = Auth.auth().currentUser?.uid ?? ""

        return [me, userID]
            .sorted()
            .joined(separator: "_")
    }

    private func listen() {

        Firestore.firestore()
            .collection("chats")
            .document(chatID())
            .collection("messages")
            .order(by: "createdAt")
            .addSnapshotListener { snapshot, _ in

                guard let documents = snapshot?.documents else {
                    return
                }

                messages = documents.map {

                    ChatMessage(
                        id: $0.documentID,
                        text: $0.data()["text"] as? String ?? "",
                        senderID: $0.data()["senderID"] as? String ?? ""
                    )
                }
            }
    }

    private func send() {

        guard !message.isEmpty,
              let uid = Auth.auth().currentUser?.uid else {
            return
        }

        Firestore.firestore()
            .collection("chats")
            .document(chatID())
            .collection("messages")
            .addDocument(data: [
                "text": message,
                "senderID": uid,
                "createdAt": Timestamp()
            ])

        message = ""
    }
}
