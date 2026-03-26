// MARK: - ModerationView

import SwiftUI
import CoreData

/// View for displaying pending contributions for moderation
struct ModerationView: View {
    
    // MARK: - Dependencies
    
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var moderationViewModel = ModerationViewModel()
    
    // MARK: - Properties
    
    private let contributionManager: ContributionManager
    private let communityPhraseManager: CommunityPhraseManager
    
    // MARK: - Initialization
    
    init(contributionManager: ContributionManager, communityPhraseManager: CommunityPhraseManager) {
        self.contributionManager = contributionManager
        self.communityPhraseManager = communityPhraseManager
    }
    
    // MARK: - View Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                moderationHeader
                
                // Contribution List
                if moderationViewModel.isLoading {
                    ProgressView("Loading contributions...")
                        .padding()
                } else if moderationViewModel.contributions.isEmpty {
                    emptyState
                } else {
                    contributionList
                }
                
                // Bottom Toolbar
                toolbar
            }
            .navigationTitle("Moderation Queue")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                moderationViewModel.loadContributions()
            }
        }
    }
    
    // MARK: - Private View Components
    
    @ViewBuilder
    private var moderationHeader: some View {
        HStack {
            Text("Moderation Queue")
                .font(.headline)
                .fontWeight(.bold)
            
            Spacer()
            
            Button(action: {
                moderationViewModel.loadContributions()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .border(Color(.separator), width: 0.5)
    }
    
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            Text("All contributions reviewed!")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("No pending contributions in the queue.")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var contributionList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(moderationViewModel.contributions) { contribution in
                    ContributionModerationRow(
                        contribution: contribution,
                        onApprove: { [weak self] in
                            self?.handleApprove(contribution: contribution)
                        },
                        onReject: { [weak self] in
                            self?.handleReject(contribution: contribution)
                        }
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    Divider()
                        .padding(.horizontal, -16)
                }
            }
        }
    }
    
    @ViewBuilder
    private var toolbar: some View {
        HStack(spacing: 16) {
            Text("Total: \(moderationViewModel.contributions.count)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button("Clear All") {
                // TODO: Add confirmation for clearing all
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(moderationViewModel.contributions.isEmpty)
        }
        .padding()
        .background(Color(.systemBackground))
        .border(Color(.separator), width: 0.5)
    }
    
    // MARK: - Private Methods
    
    private func handleApprove(contribution: Contribution) {
        // Show confirmation dialog
        moderationViewModel.showConfirmation(
            title: "Approve Contribution",
            message: "Approve this contribution and add it to community phrases?",
            onConfirm: { [weak self] in
                self?.approveContribution(contribution)
            }
        )
    }
    
    private func handleReject(contribution: Contribution) {
        // Show confirmation dialog
        moderationViewModel.showConfirmation(
            title: "Reject Contribution",
            message: "Reject this contribution? This cannot be undone.",
            onConfirm: { [weak self] in
                self?.rejectContribution(contribution)
            }
        )
    }
    
    private func approveContribution(_ contribution: Contribution) {
        do {
            try communityPhraseManager.createCommunityPhrase(from: contribution)
            moderationViewModel.showAlert(title: "Approved", message: "Contribution approved and added to community phrases.")
        } catch {
            moderationViewModel.showAlert(title: "Error", message: error.localizedDescription)
        }
    }
    
    private func rejectContribution(_ contribution: Contribution) {
        do {
            contribution.displayStatus = .rejected
            contribution.validationNotes = "Rejected by moderator"
            try viewContext.save()
            moderationViewModel.showAlert(title: "Rejected", message: "Contribution rejected.")
        } catch {
            moderationViewModel.showAlert(title: "Error", message: error.localizedDescription)
        }
    }
}

// MARK: - ModerationViewModel

class ModerationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var contributions: [Contribution] = []
    @Published var isLoading = false
    @Published var alertTitle: String? = nil
    @Published var alertMessage: String? = nil
    @Published var showingAlert = false
    
    // MARK: - Dependencies
    
    private let contributionManager: ContributionManager
    private let communityPhraseManager: CommunityPhraseManager
    
    // MARK: - Initialization
    
    init(contributionManager: ContributionManager = ContributionManager.shared, communityPhraseManager: CommunityPhraseManager = CommunityPhraseManager.shared) {
        self.contributionManager = contributionManager
        self.communityPhraseManager = communityPhraseManager
    }
    
    // MARK: - Public Methods
    
    func loadContributions() {
        isLoading = true
        
        // Fetch pending contributions excluding current user's own contributions
        let fetchRequest: NSFetchRequest<Contribution> = Contribution.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "status == %@ AND user != %@", ContributionStatus.pending.rawValue, User.currentUser)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        fetchRequest.fetchLimit = 50
        
        do {
            contributions = try PersistenceController.shared.container.viewContext.fetch(fetchRequest)
        } catch {
            print("Error loading contributions: \(error)")
        }
        
        isLoading = false
    }
    
    func showConfirmation(title: String, message: String, onConfirm: @escaping () -> Void) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
        
        // Store the confirm action to execute after user confirms
        confirmationAction = onConfirm
    }
    
    func confirmAction() {
        confirmationAction?()
        confirmationAction = nil
    }
    
    func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
    
    // MARK: - Private Properties
    
    private var confirmationAction: (() -> Void)?
}

// MARK: - ContributionModerationRow

struct ContributionModerationRow: View {
    
    // MARK: - Properties
    
    let contribution: Contribution
    let onApprove: () -> Void
    let onReject: () -> Void
    
    // MARK: - View Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            moderationHeader
            
            // Content
            content
            
            // Actions
            actions
        }
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Private View Components
    
    @ViewBuilder
    private var moderationHeader: some View {
        HStack {
            Text(contribution.humanText ?? "")
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
            
            Spacer()
            
            Text("Quality: \(Int(contribution.qualityScore * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Submitted by: \(contribution.user?.username ?? \"Unknown\")")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(contribution.dogTranslation ?? "")
                .font(.body)
                .foregroundColor(.primary)
            
            if !contribution.validationNotes.isEmpty {
                Text("Notes: \(contribution.validationNotes)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var actions: some View {
        HStack {
            Spacer()
            
            Button("Approve") {
                onApprove()
            }
            .buttonStyle(ModerateButtonStyle(color: .green))
            
            Button("Reject") {
                onReject()
            }
            .buttonStyle(ModerateButtonStyle(color: .red))
        }
    }
}

// MARK: - ModerateButtonStyle

struct ModerateButtonStyle: ButtonStyle {
    
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color)
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}