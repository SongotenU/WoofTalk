import Foundation
import CoreData

enum ReportType: String, CaseIterable, Codable {
    case spam, harassment, inappropriate, misinformation, violence, other

    var displayName: String {
        switch self {
        case .spam: return "Spam"
        case .harassment: return "Harassment"
        case .inappropriate: return "Inappropriate Content"
        case .misinformation: return "Misinformation"
        case .violence: return "Violence"
        case .other: return "Other"
        }
    }

    var severity: Int {
        switch self {
        case .spam: return 1
        case .inappropriate: return 2
        case .misinformation: return 3
        case .harassment: return 4
        case .violence: return 5
        case .other: return 1
        }
    }
}

enum ReportStatus: String, CaseIterable, Codable {
    case submitted, underReview, resolved, dismissed, escalated

    var displayName: String {
        switch self {
        case .submitted: return "Submitted"
        case .underReview: return "Under Review"
        case .resolved: return "Resolved"
        case .dismissed: return "Dismissed"
        case .escalated: return "Escalated"
        }
    }
}

@objc(ModerationReport)
public class ModerationReport: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var reporterId: String?
    @NSManaged public var reportedUserId: String?
    @NSManaged public var reportedContentId: String?
    @NSManaged public var reportType: String?
    @NSManaged public var reportReason: String?
    @NSManaged public var additionalDetails: String?
    @NSManaged public var status: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var resolvedAt: Date?
    @NSManaged public var resolvedBy: String?
    @NSManaged public var moderatorNotes: String?
    @NSManaged public var priority: Int16

    var displayStatus: ReportStatus {
        get { ReportStatus(rawValue: status ?? "submitted") ?? .submitted }
        set { status = newValue.rawValue }
    }

    var displayReportType: ReportType {
        get { ReportType(rawValue: reportType ?? "other") ?? .other }
        set { reportType = newValue.rawValue }
    }
}

extension ModerationReport {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ModerationReport> {
        return NSFetchRequest<ModerationReport>(entityName: "ModerationReport")
    }
}

final class AbuseReportingManager {
    static let shared = AbuseReportingManager(coreDataContext: PersistenceController.shared.container.viewContext)

    private let coreDataContext: NSManagedObjectContext

    init(coreDataContext: NSManagedObjectContext) {
        self.coreDataContext = coreDataContext
    }

    func submitReport(
        reportedUserId: String,
        reportedContentId: String? = nil,
        reportType: ReportType,
        reason: String,
        additionalDetails: String? = nil
    ) throws -> ModerationReport {
        let report = ModerationReport(context: coreDataContext)
        report.id = UUID()
        report.reporterId = UserProfileManager.currentUser?.id?.uuidString
        report.reportedUserId = reportedUserId
        report.reportedContentId = reportedContentId
        report.reportType = reportType.rawValue
        report.reportReason = reason
        report.additionalDetails = additionalDetails
        report.status = ReportStatus.submitted.rawValue
        report.timestamp = Date()
        report.priority = Int16(reportType.severity)

        try coreDataContext.save()
        return report
    }

    func fetchReports(for userId: String) throws -> [ModerationReport] {
        let request: NSFetchRequest<ModerationReport> = ModerationReport.fetchRequest()
        request.predicate = NSPredicate(format: "reportedUserId == %@", userId)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        return try coreDataContext.fetch(request)
    }

    func fetchPendingReports() throws -> [ModerationReport] {
        let request: NSFetchRequest<ModerationReport> = ModerationReport.fetchRequest()
        request.predicate = NSPredicate(format: "status IN %@", [ReportStatus.submitted.rawValue, ReportStatus.underReview.rawValue])
        request.sortDescriptors = [
            NSSortDescriptor(key: "priority", ascending: false),
            NSSortDescriptor(key: "timestamp", ascending: true)
        ]
        return try coreDataContext.fetch(request)
    }

    func updateReportStatus(
        report: ModerationReport,
        newStatus: ReportStatus,
        moderatorId: String,
        notes: String? = nil
    ) throws {
        report.status = newStatus.rawValue
        report.moderatorNotes = notes

        if newStatus == .resolved || newStatus == .dismissed {
            report.resolvedAt = Date()
            report.resolvedBy = moderatorId
        }

        try coreDataContext.save()
    }

    func escalateReport(_ report: ModerationReport, moderatorId: String) throws {
        try updateReportStatus(report: report, newStatus: .escalated, moderatorId: moderatorId, notes: "Escalated for urgent review")
    }

    func getReportStatistics() throws -> ReportStatistics {
        let allReports = try coreDataContext.fetch(ModerationReport.fetchRequest())

        var submitted = 0, underReview = 0, resolved = 0, dismissed = 0, escalated = 0
        var byType: [ReportType: Int] = [:]

        for report in allReports {
            switch report.displayStatus {
            case .submitted: submitted += 1
            case .underReview: underReview += 1
            case .resolved: resolved += 1
            case .dismissed: dismissed += 1
            case .escalated: escalated += 1
            }
            byType[report.displayReportType, default: 0] += 1
        }

        return ReportStatistics(
            total: allReports.count,
            pending: submitted + underReview,
            resolved: resolved,
            dismissed: dismissed,
            escalated: escalated,
            byType: byType
        )
    }

    func hasUserBeenReported(userId: String) throws -> Bool {
        let request: NSFetchRequest<ModerationReport> = ModerationReport.fetchRequest()
        request.predicate = NSPredicate(format: "reportedUserId == %@", userId)
        request.fetchLimit = 1
        return try coreDataContext.count(for: request) > 0
    }
}

struct ReportStatistics {
    let total: Int
    let pending: Int
    let resolved: Int
    let dismissed: Int
    let escalated: Int
    let byType: [ReportType: Int]

    var resolutionRate: Double {
        guard total > 0 else { return 0 }
        return Double(resolved + dismissed) / Double(total)
    }
}

enum AbuseReportError: LocalizedError {
    case saveFailed(Error)
    case updateFailed(Error)
    case reportNotFound
    case invalidData

    var errorDescription: String? {
        switch self {
        case .saveFailed(let error): return "Failed to save report: \(error.localizedDescription)"
        case .updateFailed(let error): return "Failed to update report: \(error.localizedDescription)"
        case .reportNotFound: return "Report not found"
        case .invalidData: return "Invalid report data"
        }
    }
}
