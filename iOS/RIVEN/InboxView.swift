import SwiftUI
import FirebaseFirestore

struct InboxView: View {

    @State private var conversations: [Conversation] = []

    var body: some View {

        NavigationView {

            List(conversations) { conversation in

                NavigationLink(
                    destination: ChatView(
                        userID: conversation.userID,
                        username: conversation.username
                    )
                ) {

                    HStack {

                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 45))

                        VStack(alignment: .leading) {

                            Text(conversation.username)
                                .font(.headline)

                            Text(conversation.lastMessage)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .navigationBarTitle("Inbox", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct Conversation: Identifiable {
    let id: String
    let userID: String
    let username: String
    let lastMessage: String
}
