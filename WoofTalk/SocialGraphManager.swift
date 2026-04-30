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
        }
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
    }
    
    // MARK: - Follow Operations

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

        do {
            try saveFollowRelationship(followerID: currentUserID, followingID: targetUserID)
            updateFollowingCount(for: currentUserID, delta: 1)
            updateFollowerCount(for: targetUserID, delta: 1)

            ActivityEventManager.shared.post(.newFollower(targetUser: userToFollow))
            NotificationManager.shared.sendFollowNotification(to: userToFollow, from: currentUser)
        } catch {
            throw SocialGraphError.saveFailed
        }
    }
    
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
    
    // MARK: - Block

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

        if isFollowing(userID: targetUserID, followerID: currentUserID) {
            try? removeFollowRelationship(followerID: currentUserID, followingID: targetUserID)
            updateFollowingCount(for: currentUserID, delta: -1)
            updateFollowerCount(for: targetUserID, delta: -1)
        }

        do {
            try saveBlockRelationship(blockerID: currentUserID, blockedID: targetUserID)
        } catch {
            throw SocialGraphError.saveFailed
        }
    }
    
    // MARK: - Unblock

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
    
    // MARK: - Query

    func isFollowing(userID: UUID, followerID: UUID) -> Bool {
        let key = "following_\(followerID.uuidString)"
        guard let following = UserDefaults.standard.array(forKey: key) as? [String] else { return false }
        return following.contains(userID.uuidString)
    }
    
    func isBlocked(userID: UUID, blockerID: UUID) -> Bool {
        let key = "blocked_\(blockerID.uuidString)"
        guard let blocked = UserDefaults.standard.array(forKey: key) as? [String] else { return false }
        return blocked.contains(userID.uuidString)
    }
    
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
    
    func getFollowerCount(for user: User) -> Int {
        guard let userID = user.id else { return 0 }
        return followerCount[userID] ?? 0
    }
    
    func getFollowingCount(for user: User) -> Int {
        guard let userID = user.id else { return 0 }
        return followingCount[userID] ?? 0
    }
    
    // MARK: - Private

    private func getFollowerIDs(for userID: UUID) -> [UUID] {
        UserDefaults.standard.dictionaryRepresentation()
            .filter { $0.key.hasPrefix("following_") && ($0.value as? [String])?.contains(userID.uuidString) == true }
            .compactMap { UUID(uuidString: $0.key.replacingOccurrences(of: "following_", with: "")) }
    }

    private func getFollowingIDs(for userID: UUID) -> [UUID] {
        let key = "following_\(userID.uuidString)"
        guard let following = UserDefaults.standard.array(forKey: key) as? [String] else { return [] }
        return following.compactMap { UUID(uuidString: $0) }
    }
    
    private func saveFollowRelationship(followerID: UUID, followingID: UUID) throws {
        let key = "following_\(followerID.uuidString)"
        var current = UserDefaults.standard.array(forKey: key) as? [String] ?? []
        current.append(followingID.uuidString)
        UserDefaults.standard.set(current, forKey: key)
    }

    private func removeFollowRelationship(followerID: UUID, followingID: UUID) throws {
        let key = "following_\(followerID.uuidString)"
        guard var current = UserDefaults.standard.array(forKey: key) as? [String] else { return }
        current.removeAll { $0 == followingID.uuidString }
        UserDefaults.standard.set(current, forKey: key)
    }

    private func saveBlockRelationship(blockerID: UUID, blockedID: UUID) throws {
        let key = "blocked_\(blockerID.uuidString)"
        var current = UserDefaults.standard.array(forKey: key) as? [String] ?? []
        current.append(blockedID.uuidString)
        UserDefaults.standard.set(current, forKey: key)
    }

    private func removeBlockRelationship(blockerID: UUID, blockedID: UUID) throws {
        let key = "blocked_\(blockerID.uuidString)"
        guard var current = UserDefaults.standard.array(forKey: key) as? [String] else { return }
        current.removeAll { $0 == blockedID.uuidString }
        UserDefaults.standard.set(current, forKey: key)
    }

    private func updateFollowerCount(for userID: UUID, delta: Int) {
        followerCount[userID] = max(0, (followerCount[userID] ?? 0) + delta)
    }

    private func updateFollowingCount(for userID: UUID, delta: Int) {
        followingCount[userID] = max(0, (followingCount[userID] ?? 0) + delta)
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
