// MARK: - UserProfileView+Social

import SwiftUI

extension UserProfileView {
    struct SocialStatsSection: View {
        let user: User
        @StateObject private var socialGraph = SocialGraphManager.shared

        var body: some View {
            HStack(spacing: 0) {
                SocialStatButton(count: socialGraph.getFollowerCount(for: user), label: "Followers")
                Divider().frame(height: 30)
                SocialStatButton(count: socialGraph.getFollowingCount(for: user), label: "Following")
                Divider().frame(height: 30)
                SocialStatButton(count: user.contributionCount, label: "Contributions")
            }
            .padding(.vertical, 8)
        }
    }

    struct SocialStatButton: View {
        let count: Int
        let label: String

        var body: some View {
            VStack(spacing: 4) {
                Text("\(count)").font(.title2.bold())
                Text(label).font(.caption).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - User Profile Social View

struct UserProfileSocialView: View {
    let user: User
    @StateObject private var socialGraph = SocialGraphManager.shared
    @State private var showingFollowers = false
    @State private var showingFollowing = false

    private var isFollowing: Bool {
        guard let currentUserID = UserProfileManager.currentUser?.id, let targetUserID = user.id else { return false }
        return socialGraph.isFollowing(userID: targetUserID, followerID: currentUserID)
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(String(user.username?.prefix(1) ?? "?").uppercased())
                            .font(.title.bold())
                            .foregroundColor(.secondary)
                    )

                Text(user.username ?? "Anonymous").font(.title2.bold())

                if user.isModerator {
                    Text("Moderator")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.15))
                        .foregroundColor(.purple)
                        .cornerRadius(4)
                }
            }

            UserProfileView.SocialStatsSection(user: user)

            if user.id != UserProfileManager.currentUser?.id {
                FollowUserView(user: user)
            }
        }
        .padding()
    }
}

// MARK: - Followers/Following List Views

struct FollowersListView: View {
    let user: User
    @StateObject private var socialGraph = SocialGraphManager.shared
    @State private var followers: [User] = []

    var body: some View {
        List(followers, id: \.id) { follower in
            UserListRow(user: follower)
        }
        .navigationTitle("Followers")
        .onAppear { followers = socialGraph.getFollowers(for: user) }
    }
}

struct FollowingListView: View {
    let user: User
    @StateObject private var socialGraph = SocialGraphManager.shared
    @State private var following: [User] = []

    var body: some View {
        List(following, id: \.id) { followedUser in
            UserListRow(user: followedUser)
        }
        .navigationTitle("Following")
        .onAppear { following = socialGraph.getFollowing(for: user) }
    }
}

struct UserListRow: View {
    let user: User

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(.systemGray4))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(user.username?.prefix(1) ?? "?").uppercased())
                        .font(.headline)
                        .foregroundColor(.secondary)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(user.username ?? "Anonymous").font(.headline)
                if user.isModerator {
                    Text("Moderator").font(.caption).foregroundColor(.purple)
                }
            }

            Spacer()

            FollowUserView(user: user)
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
struct UserProfileSocialView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let user = User(context: context)
        user.id = UUID()
        user.username = "Test User"
        return NavigationView { UserProfileSocialView(user: user) }
    }
}
#endif
