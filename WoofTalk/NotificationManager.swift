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

    @Published private(set) var isAuthorized = false
    @Published private(set) var deviceToken: String?

    private let center = UNUserNotificationCenter.current()
    private var cancellables = Set<AnyCancellable>()

    static let shared = NotificationManager()

    private init() {
        checkAuthorizationStatus()
    }

    /// Requests notification authorization
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run { self.isAuthorized = granted }
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
        Task {
            if await requestAuthorization() {
                await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
            }
        }
    }

    /// Handles device token registration
    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        self.deviceToken = token
        // Send token to backend
        AuthManager.shared.updateDeviceToken(token)
    }

    /// Schedules a local notification
    func scheduleLocalNotification(title: String, body: String, type: NotificationType, userInfo: [String: Any]? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo ?? [:]
        content.categoryIdentifier = type.rawValue

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request) { error in
            if let error = error { print("Error scheduling notification: \(error)") }
        }
    }

    /// Handles receiving a notification
    func handleReceivedNotification(_ userInfo: [AnyHashable: Any]) {
        guard let typeString = userInfo["type"] as? String, let type = NotificationType(rawValue: typeString) else { return }
        let title = userInfo["title"] as? String ?? "WoofTalk"
        let body = userInfo["body"] as? String ?? ""
        scheduleLocalNotification(title: title, body: body, type: type, userInfo: userInfo)
        switch type {
        case .newFollower: handleNewFollower(userInfo)
        case .contributionApproved: handleContributionApproved(userInfo)
        case .leaderboardChange: handleLeaderboardChange(userInfo)
        case .phraseFeatured: handlePhraseFeatured(userInfo)
        }
    }

    private func handleNewFollower(_ userInfo: [AnyHashable: Any]) { print("New follower: \(userInfo)") }
    private func handleContributionApproved(_ userInfo: [AnyHashable: Any]) { print("Contribution approved: \(userInfo)") }
    private func handleLeaderboardChange(_ userInfo: [AnyHashable: Any]) { print("Leaderboard change: \(userInfo)") }
    private func handlePhraseFeatured(_ userInfo: [AnyHashable: Any]) { print("Phrase featured: \(userInfo)") }
}
