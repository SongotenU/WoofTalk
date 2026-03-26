// MARK: - UserProfileManager

import Foundation
import CoreData

/// Manages user profiles and moderator role checking
final class UserProfileManager {
    
    // MARK: - Dependencies
    
    private let coreDataContext: NSManagedObjectContext
    
    // MARK: - Static Properties
    
    static let shared = UserProfileManager(coreDataContext: PersistenceController.shared.container.viewContext)
    
    // MARK: - Initialization
    
    init(coreDataContext: NSManagedObjectContext) {
        self.coreDataContext = coreDataContext
    }
    
    // MARK: - Public API
    
    /// Gets the current authenticated user
    /// - Returns: The current user if authenticated, nil otherwise
    static var currentUser: User? {
        // TODO: Implement actual authentication - this is a placeholder
        // For now, return a default user or mock user
        return User.mockUser
    }
    
    /// Checks if the current user is a moderator
    /// - Returns: True if current user is a moderator, false otherwise
    static var isCurrentUserModerator: Bool {
        return currentUser?.isModerator ?? false
    }
    
    /// Gets all moderators
    /// - Returns: Array of moderator users
    func getModerators() -> [User] {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isModerator == YES")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "username", ascending: true)]
        
        do {
            return try coreDataContext.fetch(fetchRequest)
        } catch {
            print("Error fetching moderators: \(error)")
            return []
        }
    }
    
    /// Checks if a user is a moderator by ID
    /// - Parameter userID: The ID of the user to check
    /// - Returns: True if user is a moderator, false otherwise
    func isModerator(userID: UUID) -> Bool {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@ AND isModerator == YES", userID as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try coreDataContext.fetch(fetchRequest)
            return !results.isEmpty
        } catch {
            print("Error checking moderator status: \(error)")
            return false
        }
    }
    
    /// Promotes a user to moderator
    /// - Parameter userID: The ID of the user to promote
    /// - Throws: Error if promotion fails
    func promoteToModerator(userID: UUID) throws {
        guard let user = getUser(withID: userID) else {
            throw UserProfileError.userNotFound
        }
        
        user.isModerator = true
        
        do {
            try coreDataContext.save()
        } catch {
            coreDataContext.rollback()
            throw UserProfileError.saveFailed
        }
    }
    
    /// Demotes a user from moderator
    /// - Parameter userID: The ID of the user to demote
    /// - Throws: Error if demotion fails
    func demoteFromModerator(userID: UUID) throws {
        guard let user = getUser(withID: userID) else {
            throw UserProfileError.userNotFound
        }
        
        user.isModerator = false
        
        do {
            try coreDataContext.save()
        } catch {
            coreDataContext.rollback()
            throw UserProfileError.saveFailed
        }
    }
    
    /// Gets a user by ID
    /// - Parameter userID: The ID of the user to fetch
    /// - Returns: The user if found, nil otherwise
    func getUser(withID userID: UUID) -> User? {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", userID as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try coreDataContext.fetch(fetchRequest)
            return results.first
        } catch {
            print("Error fetching user: \(error)")
            return nil
        }
    }
    
    /// Gets all users sorted by username
    /// - Returns: Array of all users sorted by username
    func getAllUsers() -> [User] {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "username", ascending: true)]
        
        do {
            return try coreDataContext.fetch(fetchRequest)
        } catch {
            print("Error fetching users: \(error)")
            return []
        }
    }
    
    /// Updates user profile
    /// - Parameters:
    ///   - userID: The ID of the user to update
    ///   - username: New username (optional)
    ///   - email: New email (optional)
    ///   - isModerator: New moderator status (optional)
    /// - Throws: Error if update fails
    func updateUserProfile(userID: UUID, username: String? = nil, email: String? = nil, isModerator: Bool? = nil) throws {
        guard let user = getUser(withID: userID) else {
            throw UserProfileError.userNotFound
        }
        
        if let username = username {
            user.username = username
        }
        
        if let email = email {
            user.email = email
        }
        
        if let isModerator = isModerator {
            user.isModerator = isModerator
        }
        
        do {
            try coreDataContext.save()
        } catch {
            coreDataContext.rollback()
            throw UserProfileError.saveFailed
        }
    }
    
    /// Deletes a user
    /// - Parameter userID: The ID of the user to delete
    /// - Throws: Error if deletion fails
    func deleteUser(userID: UUID) throws {
        guard let user = getUser(withID: userID) else {
            throw UserProfileError.userNotFound
        }
        
        coreDataContext.delete(user)
        
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
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .saveFailed:
            return "Failed to save user data"
        case .invalidData:
            return "Invalid user data provided"
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
    
    /// Checks if the user is a moderator
    var isModerator: Bool {
        get { return self.isModerator }
        set { self.isModerator = newValue }
    }
    
    /// Gets the user's contributions
    var contributions: Set<Contribution>? {
        get { return self.contributions }
        set { self.contributions = newValue }
    }
    
    /// Gets the user's contribution count
    var contributionCount: Int {
        return contributions?.count ?? 0
    }
    
    /// Gets the user's approved contribution count
    var approvedContributionCount: Int {
        guard let contributions = contributions else { return 0 }
        return contributions.filter { $0.displayStatus == .approved }.count
    }
    
    /// Gets the user's pending contribution count
    var pendingContributionCount: Int {
        guard let contributions = contributions else { return 0 }
        return contributions.filter { $0.displayStatus == .pending }.count
    }
    
    /// Gets the user's rejected contribution count
    var rejectedContributionCount: Int {
        guard let contributions = contributions else { return 0 }
        return contributions.filter { $0.displayStatus == .rejected }.count
    }
    
    /// Gets the user's duplicate contribution count
    var duplicateContributionCount: Int {
        guard let contributions = contributions else { return 0 }
        return contributions.filter { $0.displayStatus == .duplicate }.count
    }
    
    /// Gets the user's contribution statistics
    var contributionStatistics: (pending: Int, approved: Int, rejected: Int, duplicate: Int) {
        let pending = pendingContributionCount
        let approved = approvedContributionCount
        let rejected = rejectedContributionCount
        let duplicate = duplicateContributionCount
        return (pending, approved, rejected, duplicate)
    }
}