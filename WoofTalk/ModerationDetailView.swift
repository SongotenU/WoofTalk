import SwiftUI

/// Detail view for reviewing individual contributions in the moderation queue
struct ModerationDetailView: View {

    @StateObject private var viewModel = ModerationDetailViewModel()

    let contribution: Contribution
    let onApprovalChanged: (ContributionStatus) -> Void

    init(contribution: Contribution, onApprovalChanged: @escaping (ContributionStatus) -> Void) {
        self.contribution = contribution
        self.onApprovalChanged = onApprovalChanged
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Contribution details
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Human Text:").font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
                                Text(contribution.humanText ?? "").font(.body).foregroundColor(.primary)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Animal Translation:").font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
                                Text(contribution.animalText ?? "").font(.body).foregroundColor(.primary)
                            }
                            HStack {
                                Text("Language:").font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
                                Text(contribution.animalLanguage ?? "").font(.caption).foregroundColor(.primary)
                                Spacer()
                                Text("Quality: \(Int(contribution.qualityScore * 100))%").font(.caption).foregroundColor(contribution.qualityScore > 0.7 ? .green : .red)
                            }
                            HStack {
                                Text("Status:").font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
                                Text(contribution.displayStatus.displayText).font(.caption).foregroundColor(.primary)
                                Spacer()
                                Text("Moderation: \(contribution.moderationStatus.displayText)").font(.caption).foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                        // Moderation actions
                        HStack(spacing: 16) {
                            Button(action: { viewModel.approve(contribution: contribution, onApprovalChanged: onApprovalChanged) }) {
                                HStack { Image(systemName: "checkmark.circle.fill"); Text("Approve") }
                                    .frame(maxWidth: .infinity).padding().background(Color.green).foregroundColor(.white).cornerRadius(10)
                            }
                            Button(action: { viewModel.reject(contribution: contribution, onApprovalChanged: onApprovalChanged) }) {
                                HStack { Image(systemName: "xmark.circle.fill"); Text("Reject") }
                                    .frame(maxWidth: .infinity).padding().background(Color.red).foregroundColor(.white).cornerRadius(10)
                            }
                        }

                        if !contribution.validationWarnings.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Validation Warnings").font(.headline).foregroundColor(.orange)
                                ForEach(contribution.validationWarnings, id: \.self) { warning in
                                    HStack(alignment: .top) {
                                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange).font(.caption)
                                        Text(warning).font(.callout).foregroundColor(.primary)
                                        Spacer()
                                    }
                                }
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                        }

                        if !contribution.validationNotes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Moderation Notes").font(.headline)
                                Text(contribution.validationNotes).font(.callout).foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }

                // Bottom toolbar
                HStack {
                    if contribution.displayStatus != .approved {
                        Button("Approve") { viewModel.approve(contribution: contribution, onApprovalChanged: onApprovalChanged) }
                            .frame(maxWidth: .infinity).padding().background(Color.green).foregroundColor(.white).cornerRadius(8)
                    }
                    if contribution.displayStatus != .rejected {
                        Button("Reject") { viewModel.reject(contribution: contribution, onApprovalChanged: onApprovalChanged) }
                            .frame(maxWidth: .infinity).padding().background(Color.red).foregroundColor(.white).cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: -2)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { viewModel.loadContributionDetails(contribution: contribution) }
        }
    }
}
