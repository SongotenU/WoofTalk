// MARK: - ModerationDetailView

import SwiftUI
import CoreData

/// Detail view for reviewing individual contributions in the moderation queue
struct ModerationDetailView: View {
    
    // MARK: - Dependencies
    
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = ModerationDetailViewModel()
    
    // MARK: - Properties
    
    let contribution: Contribution
    let onApprovalChanged: (ContributionStatus) -> Void
    
    // MARK: - Initialization
    
    init(contribution: Contribution, onApprovalChanged: @escaping (ContributionStatus) -> Void) {
        self.contribution = contribution
        self.onApprovalChanged = onApprovalChanged
    }
    
    // MARK: - View Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        contributionDetails
                        moderationActions
                        
                        if !contribution.validationWarnings.isEmpty {
                            validationWarnings
                        }
                        
                        if !contribution.validationNotes.isEmpty {
                            moderationNotes
                        }
                    }
                    .padding()
                }
                
                bottomToolbar
            }
            .navigationTitle("Review Contribution")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.loadContributionDetails(contribution: contribution)
            }
        }
    }
    
    // MARK: - Private View Components
    
    @ViewBuilder
    private var contributionDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Human Text
            VStack(alignment: .leading, spacing: 4) {
                Text("Human Text:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text(contribution.humanText ?? "")
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            // Dog Translation
            VStack(alignment: .leading, spacing: 4) {
                Text("Dog Translation:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text(contribution.dogTranslation ?? "")
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            // Metadata
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Quality Score: \(Int(contribution.qualityScore * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Submitted: \(viewModel.formattedTimestamp)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let submitter = contribution.user {
                    HStack {
                        Text("Submitted by: \(submitter.username ?? \"Unknown\")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if viewModel.isCurrentUserModerator {
                            Text("You are a moderator")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
            }
        }
        .padding(.bottom, 16)
    }
    
    @ViewBuilder
    private var moderationActions: some View {
        VStack(spacing: 12) {
            // Status Header
            HStack {
                Text("Moderation Actions:")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text(viewModel.statusText)
                    .font(.caption)
                    .foregroundColor(viewModel.statusColor)
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                // Approve Button
                Button(action: {
                    approveContribution()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Approve")
                    }
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .cornerRadius(8)
                }
                .disabled(viewModel.isProcessing)
                
                // Reject Button
                Button(action: {
                    rejectContribution()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Reject")
                    }
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.red)
                    .cornerRadius(8)
                }
                .disabled(viewModel.isProcessing)
            }
            
            // Processing Indicator
            if viewModel.isProcessing {
                ProgressView("Processing...")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var validationWarnings: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Validation Warnings:")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Image(systemName: "exclamation.triangle.fill")
                    .foregroundColor(.yellow)
            }
            
            // Warning List
            VStack(alignment: .leading, spacing: 8) {
                ForEach(contribution.validationWarnings, id: \.self) { warning in
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        
                        Text(warning)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding()
        .background(Color(.systemYellow).opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var moderationNotes: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Moderation Notes:")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
            }
            
            // Notes Content
            Text(contribution.validationNotes)
                .font(.body)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemBlue).opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBlue).opacity(0.05))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var bottomToolbar: some View {
        HStack(spacing: 16) {
            Spacer()
            
            Button("Back to Queue") {
                // TODO: Navigate back to moderation queue
            }
            .buttonStyle(PlainButtonStyle())
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .border(Color(.separator), width: 0.5)
    }
    
    // MARK: - Private Methods
    
    private func approveContribution() {
        viewModel.approveContribution(contribution: contribution) { [weak self] success in
            if success {
                self?.onApprovalChanged(.approved)
                self?.viewModel.showAlert(title: "Approved", message: "Contribution approved and added to community phrases.")
            } else {
                self?.viewModel.showAlert(title: "Error", message: "Failed to approve contribution.")
            }
        }
    }
    
    private func rejectContribution() {
        viewModel.rejectContribution(contribution: contribution) { [weak self] success in
            if success {
                self?.onApprovalChanged(.rejected)
                self?.viewModel.showAlert(title: "Rejected", message: "Contribution rejected.")
            } else {
                self?.viewModel.showAlert(title: "Error", message: "Failed to reject contribution.")
            }
        }
    }
}

// MARK: - ModerationDetailViewModel

class ModerationDetailViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var formattedTimestamp: String = ""
    @Published var statusText: String = "Pending"
    @Published var statusColor: Color = .yellow
    @Published var isCurrentUserModerator = false
    @Published var isProcessing = false
    
    // MARK: - Dependencies
    
    private let contributionManager: ContributionManager
    private let communityPhraseManager: CommunityPhraseManager
    
    // MARK: - Initialization
    
    init(contributionManager: ContributionManager = ContributionManager.shared, communityPhraseManager: CommunityPhraseManager = CommunityPhraseManager.shared) {
        self.contributionManager = contributionManager
        self.communityPhraseManager = communityPhraseManager
    }
    
    // MARK: - Public Methods
    
    func loadContributionDetails(contribution: Contribution) {
        // Format timestamp
        if let timestamp = contribution.timestamp {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            formattedTimestamp = formatter.string(from: timestamp)
        }
        
        // Update status display
        updateStatusDisplay()
        
        // Check if current user is moderator
        isCurrentUserModerator = User.currentUser?.isModerator ?? false
    }
    
    func approveContribution(contribution: Contribution, completion: @escaping (Bool) -> Void) {
        isProcessing = true
        
        // Create community phrase
        do {
            try communityPhraseManager.createCommunityPhrase(from: contribution)
            completion(true)
        } catch {
            print("Error approving contribution: \(error)")
            completion(false)
        }
        
        isProcessing = false
    }
    
    func rejectContribution(contribution: Contribution, completion: @escaping (Bool) -> Void) {
        isProcessing = true
        
        // Update contribution status to rejected
        contribution.displayStatus = .rejected
        contribution.validationNotes = "Rejected by moderator"
        
        do {
            try contribution.managedObjectContext?.save()
            completion(true)
        } catch {
            print("Error rejecting contribution: \(error)")
            completion(false)
        }
        
        isProcessing = false
    }
    
    func showAlert(title: String, message: String) {
        // TODO: Implement alert presentation
        print("Alert: \(title) - \(message)")
    }
    
    // MARK: - Private Methods
    
    private func updateStatusDisplay() {
        guard let status = ContributionStatus(rawValue: contribution.status ?? "pending") else {
            statusText = "Unknown"
            statusColor = .gray
            return
        }
        
        switch status {
        case .pending:
            statusText = "Pending Review"
            statusColor = .yellow
        case .approved:
            statusText = "Approved"
            statusColor = .green
        case .rejected:
            statusText = "Rejected"
            statusColor = .red
        case .processed:
            statusText = "Processed"
            statusColor = .blue
        case .duplicate:
            statusText = "Duplicate"
            statusColor = .orange
        }
    }
}