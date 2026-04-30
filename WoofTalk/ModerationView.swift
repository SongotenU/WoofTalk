import SwiftUI

/// View for displaying pending contributions for moderation
struct ModerationView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var moderationViewModel = ModerationViewModel()

    private let communityPhraseManager: CommunityPhraseManager

    init(communityPhraseManager: CommunityPhraseManager) {
        self.communityPhraseManager = communityPhraseManager
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Moderation Queue").font(.headline).fontWeight(.bold)
                    Spacer()
                    Button(action: { moderationViewModel.loadContributions() }) {
                        Image(systemName: "arrow.clockwise").font(.caption)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
                .background(Color(.systemGray6))
                .border(Color(.separator), width: 0.5)

                if moderationViewModel.isLoading {
                    ProgressView("Loading contributions...").padding()
                } else if moderationViewModel.contributions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle").font(.system(size: 50)).foregroundColor(.green)
                        Text("No contributions pending moderation").font(.headline)
                        Text("New contributions will appear here for review").font(.caption).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List {
                        ForEach(moderationViewModel.contributions, id: \.self) { contribution in
                            NavigationLink(destination: ModerationDetailView(contribution: contribution) { status in
                                moderationViewModel.updateStatus(contribution, status: status)
                            }) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(contribution.humanText ?? "").font(.headline).lineLimit(1)
                                        Spacer()
                                        Text(contribution.animalLanguage ?? "").font(.caption).foregroundColor(.secondary)
                                    }
                                    HStack {
                                        Text("Quality: \(Int(contribution.qualityScore * 100))%").font(.caption)
                                            .foregroundColor(contribution.qualityScore > 0.7 ? .green : .red)
                                        Spacer()
                                        Text(contribution.displayStatus.displayText).font(.caption).foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }

                // Toolbar
                HStack {
                    Text("\(moderationViewModel.contributions.count) contributions").font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Button("Refresh") { moderationViewModel.loadContributions() }
                        .padding(.horizontal, 16).padding(.vertical, 8).background(Color.blue).foregroundColor(.white).cornerRadius(8)
                }
                .padding()
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: -2)
            }
            .navigationTitle("Moderation Queue")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { moderationViewModel.loadContributions() }
        }
    }
}
