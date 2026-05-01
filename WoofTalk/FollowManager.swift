import Foundation
import CoreData
import SwiftUI

/// Manages follow relationships with UI support
final class FollowManager: ObservableObject {
    static let shared = FollowManager(context: PersistenceController.shared.container.viewContext)
    private let context: NSManagedObjectContext

    @Published var followers: [User] = []
    @Published var following: [User] = []

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func follow(user: User, follower: User? = nil) throws {
        let currentUser = follower ?? UserProfileManager.currentUser
        guard let followerID = currentUser?.id, let targetID = user.id, followerID != targetID else { return }
        SocialGraphManager.shared.follow(user: user, follower: currentUser)
        refresh(for: user)
    }

    func unfollow(user: User, follower: User? = nil) throws {
        let currentUser = follower ?? UserProfileManager.currentUser
        SocialGraphManager.shared.unfollow(user: user, follower: currentUser)
        refresh(for: user)
    }

    func isFollowing(user: User) -> Bool {
        guard let currentUserID = UserProfileManager.currentUser?.id, let targetID = user.id else { return false }
        return SocialGraphManager.shared.isFollowing(userID: targetID, followerID: currentUserID)
    }

    func refresh(for user: User) {
        followers = SocialGraphManager.shared.getFollowers(for: user)
        following = SocialGraphManager.shared.getFollowing(for: user)
    }
}

// MARK: - Follow Button View

struct FollowButton: View {
    let user: User
    @StateObject private var manager = FollowManager.shared
    @State private var isLoading = false

    var body: some View {
        Button(action: toggleFollow) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Image(systemName: manager.isFollowing(user: user) ? "person.fill.checkmark" : "person.fill.badge.plus")
                    Text(manager.isFollowing(user: user) ? "Following" : "Follow")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(manager.isFollowing(user: user) ? Color(.systemGray5) : Color.accentColor)
            .foregroundColor(manager.isFollowing(user: user) ? .primary : .white)
            .cornerRadius(20)
        }
        .disabled(isLoading)
    }

    private func toggleFollow() {
        isLoading = true
        do {
            if manager.isFollowing(user: user) {
                try manager.unfollow(user: user)
            } else {
                try manager.follow(user: user)
            }
        } catch { }
        isLoading = false
    }
}
