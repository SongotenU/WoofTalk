import SwiftUI
import CoreData

struct MessagingView: View {
    @State private var threads: [MessageThread] = []
    @State private var showingNewMessage = false

    var body: some View {
        NavigationView {
            List(threads, id: \.id) { thread in
                NavigationLink(destination: MessageThreadView(thread: thread)) {
                    HStack {
                        Image(systemName: "message.fill")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                        VStack(alignment: .leading) {
                            Text(participantName(for: thread))
                                .font(.headline)
                            if let preview = thread.lastMessagePreview {
                                Text(preview)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        if let date = thread.lastMessageTimestamp {
                            Text(date, style: .time)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Messages")
            .onAppear { loadThreads() }
            .refreshable { loadThreads() }
        }
    }

    private func loadThreads() {
        let fetchRequest: NSFetchRequest<MessageThread> = MessageThread.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastMessageTimestamp", ascending: false)]
        threads = (try? PersistenceController.shared.container.viewContext.fetch(fetchRequest)) ?? []
    }

    private func participantName(for thread: MessageThread) -> String {
        guard let currentUserID = UserProfileManager.currentUser?.id?.uuidString else { return "Unknown" }
        let otherID = (thread.participant1ID == currentUserID) ? thread.participant2ID : thread.participant1ID
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", UUID(uuidString: otherID ?? "") as CVarArg)
        fetchRequest.fetchLimit = 1
        let user = try? PersistenceController.shared.container.viewContext.fetch(fetchRequest).first
        return user?.username ?? "Unknown"
    }
}

struct MessageThreadView: View {
    let thread: MessageThread
    @State private var messages: [Message] = []
    @State private var newMessageText = ""

    var body: some View {
        VStack {
            List(messages, id: \.id) { message in
                HStack {
                    if isCurrentUser(senderID: message.senderID) {
                        Spacer()
                        Text(message.text ?? "")
                            .padding(10)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    } else {
                        Text(message.text ?? "")
                            .padding(10)
                            .background(Color(.systemGray5))
                            .cornerRadius(16)
                        Spacer()
                    }
                }
            }

            Divider()

            HStack {
                TextField("Message...", text: $newMessageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.accentColor)
                }
                .disabled(newMessageText.isEmpty)
            }
            .padding()
        }
        .navigationTitle("Chat")
        .onAppear { loadMessages() }
    }

    private func loadMessages() {
        messages = thread.sortedMessages
    }

    private func sendMessage() {
        guard let user = UserProfileManager.currentUser, !newMessageText.isEmpty else { return }
        _ = thread.addMessage(text: newMessageText, sender: user, context: PersistenceController.shared.container.viewContext)
        newMessageText = ""
        loadMessages()
    }

    private func isCurrentUser(senderID: String?) -> Bool {
        guard let senderID = senderID, let currentUserID = UserProfileManager.currentUser?.id?.uuidString else { return false }
        return senderID == currentUserID
    }
}

#if DEBUG
struct MessagingView_Previews: PreviewProvider {
    static var previews: some View {
        MessagingView()
    }
}
#endif
