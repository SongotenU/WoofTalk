import SwiftUI
import CoreData

struct ModerationAnalyticsView: View {
    @StateObject private var viewModel = ModerationAnalyticsViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(title: "Pending", value: "\(viewModel.pendingCount)", icon: "clock.fill", color: .yellow)
                        StatCard(title: "Approved", value: "\(viewModel.approvedCount)", icon: "checkmark.circle.fill", color: .green)
                        StatCard(title: "Rejected", value: "\(viewModel.rejectedCount)", icon: "xmark.circle.fill", color: .red)
                        StatCard(title: "Total", value: "\(viewModel.totalCount)", icon: "doc.text.fill", color: .blue)
                    }

                    if viewModel.isModerator {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quality Distribution").font(.headline)
                            QualityDistributionChart(avgQuality: viewModel.averageQuality)
                            HStack {
                                QualityIndicator(label: "Avg", value: viewModel.averageQuality)
                                QualityIndicator(label: "Min", value: viewModel.minQuality)
                                QualityIndicator(label: "Max", value: viewModel.maxQuality)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Auto-Moderation").font(.headline)
                                Spacer()
                                Toggle("Enabled", isOn: $viewModel.autoModerationEnabled).labelsHidden()
                            }
                            if viewModel.autoModerationEnabled {
                                HStack(spacing: 20) {
                                    VStack { Text("\(viewModel.autoApprovedCount)").font(.title2).fontWeight(.bold); Text("Auto-Approved").font(.caption).foregroundColor(.secondary) }
                                    VStack { Text("\(viewModel.autoRejectedCount)").font(.title2).fontWeight(.bold); Text("Auto-Rejected").font(.caption).foregroundColor(.secondary) }
                                    VStack { Text("\(Int(viewModel.autoApprovalRate * 100))%").font(.title2).fontWeight(.bold); Text("Approval Rate").font(.caption).foregroundColor(.secondary) }
                                }
                                .frame(maxWidth: .infinity)
                                Button("Run Auto-Moderation") { viewModel.runAutoModeration() }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Abuse Reports").font(.headline)
                            HStack(spacing: 20) {
                                VStack { Text("\(viewModel.totalReports)").font(.title2).fontWeight(.bold); Text("Total").font(.caption).foregroundColor(.secondary) }
                                VStack { Text("\(viewModel.pendingReports)").font(.title2).fontWeight(.bold); Text("Pending").font(.caption).foregroundColor(.secondary) }
                                VStack { Text("\(viewModel.escalatedReports)").font(.title2).fontWeight(.bold).foregroundColor(.red); Text("Escalated").font(.caption).foregroundColor(.secondary) }
                            }
                            .frame(maxWidth: .infinity)
                            if viewModel.totalReports > 0 {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("By Type").font(.subheadline).foregroundColor(.secondary)
                                    ForEach(ReportType.allCases, id: \.self) { type in
                                        if let count = viewModel.reportsByType[type], count > 0 {
                                            HStack { Text(type.displayName); Spacer(); Text("\(count)").fontWeight(.medium) }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Bulk Actions").font(.headline)
                            HStack(spacing: 12) {
                                Button("Approve High Quality") { viewModel.approveAllHighQuality() }
                                    .frame(maxWidth: .infinity).padding().background(Color.green.opacity(0.1)).foregroundColor(.green).cornerRadius(8)
                                Button("Reject Low Quality") { viewModel.rejectAllLowQuality() }
                                    .frame(maxWidth: .infinity).padding().background(Color.red.opacity(0.1)).foregroundColor(.red).cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                }
                .padding()
            }
            .navigationTitle("Moderation Dashboard")
            .onAppear { viewModel.loadAnalytics() }
        }
    }
}

struct StatCard: View {
    let title, value, icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundColor(color)
            Text(value).font(.title).fontWeight(.bold)
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct QualityDistributionChart: View {
    let avgQuality: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.2))
                RoundedRectangle(cornerRadius: 4).fill(qualityColor).frame(width: geo.size.width * avgQuality)
            }
        }
        .frame(height: 24)
    }

    private var qualityColor: Color {
        switch avgQuality {
        case 0.8...: return .green
        case 0.5..<0.8: return .yellow
        default: return .red
        }
    }
}

struct QualityIndicator: View {
    let label: String
    let value: Double

    var body: some View {
        VStack(spacing: 4) {
            Text(label).font(.caption).foregroundColor(.secondary)
            Text(String(format: "%.0f%%", value * 100)).font(.subheadline).fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
    }
}

class ModerationAnalyticsViewModel: ObservableObject {
    @Published var pendingCount = 0
    @Published var approvedCount = 0
    @Published var rejectedCount = 0
    @Published var totalCount = 0
    @Published var averageQuality = 0.0
    @Published var minQuality = 0.0
    @Published var maxQuality = 0.0
    @Published var autoModerationEnabled = true
    @Published var autoApprovedCount = 0
    @Published var autoRejectedCount = 0
    @Published var autoApprovalRate: Double = 0
    @Published var totalReports = 0
    @Published var pendingReports = 0
    @Published var escalatedReports = 0
    @Published var reportsByType: [ReportType: Int] = [:]
    @Published var isModerator = UserProfileManager.isCurrentUserModerator

    private let autoModerationService = AutoModerationService.shared
    private let abuseReportingManager = AbuseReportingManager.shared

    func loadAnalytics() {
        loadContributionStats()
        let stats = autoModerationService.getAutoModerationStats()
        autoApprovedCount = stats.autoApprovedCount
        autoRejectedCount = stats.autoRejectedCount
        autoApprovalRate = stats.autoApprovalRate
        do {
            let stats = try abuseReportingManager.getReportStatistics()
            totalReports = stats.total
            pendingReports = stats.pending
            escalatedReports = stats.escalated
            reportsByType = stats.byType
        } catch {
            print("Error loading report stats: \(error.localizedDescription)")
        }
    }

    private func loadContributionStats() {
        do {
            let contributions = try PersistenceController.shared.container.viewContext.fetch(Contribution.fetchRequest())
            totalCount = contributions.count
            var pending = 0, approved = 0, rejected = 0
            var qualities: [Double] = []
            for c in contributions {
                switch c.displayStatus {
                case .pending: pending += 1
                case .approved: approved += 1
                case .rejected: rejected += 1
                default: break
                }
                qualities.append(c.qualityScore)
            }
            pendingCount = pending
            approvedCount = approved
            rejectedCount = rejected
            if !qualities.isEmpty {
                averageQuality = qualities.reduce(0, +) / Double(qualities.count)
                minQuality = qualities.min() ?? 0
                maxQuality = qualities.max() ?? 0
            }
        } catch {
            print("Error loading contribution stats: \(error.localizedDescription)")
        }
    }

    func runAutoModeration() { loadAnalytics() }

    func approveAllHighQuality() {
        QualityThresholdPolicy.shared.addThreshold(QualityThreshold(minQualityScore: 0.85, maxQualityScore: 1.0, action: .autoApprove, reason: "Bulk high quality approval"))
        runAutoModeration()
    }

    func rejectAllLowQuality() {
        QualityThresholdPolicy.shared.addThreshold(QualityThreshold(minQualityScore: 0.0, maxQualityScore: 0.3, action: .autoReject, reason: "Bulk low quality rejection"))
        runAutoModeration()
    }
}
