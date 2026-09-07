import SwiftUI
import FirebaseFirestore

struct CommentsView: View {

    let videoID: String

    @State private var comment = ""
    @State private var comments: [String] = []

    var body: some View {

        NavigationView {

            VStack {

                List(comments, id: \.self) { item in
                    Text(item)
                }

                HStack {

                    TextField("Add a comment...", text: $comment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button {
                        sendComment()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                    }
                }
                .padding()
            }
            .navigationBarTitle("Comments", displayMode: .inline)
        }
    }

    private func sendComment() {

        guard !comment.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }

        Firestore.firestore()
            .collection("videos")
            .document(videoID)
            .collection("comments")
            .addDocument(data: [
                "text": comment,
                "createdAt": Timestamp()
            ])

        comments.append(comment)
        comment = ""
    }
}
