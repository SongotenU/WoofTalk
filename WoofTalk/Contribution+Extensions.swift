enum ContributionStatus: String, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    case processed = "processed"
    case duplicate = "duplicate"
    case submitted = "submitted"
    case validated = "validated"
}

enum ContributionError: LocalizedError {
    case invalidStatusTransition
    case saveFailed
    case invalidData
    case validationFailed(errors: [ValidationError])
    case networkUnavailable
    case coreDataSaveFailed

    var errorDescription: String? {
        switch self {
        case .invalidStatusTransition:
            return "Invalid status transition"
        case .saveFailed:
            return "Failed to save contribution"
        case .invalidData:
            return "Invalid contribution data"
        case .validationFailed(let errors):
            return errors.map { $0.localizedDescription ?? "" }.joined(separator: "; ")
        case .networkUnavailable:
            return "Network unavailable"
        case .coreDataSaveFailed:
            return "Core Data save failed"
        }
    }
}

import CoreData
import SwiftUI

extension Contribution {

    var displayStatus: ContributionStatus {
        get { ContributionStatus(rawValue: status ?? "pending") ?? .pending }
        set { status = newValue.rawValue }
    }

    var isApproved: Bool { displayStatus == .approved }

    var isProcessed: Bool { displayStatus == .processed || displayStatus == .duplicate }

    var contributorDisplay: String { user?.username ?? "Anonymous" }

    var ageDisplay: String {
        guard let timestamp else { return "Unknown" }
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: timestamp, to: Date())
        if let days = components.day, days > 0 { return "\(days)d ago" }
        if let hours = components.hour, hours > 0 { return "\(hours)h ago" }
        return "\(components.minute ?? 0)m ago"
    }

    func updateValidationResults(qualityScore: Double, warnings: [ValidationWarning], notes: String) {
        self.qualityScore = qualityScore
        self.validationWarnings = warnings.map { $0.localizedDescription ?? "" }
        self.validationNotes = notes
    }

    func approve(by user: User) throws {
        guard displayStatus == .pending else { throw ContributionError.invalidStatusTransition }
        displayStatus = .approved
        validationNotes = "Approved by \(user.username ?? "Moderator")"
        try managedObjectContext?.save()
    }

    func reject(by user: User) throws {
        guard displayStatus == .pending else { throw ContributionError.invalidStatusTransition }
        displayStatus = .rejected
        validationNotes = "Rejected by \(user.username ?? "Moderator")"
        try managedObjectContext?.save()
    }

    func markAsProcessed() throws {
        guard displayStatus == .approved else { throw ContributionError.invalidStatusTransition }
        displayStatus = .processed
        try managedObjectContext?.save()
    }

    func markAsDuplicate() throws {
        guard displayStatus == .approved else { throw ContributionError.invalidStatusTransition }
        displayStatus = .duplicate
        try managedObjectContext?.save()
    }
}
