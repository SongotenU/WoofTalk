// MARK: - NotificationManager

import Foundation
import UserNotifications
import UIKit
import Combine

/// Types of notifications
enum NotificationType: String {
    case newFollower = "new_follower"
    case contributionApproved = "contribution_approved"
    case leaderboardChange = "leaderboard_change"
    case phraseFeatured = "phrase_featured"
}

/// Manages push notifications and local notifications
final class NotificationManager: ObservableObject {
    
    // MARK: - Properties
    
    @Published private(set) var isAuthorized = false
    @Published private(set) var deviceToken: String?
    
    private let center = UNUserNotificationCenter.current()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Singleton
    
    static let shared = NotificationManager()
    
    // MARK: - Initialization
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// Requests notification authorization
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }
    
    /// Checks current authorization status
    func checkAuthorizationStatus() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /// Registers for remote notifications
    func registerForRemoteNotifications() {
        Task { @MainActor in
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    // MARK: - Device Token
    
    /// Handles device token update
    func didUpdateDeviceToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        deviceToken = tokenString
        sendTokenToServer(tokenString)
    }
    
    /// Handles failed registration
    func didFailToRegisterForRemoteNotifications(_ error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    // MARK: - Send Notifications
    
    /// Sends a follow notification to a user
    /// - Parameters:
    ///   - user: The user to notify
    ///   - fromUser: The user who followed
    func sendFollowNotification(to user: User, from fromUser: User) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "New Follower"
        content.body = "\(fromUser.username ?? "Someone") started following you"
        content.sound = .default
        content.userInfo = [
            "type": NotificationType.newFollower.rawValue,
            "followerID": fromUser.id?.uuidString ?? "",
            "userID": user.id?.uuidString ?? ""
        ]
        
        scheduleNotification(content, identifier: "follow_\(UUID().uuidString)")
    }
    
    /// Sends a contribution approved notification
    /// - Parameter user: The user to notify
    func sendContributionApprovedNotification(to user: User) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Contribution Approved!"
        content.body = "Your translation contribution has been approved"
        content.sound = .default
        content.userInfo = [
            "type": NotificationType.contributionApproved.rawValue,
            "userID": user.id?.uuidString ?? ""
        ]
        
        scheduleNotification(content, identifier: "approved_\(UUID().uuidString)")
    }
    
    /// Sends a leaderboard change notification
    /// - Parameters:
    ///   - newRank: The user's new rank
    ///   - improvement: How many positions improved (if positive)
    func sendLeaderboardChangeNotification(newRank: Int, improvement: Int) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        
        if improvement > 0 {
            content.title = "Rank Improved! 🎉"
            content.body = "You've moved up to #\(newRank) on the leaderboard"
        } else {
            content.title = "Leaderboard Update"
            content.body = "Your current rank is #\(newRank)"
        }
        
        content.sound = .default
        content.userInfo = [
            "type": NotificationType.leaderboardChange.rawValue,
            "rank": String(newRank)
        ]
        
        scheduleNotification(content, identifier: "leaderboard_\(UUID().uuidString)")
    }
    
    // MARK: - Badge Management
    
    /// Updates the app badge count
    /// - Parameter count: The badge count
    func updateBadgeCount(_ count: Int) {
        Task { @MainActor in
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
    
    /// Clears the badge count
    func clearBadge() {
        updateBadgeCount(0)
    }
    
    // MARK: - Private Methods
    
    private func scheduleNotification(_ content: UNMutableNotificationContent, identifier: String) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    private func sendTokenToServer(_ token: String) {
        print("[NotificationManager] Sending token to server: \(token)")
    }
}

// MARK: - Activity Feed View

struct ActivityFeedView: View {
    @StateObject private var viewModel = ActivityFeedViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.events.isEmpty {
                    EmptyStateView(
                        icon: "bell.slash",
                        title: "No activity yet",
                        message: "Follow users to see their activity here"
                    )
                } else {
                    List(viewModel.events, id: \.id) { event in
                        ActivityEventRow(event: event)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Activity")
            .refreshable {
                await viewModel.refresh()
            }
        }
        .onAppear {
            viewModel.loadEvents()
        }
    }
}

// MARK: - Activity Event Row

struct ActivityEventRow: View {
    let event: ActivityEvent
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: event.type.icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.15))
                .cornerRadius(8)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(event.type.displayName)
                    .font(.headline)
                
                Text(eventMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(event.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private var iconColor: Color {
        switch event.type {
        case .newFollower: return .blue
        case .contributionApproved: return .green
        case .contributionRejected: return .red
        case .leaderboardChange: return .orange
        case .phraseFeatured: return .yellow
        case .milestoneReached: return .purple
        }
    }
    
    private var eventMessage: String {
        switch event.type {
        case .newFollower:
            if let actorName = event.actorName {
                return "\(actorName) started following you"
            }
            return "Someone started following you"
        case .contributionApproved:
            return "Your translation was approved"
        case .contributionRejected:
            return "Your translation was not approved"
        case .leaderboardChange:
            if let newRank = event.metadata?["new_rank"] {
                return "You moved to rank #\(newRank)"
            }
            return "Your leaderboard position changed"
        case .phraseFeatured:
            return "Your phrase was featured"
        case .milestoneReached:
            if let milestone = event.metadata?["milestone"] {
                return "You reached \(milestone)"
            }
            return "You reached a new milestone"
        }
    }
}

// MARK: - Activity Feed ViewModel

@MainActor
class ActivityFeedViewModel: ObservableObject {
    @Published var events: [ActivityEvent] = []
    @Published var isLoading = false
    
    private let eventManager = ActivityEventManager.shared
    
    func loadEvents() {
        events = eventManager.getRecentEvents(limit: 50)
    }
    
    func refresh() async {
        isLoading = true
        // Simulate network delay for real-time updates
        try? await Task.sleep(nanoseconds: 500_000_000)
        events = eventManager.getRecentEvents(limit: 50)
        isLoading = false
    }
}

// MARK: - Preview

#if DEBUG
struct ActivityFeedView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityFeedView()
    }
}
#endif
