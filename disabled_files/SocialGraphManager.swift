// MARK: - SocialGraphManager

import Foundation
import CoreData
import Combine

/// Errors that can occur in social graph operations
enum SocialGraphError: LocalizedError {
    case userNotFound
    case cannotFollowSelf
    case alreadyFollowing
    case notFollowing
    case saveFailed
    case blocked
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .cannotFollowSelf:
            return "You cannot follow yourself"
        case .alreadyFollowing:
            return "Already following this user"
        case .notFollowing:
            return "Not following this user"
        case .saveFailed:
            return "Failed to save social graph changes"
        case .blocked:
            return "Cannot interact with blocked user"
        }
    }
}

/// Follow relationship between two users
final class FollowRelationship: NSObject {
    let followerID: UUID
    let followingID: UUID
    let timestamp: Date
    
    init(followerID: UUID, followingID: UUID, timestamp: Date = Date()) {
        self.followerID = followerID
        self.followingID = followingID
        self.timestamp = timestamp
    }
}

/// Block relationship between two users
final class BlockRelationship: NSObject {
    let blockerID: UUID
    let blockedID: UUID
    let timestamp: Date
    
    init(blockerID: UUID, blockedID: UUID, timestamp: Date = Date()) {
        self.blockerID = blockerID
        self.blockedID = blockedID
        self.timestamp = timestamp
    }
}

/// Manages social graph (followers/following) relationships
final class SocialGraphManager: ObservableObject {
    
    // MARK: - Dependencies
    
    private let coreDataContext: NSManagedObjectContext
    
    // MARK: - Published Properties
    
    @Published private(set) var followerCount: [UUID: Int] = [:]
    @Published private(set) var followingCount: [UUID: Int] = [:]
    
    // MARK: - Static
    
    static let shared = SocialGraphManager(
        coreDataContext: PersistenceController.shared.container.viewContext
    )
    
    // MARK: - Initialization
    
    init(coreDataContext: NSManagedObjectContext) {
        self.coreDataContext = coreDataContext
        loadFollowerCounts()
    }
    
    // MARK: - Follow Operations
    
    /// Follows a user
    /// - Parameters:
    ///   - userToFollow: The user to follow
    ///   - follower: The user who is following (defaults to current user)
    /// - Throws: SocialGraphError if operation fails
    func follow(user userToFollow: User, follower: User? = nil) throws {
        guard let currentUser = follower ?? UserProfileManager.currentUser else {
            throw SocialGraphError.userNotFound
        }
        
        guard let currentUserID = currentUser.id, let targetUserID = userToFollow.id else {
            throw SocialGraphError.userNotFound
        }
        
        guard currentUserID != targetUserID else {
            throw SocialGraphError.cannotFollowSelf
        }
        
        if isBlocked(userID: targetUserID, blockerID: currentUserID) {
            throw SocialGraphError.blocked
        }
        
        if isFollowing(userID: targetUserID, followerID: currentUserID) {
            throw SocialGraphError.alreadyFollowing
        }
        
        let relationship = FollowRelationship(followerID: currentUserID, followingID: targetUserID)
        
        do {
            try saveFollowRelationship(relationship)
            updateFollowingCount(for: currentUserID, delta: 1)
            updateFollowerCount(for: targetUserID, delta: 1)
            
            // Post activity event
            ActivityEventManager.shared.post(.newFollower(targetUser: userToFollow))
            
            // Send notification
            NotificationManager.shared.sendFollowNotification(to: userToFollow, from: currentUser)
        } catch {
            throw SocialGraphError.saveFailed
        }
    }
    
    /// Unfollows a user
    /// - Parameters:
    ///   - userToUnfollow: The user to unfollow
    ///   - follower: The user who is unfollowing (defaults to current user)
    /// - Throws: SocialGraphError if operation fails
    func unfollow(user userToUnfollow: User, follower: User? = nil) throws {
        guard let currentUser = follower ?? UserProfileManager.currentUser else {
            throw SocialGraphError.userNotFound
        }
        
        guard let currentUserID = currentUser.id, let targetUserID = userToUnfollow.id else {
            throw SocialGraphError.userNotFound
        }
        
        guard isFollowing(userID: targetUserID, followerID: currentUserID) else {
            throw SocialGraphError.notFollowing
        }
        
        do {
            try removeFollowRelationship(followerID: currentUserID, followingID: targetUserID)
            updateFollowingCount(for: currentUserID, delta: -1)
            updateFollowerCount(for: targetUserID, delta: -1)
        } catch {
            throw SocialGraphError.saveFailed
        }
    }
    
    // MARK: - Block Operations
    
    /// Blocks a user
    /// - Parameters:
    ///   - userToBlock: The user to block
    ///   - blocker: The user who is blocking (defaults to current user)
    /// - Throws: SocialGraphError if operation fails
    func block(user userToBlock: User, blocker: User? = nil) throws {
        guard let currentUser = blocker ?? UserProfileManager.currentUser else {
            throw SocialGraphError.userNotFound
        }
        
        guard let currentUserID = currentUser.id, let targetUserID = userToBlock.id else {
            throw SocialGraphError.userNotFound
        }
        
        guard currentUserID != targetUserID else {
            throw SocialGraphError.cannotFollowSelf
        }
        
        // If currently following, unfollow first
        if isFollowing(userID: targetUserID, followerID: currentUserID) {
            try? removeFollowRelationship(followerID: currentUserID, followingID: targetUserID)
            updateFollowingCount(for: currentUserID, delta: -1)
            updateFollowerCount(for: targetUserID, delta: -1)
        }
        
        let blockRelationship = BlockRelationship(blockerID: currentUserID, blockedID: targetUserID)
        
        do {
            try saveBlockRelationship(blockRelationship)
        } catch {
            throw SocialGraphError.saveFailed
        }
    }
    
    /// Unblocks a user
    /// - Parameters:
    ///   - userToUnblock: The user to unblock
    ///   - blocker: The user who is unblocking (defaults to current user)
    /// - Throws: SocialGraphError if operation fails
    func unblock(user userToUnblock: User, blocker: User? = nil) throws {
        guard let currentUser = blocker ?? UserProfileManager.currentUser else {
            throw SocialGraphError.userNotFound
        }
        
        guard let currentUserID = currentUser.id, let targetUserID = userToUnblock.id else {
            throw SocialGraphError.userNotFound
        }
        
        do {
            try removeBlockRelationship(blockerID: currentUserID, blockedID: targetUserID)
        } catch {
            throw SocialGraphError.saveFailed
        }
    }
    
    // MARK: - Query Methods
    
    /// Checks if one user is following another
    /// - Parameters:
    ///   - userID: The user being followed
    ///   - followerID: The potential follower
    /// - Returns: True if follower is following userID
    func isFollowing(userID: UUID, followerID: UUID) -> Bool {
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: "FollowRelationship")
        fetchRequest.predicate = NSPredicate(
            format: "followerID == %@ AND followingID == %@",
            followerID as CVarArg,
            userID as CVarArg
        )
        fetchRequest.resultType = .countResultType
        
        do {
            let count = try coreDataContext.count(for: fetchRequest)
            return count > 0
        } catch {
            return false
        }
    }
    
    /// Checks if a user is blocked
    /// - Parameters:
    ///   - userID: The blocked user
    ///   - blockerID: The blocking user
    /// - Returns: True if userID is blocked by blockerID
    func isBlocked(userID: UUID, blockerID: UUID) -> Bool {
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: "BlockRelationship")
        fetchRequest.predicate = NSPredicate(
            format: "blockerID == %@ AND blockedID == %@",
            blockerID as CVarArg,
            userID as CVarArg
        )
        fetchRequest.resultType = .countResultType
        
        do {
            let count = try coreDataContext.count(for: fetchRequest)
            return count > 0
        } catch {
            return false
        }
    }
    
    /// Gets followers for a user
    /// - Parameter user: The user to get followers for
    /// - Returns: Array of follower users
    func getFollowers(for user: User) -> [User] {
        guard let userID = user.id else { return [] }
        
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id IN %@", getFollowerIDs(for: userID) as CVarArg)
        
        do {
            return try coreDataContext.fetch(fetchRequest)
        } catch {
            return []
        }
    }
    
    /// Gets users that a user is following
    /// - Parameter user: The user to get following for
    /// - Returns: Array of users being followed
    func getFollowing(for user: User) -> [User] {
        guard let userID = user.id else { return [] }
        
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id IN %@", getFollowingIDs(for: userID) as CVarArg)
        
        do {
            return try coreDataContext.fetch(fetchRequest)
        } catch {
            return []
        }
    }
    
    /// Gets follower count for a user
    /// - Parameter user: The user to get count for
    /// - Returns: Number of followers
    func getFollowerCount(for user: User) -> Int {
        guard let userID = user.id else { return 0 }
        return followerCount[userID] ?? 0
    }
    
    /// Gets following count for a user
    /// - Parameter user: The user to get count for
    /// - Returns: Number of users being followed
    func getFollowingCount(for user: User) -> Int {
        guard let userID = user.id else { return 0 }
        return followingCount[userID] ?? 0
    }
    
    // MARK: - Private Methods
    
    private func getFollowerIDs(for userID: UUID) -> [UUID] {
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: "FollowRelationship")
        fetchRequest.predicate = NSPredicate(format: "followingID == %@", userID as CVarArg)
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.propertiesToFetch = ["followerID"]
        
        do {
            let results = try coreDataContext.fetch(fetchRequest)
            return results.compactMap { $0["followerID"] as? UUID }
        } catch {
            return []
        }
    }
    
    private func getFollowingIDs(for userID: UUID) -> [UUID] {
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: "FollowRelationship")
        fetchRequest.predicate = NSPredicate(format: "followerID == %@", userID as CVarArg)
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.propertiesToFetch = ["followingID"]
        
        do {
            let results = try coreDataContext.fetch(fetchRequest)
            return results.compactMap { $0["followingID"] as? UUID }
        } catch {
            return []
        }
    }
    
    private func saveFollowRelationship(_ relationship: FollowRelationship) throws {
        guard let userID = UserProfileManager.currentUser?.id else { return }
        
        let followingKey = "following_\(userID.uuidString)"
        if var currentFollowing = UserDefaults.standard.array(forKey: "following_\(userID.uuidString)") as? [String] {
            currentFollowing.append(relationship.followingID.uuidString)
            UserDefaults.standard.set(currentFollowing, forKey: "following_\(userID.uuidString)")
        } else {
            UserDefaults.standard.set([relationship.followingID.uuidString], forKey: "following_\(userID.uuidString)")
        }
    }
    
    private func removeFollowRelationship(followerID: UUID, followingID: UUID) throws {
        if var following = UserDefaults.standard.array(forKey: "following_\(followerID.uuidString)") as? [String] {
            following.removeAll { $0 == followingID.uuidString }
            UserDefaults.standard.set(following, forKey: "following_\(followerID.uuidString)")
        }
    }
    
    private func saveBlockRelationship(_ relationship: BlockRelationship) throws {
        if var blocked = UserDefaults.standard.array(forKey: "blocked_\(relationship.blockerID.uuidString)") as? [String] {
            blocked.append(relationship.blockedID.uuidString)
            UserDefaults.standard.set(blocked, forKey: "blocked_\(relationship.blockerID.uuidString)")
        } else {
            UserDefaults.standard.set([relationship.blockedID.uuidString], forKey: "blocked_\(relationship.blockerID.uuidString)")
        }
    }
    
    private func removeBlockRelationship(blockerID: UUID, blockedID: UUID) throws {
        if var blocked = UserDefaults.standard.array(forKey: "blocked_\(blockerID.uuidString)") as? [String] {
            blocked.removeAll { $0 == blockedID.uuidString }
            UserDefaults.standard.set(blocked, forKey: "blocked_\(blockerID.uuidString)")
        }
    }
    
    private func loadFollowerCounts() {
        // Load counts from UserDefaults or calculate from relationships
        // This is a simplified implementation
    }
    
    private func updateFollowerCount(for userID: UUID, delta: Int) {
        let currentCount = followerCount[userID] ?? 0
        followerCount[userID] = max(0, currentCount + delta)
    }
    
    private func updateFollowingCount(for userID: UUID, delta: Int) {
        let currentCount = followingCount[userID] ?? 0
        followingCount[userID] = max(0, currentCount + delta)
    }
}

// MARK: - Follow User View

struct FollowUserView: View {
    let user: User
    @StateObject private var socialGraph = SocialGraphManager.shared
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private var isFollowing: Bool {
        guard let currentUserID = UserProfileManager.currentUser?.id,
              let targetUserID = user.id else { return false }
        return socialGraph.isFollowing(userID: targetUserID, followerID: currentUserID)
    }
    
    var body: some View {
        Button(action: toggleFollow) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: isFollowing ? "person.fill.checkmark" : "person.fill.badge.plus")
                    Text(isFollowing ? "Following" : "Follow")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isFollowing ? Color(.systemGray5) : Color.accentColor)
            .foregroundColor(isFollowing ? .primary : .white)
            .cornerRadius(20)
        }
        .disabled(isLoading)
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func toggleFollow() {
        isLoading = true
        
        do {
            if isFollowing {
                try socialGraph.unfollow(user: user)
            } else {
                try socialGraph.follow(user: user)
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isLoading = false
    }
}

// MARK: - Preview

#if DEBUG
struct FollowUserView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let user = User(context: context)
        user.id = UUID()
        user.username = "Test User"
        
        return FollowUserView(user: user)
            .padding()
    }
}
#endif
