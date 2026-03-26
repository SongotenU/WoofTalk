import SwiftUI
import CoreData

struct ModerationAnalyticsView: View {
    @StateObject private var viewModel = ModerationAnalyticsViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    summaryCardsSection
                    
                    if viewModel.isModerator {
                        qualityDistributionSection
                        autoModerationSection
                        reportStatsSection
                        bulkActionsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Moderation Dashboard")
            .onAppear {
                viewModel.loadAnalytics()
            }
        }
    }
    
    @ViewBuilder
    private var summaryCardsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(
                title: "Pending",
                value: "\(viewModel.pendingCount)",
                icon: "clock.fill",
                color: .yellow
            )
            
            StatCard(
                title: "Approved",
                value: "\(viewModel.approvedCount)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            StatCard(
                title: "Rejected",
                value: "\(viewModel.rejectedCount)",
                icon: "xmark.circle.fill",
                color: .red
            )
            
            StatCard(
                title: "Total",
                value: "\(viewModel.totalCount)",
                icon: "doc.text.fill",
                color: .blue
            )
        }
    }
    
    @ViewBuilder
    private var qualityDistributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quality Distribution")
                .font(.headline)
            
            QualityDistributionChart(avgQuality: viewModel.averageQuality)
            
            HStack {
                QualityIndicator(label: "Avg Quality", value: viewModel.averageQuality, maxValue: 1.0)
                QualityIndicator(label: "Min Quality", value: viewModel.minQuality, maxValue: 1.0)
                QualityIndicator(label: "Max Quality", value: viewModel.maxQuality, maxValue: 1.0)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    @ViewBuilder
    private var autoModerationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Auto-Moderation")
                    .font(.headline)
                
                Spacer()
                
                Toggle("Enabled", isOn: $viewModel.autoModerationEnabled)
                    .labelsHidden()
            }
            
            if viewModel.autoModerationEnabled {
                HStack(spacing: 20) {
                    VStack {
                        Text("\(viewModel.autoApprovedCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Auto-Approved")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text("\(viewModel.autoRejectedCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Auto-Rejected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text("\(Int(viewModel.autoApprovalRate * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Approval Rate")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Button(action: {
                    viewModel.runAutoModeration()
                }) {
                    Label("Run Auto-Moderation", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    @ViewBuilder
    private var reportStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Abuse Reports")
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack {
                    Text("\(viewModel.totalReports)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Total Reports")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(viewModel.pendingReports)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Pending")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(viewModel.escalatedReports)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Text("Escalated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            
            if viewModel.totalReports > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("By Type")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(ReportType.allCases, id: \.self) { type in
                        if let count = viewModel.reportsByType[type], count > 0 {
                            HStack {
                                Text(type.displayName)
                                Spacer()
                                Text("\(count)")
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    @ViewBuilder
    private var bulkActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bulk Actions")
                .font(.headline)
            
            HStack(spacing: 12) {
                Button(action: {
                    viewModel.approveAllHighQuality()
                }) {
                    Label("Approve High Quality", systemImage: "checkmark.seal.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    viewModel.rejectAllLowQuality()
                }) {
                    Label("Reject Low Quality", systemImage: "xmark.seal.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
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
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(qualityColor)
                    .frame(width: geometry.size.width * avgQuality)
            }
        }
        .frame(height: 24)
    }
    
    var qualityColor: Color {
        switch avgQuality {
        case 0.8...1.0: return .green
        case 0.5..<0.8: return .yellow
        default: return .red
        }
    }
}

struct QualityIndicator: View {
    let label: String
    let value: Double
    let maxValue: Double
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(String(format: "%.0f%%", value * 100))
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
    }
}

class ModerationAnalyticsViewModel: ObservableObject {
    @Published var pendingCount = 0
    @Published var approvedCount = 0
    @Published var rejectedCount = 0
    @Published var totalCount = 0
    
    @Published var averageQuality: Double = 0
    @Published var minQuality: Double = 0
    @Published var maxQuality: Double = 0
    
    @Published var autoModerationEnabled = true
    @Published var autoApprovedCount = 0
    @Published var autoRejectedCount = 0
    @Published var autoApprovalRate: Double = 0
    
    @Published var totalReports = 0
    @Published var pendingReports = 0
    @Published var escalatedReports = 0
    @Published var reportsByType: [ReportType: Int] = [:]
    
    @Published var isModerator = false
    
    private let autoModerationService = AutoModerationService.shared
    private let abuseReportingManager = AbuseReportingManager.shared
    
    init() {
        isModerator = UserProfileManager.isCurrentUserModerator
    }
    
    func loadAnalytics() {
        loadContributionStats()
        loadAutoModerationStats()
        loadReportStats()
    }
    
    private func loadContributionStats() {
        let fetchRequest: NSFetchRequest<Contribution> = Contribution.fetchRequest()
        
        do {
            let context = PersistenceController.shared.container.viewContext
            let contributions = try context.fetch(fetchRequest)
            
            totalCount = contributions.count
            pendingCount = contributions.filter { $0.displayStatus == .pending }.count
            approvedCount = contributions.filter { $0.displayStatus == .approved }.count
            rejectedCount = contributions.filter { $0.displayStatus == .rejected }.count
            
            if !contributions.isEmpty {
                let qualities = contributions.map { $0.qualityScore }
                averageQuality = qualities.reduce(0, +) / Double(qualities.count)
                minQuality = qualities.min() ?? 0
                maxQuality = qualities.max() ?? 0
            }
        } catch {
            print("Error loading contribution stats: \(error)")
        }
    }
    
    private func loadAutoModerationStats() {
        let stats = autoModerationService.getAutoModerationStats()
        
        autoApprovedCount = stats.autoApprovedCount
        autoRejectedCount = stats.autoRejectedCount
        autoApprovalRate = stats.autoApprovalRate
    }
    
    private func loadReportStats() {
        do {
            let stats = try abuseReportingManager.getReportStatistics()
            
            totalReports = stats.total
            pendingReports = stats.pending
            escalatedReports = stats.escalated
            reportsByType = stats.byType
        } catch {
            print("Error loading report stats: \(error)")
        }
    }
    
    func runAutoModeration() {
        let result = autoModerationService.processPendingContributions()
        loadAnalytics()
    }
    
    func approveAllHighQuality() {
        let threshold = QualityThreshold(
            minQualityScore: 0.85,
            maxQualityScore: 1.0,
            action: .autoApprove,
            reason: "Bulk high quality approval"
        )
        
        let policy = QualityThresholdPolicy.shared
        policy.addThreshold(threshold)
        runAutoModeration()
    }
    
    func rejectAllLowQuality() {
        let threshold = QualityThreshold(
            minQualityScore: 0.0,
            maxQualityScore: 0.3,
            action: .autoReject,
            reason: "Bulk low quality rejection"
        )
        
        let policy = QualityThresholdPolicy.shared
        policy.addThreshold(threshold)
        runAutoModeration()
    }
}
