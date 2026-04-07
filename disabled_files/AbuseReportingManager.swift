import Foundation
import CoreData
import SwiftUI

enum ReportType: String, CaseIterable, Codable {
    case spam = "spam"
    case harassment = "harassment"
    case inappropriate = "inappropriate"
    case misinformation = "misinformation"
    case violence = "violence"
    case other = "other"
    
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
    case submitted = "submitted"
    case underReview = "under_review"
    case resolved = "resolved"
    case dismissed = "dismissed"
    case escalated = "escalated"
    
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
        
        do {
            try coreDataContext.save()
            return report
        } catch {
            throw AbuseReportError.saveFailed(error)
        }
    }
    
    func fetchReports(for userId: String) throws -> [ModerationReport] {
        let fetchRequest: NSFetchRequest<ModerationReport> = ModerationReport.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reportedUserId == %@", userId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        return try coreDataContext.fetch(fetchRequest)
    }
    
    func fetchPendingReports() throws -> [ModerationReport] {
        let fetchRequest: NSFetchRequest<ModerationReport> = ModerationReport.fetchRequest()
        let submittedStatus = ReportStatus.submitted.rawValue
        let underReviewStatus = ReportStatus.underReview.rawValue
        fetchRequest.predicate = NSPredicate(
            format: "status == %@ OR status == %@",
            submittedStatus,
            underReviewStatus
        )
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "priority", ascending: false),
            NSSortDescriptor(key: "timestamp", ascending: true)
        ]
        
        return try coreDataContext.fetch(fetchRequest)
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
        
        do {
            try coreDataContext.save()
        } catch {
            throw AbuseReportError.updateFailed(error)
        }
    }
    
    func escalateReport(_ report: ModerationReport, moderatorId: String) throws {
        try updateReportStatus(
            report: report,
            newStatus: .escalated,
            moderatorId: moderatorId,
            notes: "Escalated for urgent review"
        )
    }
    
    func getReportStatistics() throws -> ReportStatistics {
        let fetchRequest: NSFetchRequest<ModerationReport> = ModerationReport.fetchRequest()
        
        let allReports = try coreDataContext.fetch(fetchRequest)
        
        let submittedCount = allReports.filter { $0.displayStatus == .submitted }.count
        let underReviewCount = allReports.filter { $0.displayStatus == .underReview }.count
        let resolvedCount = allReports.filter { $0.displayStatus == .resolved }.count
        let dismissedCount = allReports.filter { $0.displayStatus == .dismissed }.count
        let escalatedCount = allReports.filter { $0.displayStatus == .escalated }.count
        
        var byType: [ReportType: Int] = [:]
        for reportType in ReportType.allCases {
            byType[reportType] = allReports.filter { $0.displayReportType == reportType }.count
        }
        
        return ReportStatistics(
            total: allReports.count,
            pending: submittedCount + underReviewCount,
            resolved: resolvedCount,
            dismissed: dismissedCount,
            escalated: escalatedCount,
            byType: byType
        )
    }
    
    func hasUserBeenReported(userId: String) throws -> Bool {
        let fetchRequest: NSFetchRequest<ModerationReport> = ModerationReport.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reportedUserId == %@", userId)
        fetchRequest.fetchLimit = 1
        
        let count = try coreDataContext.count(for: fetchRequest)
        return count > 0
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
        case .saveFailed(let error):
            return "Failed to save report: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update report: \(error.localizedDescription)"
        case .reportNotFound:
            return "Report not found"
        case .invalidData:
            return "Invalid report data"
        }
    }
}
