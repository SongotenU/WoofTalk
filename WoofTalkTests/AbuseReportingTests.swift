import XCTest
@testable import WoofTalk

final class AbuseReportingTests: XCTestCase {
    
    var abuseReportingManager: AbuseReportingManager!
    var testContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        let controller = PersistenceController(inMemory: true)
        testContext = controller.container.viewContext
        abuseReportingManager = AbuseReportingManager(coreDataContext: testContext)
    }
    
    override func tearDownWithError() throws {
        abuseReportingManager = nil
        testContext = nil
        try super.tearDownWithError()
    }
    
    func testSubmitSpamReport() throws {
        let report = try abuseReportingManager.submitReport(
            reportedUserId: "reportedUser123",
            reportType: .spam,
            reason: "User posting spam content"
        )
        
        XCTAssertNotNil(report.id, "Report should have an ID")
        XCTAssertEqual(report.reportType, ReportType.spam.rawValue)
        XCTAssertEqual(report.displayStatus, .submitted)
    }
    
    func testSubmitHarassmentReport() throws {
        let report = try abuseReportingManager.submitReport(
            reportedUserId: "harassingUser456",
            reportType: .harassment,
            reason: "User is harassing others"
        )
        
        XCTAssertEqual(report.displayReportType, .harassment)
        XCTAssertEqual(report.reportReason, "User is harassing others")
    }
    
    func testSubmitReportWithContent() throws {
        let report = try abuseReportingManager.submitReport(
            reportedUserId: "badUser789",
            reportedContentId: "content123",
            reportType: .inappropriate,
            reason: "Inappropriate image posted"
        )
        
        XCTAssertEqual(report.reportedContentId, "content123")
    }
    
    func testSubmitReportWithAdditionalDetails() throws {
        let report = try abuseReportingManager.submitReport(
            reportedUserId: "userWithDetails",
            reportType: .misinformation,
            reason: "False information being spread",
            additionalDetails: "See attached screenshots"
        )
        
        XCTAssertEqual(report.additionalDetails, "See attached screenshots")
    }
    
    func testReportPriorityByType() throws {
        let spamReport = try abuseReportingManager.submitReport(
            reportedUserId: "spamUser",
            reportType: .spam,
            reason: "Spam"
        )
        
        let violenceReport = try abuseReportingManager.submitReport(
            reportedUserId: "violentUser",
            reportType: .violence,
            reason: "Violent content"
        )
        
        XCTAssertLessThan(spamReport.priority, violenceReport.priority, "Violence should have higher priority than spam")
    }
    
    func testFetchReportsForUser() throws {
        try abuseReportingManager.submitReport(
            reportedUserId: "targetUser",
            reportType: .spam,
            reason: "Spam 1"
        )
        
        try abuseReportingManager.submitReport(
            reportedUserId: "targetUser",
            reportType: .harassment,
            reason: "Harassment"
        )
        
        try abuseReportingManager.submitReport(
            reportedUserId: "otherUser",
            reportType: .spam,
            reason: "Spam 2"
        )
        
        let reports = try abuseReportingManager.fetchReports(for: "targetUser")
        
        XCTAssertEqual(reports.count, 2, "Should fetch 2 reports for targetUser")
    }
    
    func testFetchPendingReports() throws {
        try abuseReportingManager.submitReport(
            reportedUserId: "user1",
            reportType: .spam,
            reason: "Spam"
        )
        
        let report = try abuseReportingManager.submitReport(
            reportedUserId: "user2",
            reportType: .harassment,
            reason: "Harassment"
        )
        
        try abuseReportingManager.updateReportStatus(
            report: report,
            newStatus: .resolved,
            moderatorId: "moderator1",
            notes: "Resolved"
        )
        
        let pending = try abuseReportingManager.fetchPendingReports()
        
        XCTAssertEqual(pending.count, 1, "Should have 1 pending report")
    }
    
    func testUpdateReportStatusToResolved() throws {
        let report = try abuseReportingManager.submitReport(
            reportedUserId: "userToResolve",
            reportType: .spam,
            reason: "Spam content"
        )
        
        try abuseReportingManager.updateReportStatus(
            report: report,
            newStatus: .resolved,
            moderatorId: "moderator123"
        )
        
        XCTAssertEqual(report.displayStatus, .resolved)
        XCTAssertNotNil(report.resolvedAt)
        XCTAssertEqual(report.resolvedBy, "moderator123")
    }
    
    func testUpdateReportStatusToDismissed() throws {
        let report = try abuseReportingManager.submitReport(
            reportedUserId: "userToDismiss",
            reportType: .spam,
            reason: "False report"
        )
        
        try abuseReportingManager.updateReportStatus(
            report: report,
            newStatus: .dismissed,
            moderatorId: "moderator456",
            notes: "No violation found"
        )
        
        XCTAssertEqual(report.displayStatus, .dismissed)
        XCTAssertEqual(report.moderatorNotes, "No violation found")
    }
    
    func testEscalateReport() throws {
        let report = try abuseReportingManager.submitReport(
            reportedUserId: "seriousUser",
            reportType: .violence,
            reason: "Extremely violent content"
        )
        
        try abuseReportingManager.escalateReport(report, moderatorId: "moderator789")
        
        XCTAssertEqual(report.displayStatus, .escalated)
    }
    
    func testReportStatistics() throws {
        try abuseReportingManager.submitReport(
            reportedUserId: "user1",
            reportType: .spam,
            reason: "Spam"
        )
        
        try abuseReportingManager.submitReport(
            reportedUserId: "user2",
            reportType: .spam,
            reason: "Spam"
        )
        
        let report = try abuseReportingManager.submitReport(
            reportedUserId: "user3",
            reportType: .harassment,
            reason: "Harassment"
        )
        
        try abuseReportingManager.updateReportStatus(
            report: report,
            newStatus: .resolved,
            moderatorId: "mod1"
        )
        
        let stats = try abuseReportingManager.getReportStatistics()
        
        XCTAssertEqual(stats.total, 3)
        XCTAssertEqual(stats.resolved, 1)
        XCTAssertEqual(stats.pending, 2)
        XCTAssertEqual(stats.byType[.spam], 2)
        XCTAssertEqual(stats.byType[.harassment], 1)
    }
    
    func testResolutionRate() throws {
        let report1 = try abuseReportingManager.submitReport(
            reportedUserId: "user1",
            reportType: .spam,
            reason: "Spam"
        )
        
        let report2 = try abuseReportingManager.submitReport(
            reportedUserId: "user2",
            reportType: .spam,
            reason: "Spam"
        )
        
        try abuseReportingManager.updateReportStatus(
            report: report1,
            newStatus: .resolved,
            moderatorId: "mod"
        )
        
        let stats = try abuseReportingManager.getReportStatistics()
        
        XCTAssertEqual(stats.resolutionRate, 0.5, "Resolution rate should be 50%")
    }
    
    func testHasUserBeenReported() throws {
        try abuseReportingManager.submitReport(
            reportedUserId: "checkUser",
            reportType: .spam,
            reason: "Spam"
        )
        
        let hasBeenReported = try abuseReportingManager.hasUserBeenReported(userId: "checkUser")
        let hasNotBeenReported = try abuseReportingManager.hasUserBeenReported(userId: "nonExistentUser")
        
        XCTAssertTrue(hasBeenReported)
        XCTAssertFalse(hasNotBeenReported)
    }
    
    func testReportTypeDisplayName() throws {
        XCTAssertEqual(ReportType.spam.displayName, "Spam")
        XCTAssertEqual(ReportType.harassment.displayName, "Harassment")
        XCTAssertEqual(ReportType.violence.displayName, "Violence")
    }
    
    func testReportStatusDisplayName() throws {
        XCTAssertEqual(ReportStatus.submitted.displayName, "Submitted")
        XCTAssertEqual(ReportStatus.underReview.displayName, "Under Review")
        XCTAssertEqual(ReportStatus.resolved.displayName, "Resolved")
        XCTAssertEqual(ReportStatus.escalated.displayName, "Escalated")
    }
}
