// MARK: - SocialSharingManager

import Foundation
import UIKit
import SwiftUI

/// Errors that can occur during social sharing
enum SocialSharingError: LocalizedError {
    case shareFailed
    case invalidContent
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .shareFailed:
            return "Failed to share content"
        case .invalidContent:
            return "Content is invalid or cannot be shared"
        case .cancelled:
            return "Share was cancelled"
        }
    }
}

/// Content to be shared
struct ShareContent {
    let humanText: String
    let dogTranslation: String
    let qualityScore: Double?
    let contributorName: String?
    
    var shareText: String {
        var text = "\"\(humanText)\" → \"\(dogTranslation)\""
        
        if let contributor = contributorName {
            text += "\n\nContributed by \(contributor)"
        }
        
        text += "\n\nTranslated with WoofTalk 🐕"
        return text
    }
    
    var attributionText: String {
        return "Translation by WoofTalk"
    }
}

/// Manages social sharing functionality
final class SocialSharingManager {
    
    // MARK: - Singleton
    
    static let shared = SocialSharingManager()
    
    // MARK: - Properties
    
    private let appName = "WoofTalk"
    private let appStoreURL = "https://apps.apple.com/app/wooftalk"
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public API
    
    /// Creates share content from a community phrase
    /// - Parameter phrase: The community phrase to share
    /// - Returns: ShareContent with phrase data
    func createShareContent(from phrase: CommunityPhrase) -> ShareContent {
        return ShareContent(
            humanText: phrase.humanText ?? "",
            dogTranslation: phrase.dogTranslation ?? "",
            qualityScore: phrase.qualityScore,
            contributorName: phrase.submitter?.username
        )
    }
    
    /// Creates share content from a translation
    /// - Parameters:
    ///   - humanText: The human text that was translated
    ///   - dogTranslation: The dog translation
    /// - Returns: ShareContent with translation data
    func createShareContent(humanText: String, dogTranslation: String) -> ShareContent {
        return ShareContent(
            humanText: humanText,
            dogTranslation: dogTranslation,
            qualityScore: nil,
            contributorName: nil
        )
    }
    
    /// Presents the share sheet for a community phrase
    /// - Parameters:
    ///   - phrase: The community phrase to share
    ///   - viewController: The view controller to present the share sheet from
    ///   - completion: Completion handler called after sharing
    func share(phrase: CommunityPhrase, from viewController: UIViewController, completion: @escaping (Result<Void, SocialSharingError>) -> Void) {
        let content = createShareContent(from: phrase)
        presentShareSheet(with: content, from: viewController, completion: completion)
    }
    
    /// Presents the share sheet for custom content
    /// - Parameters:
    ///   - content: The content to share
    ///   - viewController: The view controller to present the share sheet from
    ///   - completion: Completion handler called after sharing
    func share(content: ShareContent, from viewController: UIViewController, completion: @escaping (Result<Void, SocialSharingError>) -> Void) {
        presentShareSheet(with: content, from: viewController, completion: completion)
    }
    
    /// Presents the share sheet for translation
    /// - Parameters:
    ///   - humanText: The human text
    ///   - dogTranslation: The dog translation
    ///   - viewController: The view controller to present the share sheet from
    ///   - completion: Completion handler called after sharing
    func shareTranslation(humanText: String, dogTranslation: String, from viewController: UIViewController, completion: @escaping (Result<Void, SocialSharingError>) -> Void) {
        let content = createShareContent(humanText: humanText, dogTranslation: dogTranslation)
        presentShareSheet(with: content, from: viewController, completion: completion)
    }
    
    // MARK: - Private Methods
    
    private func presentShareSheet(with content: ShareContent, from viewController: UIViewController, completion: @escaping (Result<Void, SocialSharingError>) -> Void) {
        guard !content.humanText.isEmpty, !content.dogTranslation.isEmpty else {
            completion(.failure(.invalidContent))
            return
        }
        
        var activityItems: [Any] = [content.shareText]
        
        // Add app URL if available
        if let url = URL(string: appStoreURL) {
            activityItems.append(url)
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        // Set excluded activity types
        activityViewController.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .openInIBooks
        ]
        
        // Completion handler
        activityViewController.completionWithItemsHandler = { activityType, completed, items, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Share error: \(error.localizedDescription)")
                    completion(.failure(.shareFailed))
                    return
                }
                
                if completed {
                    // Track share event for analytics
                    self.trackShareEvent(activityType: activityType, content: content)
                    completion(.success(()))
                } else {
                    completion(.failure(.cancelled))
                }
            }
        }
        
        // Present the share sheet
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        viewController.present(activityViewController, animated: true)
    }
    
    private func trackShareEvent(activityType: UIActivity.ActivityType?, content: ShareContent) {
        // Runtime signal for share events - for observability
        let eventData: [String: Any] = [
            "event": "translation_shared",
            "timestamp": Date().timeIntervalSince1970,
            "content_length": content.humanText.count,
            "activity_type": activityType?.rawValue ?? "unknown",
            "has_contributor": content.contributorName != nil
        ]
        
        print("[SocialSharing] Share event: \(eventData)")
    }
}

// MARK: - Share Translation View (SwiftUI)

struct ShareTranslationView: View {
    let phrase: CommunityPhrase
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Preview card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Share this translation")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(phrase.humanText ?? "")
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Image(systemName: "arrow.down")
                            .foregroundColor(.secondary)
                        
                        Text(phrase.dogTranslation ?? "")
                            .font(.body.bold())
                            .foregroundColor(.accentColor)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    if let contributor = phrase.submitter?.username {
                        Text("Contributed by \(contributor)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                Spacer()
                
                // Share button
                Button(action: shareTranslation) {
                    Label("Share Translation", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.top)
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func shareTranslation() {
        // Get the root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        // Find the topmost presented view controller
        var topVC = rootViewController
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        
        SocialSharingManager.shared.share(phrase: phrase, from: topVC) { result in
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                print("Share failed: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ShareTranslationView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let phrase = CommunityPhrase(context: context)
        phrase.humanText = "Hello"
        phrase.dogTranslation = "Woof woof!"
        phrase.qualityScore = 0.9
        
        return ShareTranslationView(phrase: phrase)
    }
}
#endif
