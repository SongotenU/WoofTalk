// MARK: - ContributionStatus

/// Status of a contribution through the moderation lifecycle
enum ContributionStatus: String, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    case processed = "processed"
    case duplicate = "duplicate"
    
    /// User-friendly display name for the status
    var displayName: String {
        switch self {
        case .pending:
            return "Pending Review"
        case .approved:
            return "Approved"
        case .rejected:
            return "Rejected"
        case .processed:
            return "Processed"
        case .duplicate:
            return "Duplicate"
        }
    }
    
    /// Color associated with the status for UI display
    var displayColor: Color {
        switch self {
        case .pending:
            return .yellow
        case .approved:
            return .green
        case .rejected:
            return .red
        case .processed:
            return .blue
        case .duplicate:
            return .orange
        }
    }
    
    /// Icon associated with the status for UI display
    var displayIcon: String {
        switch self {
        case .pending:
            return "clock"
        case .approved:
            return "checkmark.circle.fill"
        case .rejected:
            return "xmark.circle.fill"
        case .processed:
            return "checkmark.circle"
        case .duplicate:
            return "minus.circle.fill"
        }
    }
}

// MARK: - Contribution Extensions

extension Contribution {
    
    /// Computed property for display status
    var displayStatus: ContributionStatus {
        get {
            return ContributionStatus(rawValue: status ?? "pending") ?? .pending
        }
        set {
            status = newValue.rawValue
        }
    }
    
    /// Checks if contribution is pending review
    var isPending: Bool {
        return displayStatus == .pending
    }
    
    /// Checks if contribution is approved
    var isApproved: Bool {
        return displayStatus == .approved
    }
    
    /// Checks if contribution is rejected
    var isRejected: Bool {
        return displayStatus == .rejected
    }
    
    /// Checks if contribution is processed (approved or duplicate)
    var isProcessed: Bool {
        return displayStatus == .processed || displayStatus == .duplicate
    }
    
    /// Gets contribution age in days
    var ageInDays: Int {
        guard let timestamp = timestamp else { return 0 }
        return Calendar.current.dateComponents([.day], from: timestamp, to: Date()).day ?? 0
    }
    
    /// Gets contribution age in hours
    var ageInHours: Int {
        guard let timestamp = timestamp else { return 0 }
        return Calendar.current.dateComponents([.hour], from: timestamp, to: Date()).hour ?? 0
    }
    
    /// Gets contribution age in minutes
    var ageInMinutes: Int {
        guard let timestamp = timestamp else { return 0 }
        return Calendar.current.dateComponents([.minute], from: timestamp, to: Date()).minute ?? 0
    }
    
    /// Gets contribution age display string
    var ageDisplay: String {
        let days = ageInDays
        let hours = ageInHours
        let minutes = ageInMinutes
        
        if days > 0 {
            return "\(days) day\"(s) ago"
        } else if hours > 0 {
            return "\(hours) hour\"(s) ago"
        } else {
            return "\(minutes) minute\"(s) ago"
        }
    }
    
    /// Gets contribution status display
    var statusDisplay: String {
        return displayStatus.displayName
    }
    
    /// Gets contribution status color
    var statusColor: Color {
        return displayStatus.displayColor
    }
    
    /// Gets contribution status icon
    var statusIcon: String {
        return displayStatus.displayIcon
    }
    
    /// Checks if contribution can be approved
    var canBeApproved: Bool {
        return isPending
    }
    
    /// Checks if contribution can be rejected
    var canBeRejected: Bool {
        return isPending
    }
    
    /// Checks if contribution has been processed
    var isProcessed: Bool {
        return isApproved || isRejected || displayStatus == .processed || displayStatus == .duplicate
    }
    
    /// Creates a contribution from a translation record
    /// - Parameter translationRecord: The translation to create contribution from
    /// - Parameter user: The user who submitted the contribution
    /// - Returns: The created contribution
    static func create(from translationRecord: TranslationRecord, user: User, qualityScore: Double, warnings: [ValidationWarning]) -> Contribution {
        let contribution = Contribution(context: PersistenceController.shared.container.viewContext)
        contribution.id = UUID()
        contribution.humanText = translationRecord.humanText
        contribution.dogTranslation = translationRecord.dogTranslation
        contribution.qualityScore = qualityScore
        contribution.status = ContributionStatus.pending.rawValue
        contribution.timestamp = Date()
        contribution.user = user
        
        // Store validation warnings as comma-separated string
        contribution.validationWarnings = warnings.map { $0.localizedDescription }
        
        return contribution
    }
    
    /// Updates contribution with validation results
    /// - Parameters:
    ///   - qualityScore: Quality score from validation
    ///   - warnings: Validation warnings
    ///   - notes: Additional validation notes
    func updateValidationResults(qualityScore: Double, warnings: [ValidationWarning], notes: String) {
        self.qualityScore = qualityScore
        self.validationWarnings = warnings.map { $0.localizedDescription }
        self.validationNotes = notes
    }
    
    /// Approves the contribution
    /// - Parameter user: The moderator approving the contribution
    /// - Throws: Error if approval fails
    func approve(by user: User) throws {
        guard displayStatus == .pending else {
            throw ContributionError.invalidStatusTransition
        }
        
        displayStatus = .approved
        validationNotes = "Approved by \(user.username ?? \"Moderator\")"
        
        do {
            try managedObjectContext?.save()
        } catch {
            throw ContributionError.saveFailed
        }
    }
    
    /// Rejects the contribution
    /// - Parameter user: The moderator rejecting the contribution
    /// - Throws: Error if rejection fails
    func reject(by user: User) throws {
        guard displayStatus == .pending else {
            throw ContributionError.invalidStatusTransition
        }
        
        displayStatus = .rejected
        validationNotes = "Rejected by \(user.username ?? \"Moderator\")"
        
        do {
            try managedObjectContext?.save()
        } catch {
            throw ContributionError.saveFailed
        }
    }
    
    /// Marks contribution as processed
    /// - Throws: Error if marking as processed fails
    func markAsProcessed() throws {
        guard displayStatus == .approved else {
            throw ContributionError.invalidStatusTransition
        }
        
        displayStatus = .processed
        
        do {
            try managedObjectContext?.save()
        } catch {
            throw ContributionError.saveFailed
        }
    }
    
    /// Marks contribution as duplicate
    /// - Throws: Error if marking as duplicate fails
    func markAsDuplicate() throws {
        guard displayStatus == .approved else {
            throw ContributionError.invalidStatusTransition
        }
        
        displayStatus = .duplicate
        
        do {
            try managedObjectContext?.save()
        } catch {
            throw ContributionError.saveFailed
        }
    }
}

// MARK: - ContributionError

enum ContributionError: LocalizedError {
    case invalidStatusTransition
    case saveFailed
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .invalidStatusTransition:
            return "Invalid status transition"
        case .saveFailed:
            return "Failed to save contribution"
        case .invalidData:
            return "Invalid contribution data"
        }
    }
}