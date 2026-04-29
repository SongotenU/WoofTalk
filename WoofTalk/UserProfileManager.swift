import Foundation
import CoreData
import os

/// Manages user profiles and moderator role checking
final class UserProfileManager {
    private let coreDataContext: NSManagedObjectContext
    private let logger = OSLog(subsystem: "com.wooftalk", category: "UserProfile")

    init(coreDataContext: NSManagedObjectContext) {
        self.coreDataContext = coreDataContext
    }

    static var currentUser: User? { User.mockUser }

    static var isCurrentUserModerator: Bool { currentUser?.isModerator ?? false }

    func getModerators() -> [User] {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isModerator == YES")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "username", ascending: true)]
        return (try? coreDataContext.fetch(fetchRequest)) ?? []
    }

    func isModerator(userID: UUID) -> Bool {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@ AND isModerator == YES", userID as CVarArg)
        fetchRequest.fetchLimit = 1
        return (try? coreDataContext.fetch(fetchRequest))?.isEmpty == false
    }
    
    func promoteToModerator(userID: UUID) throws {
        guard let user = getUser(withID: userID) else { throw UserProfileError.userNotFound }
        user.isModerator = true
        try saveContext()
    }

    func demoteFromModerator(userID: UUID) throws {
        guard let user = getUser(withID: userID) else { throw UserProfileError.userNotFound }
        user.isModerator = false
        try saveContext()
    }

    func getUser(withID userID: UUID) -> User? {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", userID as CVarArg)
        fetchRequest.fetchLimit = 1
        do {
            return try coreDataContext.fetch(fetchRequest).first
        } catch {
            os_log("Error fetching user: %{public}@", log: logger, type: .default, error.localizedDescription)
            return nil
        }
    }

    func updateUserProfile(userID: UUID, username: String? = nil, email: String? = nil, isModerator: Bool? = nil) throws {
        guard let user = getUser(withID: userID) else { throw UserProfileError.userNotFound }
        if let username = username { user.username = username }
        if let email = email { user.email = email }
        if let isModerator = isModerator { user.isModerator = isModerator }
        try saveContext()
    }

    func deleteUser(userID: UUID) throws {
        guard let user = getUser(withID: userID) else { throw UserProfileError.userNotFound }
        coreDataContext.delete(user)
        try saveContext()
    }

    private func saveContext() throws {
        do {
            try coreDataContext.save()
        } catch {
            coreDataContext.rollback()
            throw UserProfileError.saveFailed
        }
    }
}

// MARK: - UserProfileError

enum UserProfileError: LocalizedError {
    case userNotFound
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .saveFailed:
            return "Failed to save user data"
        }
    }
}

// MARK: - User Extensions

extension User {
    
    /// Mock user for development/testing
    static var mockUser: User {
        let user = User(context: PersistenceController.shared.container.viewContext)
        user.id = UUID()
        user.username = "Test User"
        user.email = "test@example.com"
        user.isModerator = false
        return user
    }
    
    /// Creates a new user
    /// - Parameters:
    ///   - username: Username for the new user
    ///   - email: Email for the new user
    ///   - isModerator: Whether the user is a moderator
    /// - Returns: The created user
    static func create(username: String, email: String, isModerator: Bool = false) -> User {
        let user = User(context: PersistenceController.shared.container.viewContext)
        user.id = UUID()
        user.username = username
        user.email = email
        user.isModerator = isModerator
        return user
    }
    
    var contributionCount: Int { contributions?.count ?? 0 }

    private func contributionCount(where status: Contribution.DisplayStatus) -> Int {
        contributions?.filter { $0.displayStatus == status }.count ?? 0
    }

    var approvedContributionCount: Int { contributionCount(where: .approved) }
    var pendingContributionCount: Int { contributionCount(where: .pending) }
    var rejectedContributionCount: Int { contributionCount(where: .rejected) }
    var duplicateContributionCount: Int { contributionCount(where: .duplicate) }

    var contributionStatistics: (pending: Int, approved: Int, rejected: Int, duplicate: Int) {
        (pendingContributionCount, approvedContributionCount, rejectedContributionCount, duplicateContributionCount)
    }
}