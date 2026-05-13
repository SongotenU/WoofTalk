import Foundation
import CoreData

@objc(MessageThread)
public class MessageThread: NSManagedObject, @unchecked Sendable {
    @NSManaged public var id: UUID?
    @NSManaged public var participant1ID: String?
    @NSManaged public var participant2ID: String?
    @NSManaged public var lastMessageTimestamp: Date?
    @NSManaged public var lastMessagePreview: String?
    @NSManaged public var messages: NSSet?

    static func create(participant1: User, participant2: User, context: NSManagedObjectContext) -> MessageThread {
        let thread = MessageThread(context: context)
        thread.id = UUID()
        thread.participant1ID = participant1.id?.uuidString
        thread.participant2ID = participant2.id?.uuidString
        thread.lastMessageTimestamp = Date()
        return thread
    }

    func addMessage(text: String, sender: User, context: NSManagedObjectContext) -> Message? {
        guard let threadID = id, let senderID = sender.id else { return nil }
        let message = Message.create(threadID: threadID, senderID: senderID, text: text, context: context)
        lastMessagePreview = String(text.prefix(50))
        lastMessageTimestamp = Date()
        try? context.save()
        return message
    }

    var sortedMessages: [Message] {
        guard let messages = messages else { return [] }
        return messages.compactMap { $0 as? Message }.sorted { ($0.timestamp ?? Date.distantPast) < ($1.timestamp ?? Date.distantPast) }
    }
}

extension MessageThread {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MessageThread> {
        return NSFetchRequest<MessageThread>(entityName: "MessageThread")
    }
}

// MARK: - Message

@objc(Message)
public class Message: NSManagedObject, @unchecked Sendable {
    @NSManaged public var id: UUID?
    @NSManaged public var threadID: String?
    @NSManaged public var senderID: String?
    @NSManaged public var text: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var isRead: Bool

    static func create(threadID: UUID, senderID: UUID, text: String, context: NSManagedObjectContext) -> Message {
        let message = Message(context: context)
        message.id = UUID()
        message.threadID = threadID.uuidString
        message.senderID = senderID.uuidString
        message.text = text
        message.timestamp = Date()
        message.isRead = false
        return message
    }

    func markAsRead(context: NSManagedObjectContext) throws {
        isRead = true
        try context.save()
    }
}

extension Message {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Message> {
        return NSFetchRequest<Message>(entityName: "Message")
    }
}
