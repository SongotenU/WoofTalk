// MARK: - TranslationHistoryCell

import UIKit

final class TranslationHistoryCell: UITableViewCell {
    
    // MARK: - UI Components
    
    private let humanTextLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 2
        return label
    }()
    
    private let dogTranslationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 2
        label.textColor = .systemBlue
        return label
    }()
    
    private let timestampLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let latencyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .right
        return label
    }()
    
    private let submitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Submit", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        return button
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - State
    
    private var record: TranslationRecord?
    private var contributionManager: ContributionManager?
    private var contributionSyncManager: ContributionSyncManager?
    
    // MARK: - Delegate
    
    weak var delegate: TranslationHistoryCellDelegate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        
        // Stack view for text content
        let textStackView = UIStackView(arrangedSubviews: [humanTextLabel, dogTranslationLabel, timestampLabel])
        textStackView.axis = .vertical
        textStackView.spacing = 4
        textStackView.alignment = .leading
        
        // Stack view for right side (latency + button)
        let rightStackView = UIStackView(arrangedSubviews: [latencyLabel, submitButton, activityIndicator])
        rightStackView.axis = .vertical
        rightStackView.spacing = 4
        rightStackView.alignment = .trailing
        rightStackView.distribution = .fill
        
        // Main container
        let container = UIStackView(arrangedSubviews: [textStackView, rightStackView])
        container.spacing = 16
        container.alignment = .top
        
        contentView.addSubview(container)
        
        container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
        
        // Setup button actions
        submitButton.addTarget(self, action: #selector(submitButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Configuration
    
    func configure(with record: TranslationRecord, contributionManager: ContributionManager, contributionSyncManager: ContributionSyncManager) {
        self.record = record
        self.contributionManager = contributionManager
        self.contributionSyncManager = contributionSyncManager
        
        humanTextLabel.text = "Human: \(record.humanText)"
        dogTranslationLabel.text = "Dog: \(record.dogTranslation)"
        timestampLabel.text = formatTimestamp(record.timestamp)
        latencyLabel.text = String(format: "%.1f s", record.latency)
        
        // Color latency based on performance
        if record.latency < 1.0 {
            latencyLabel.textColor = .systemGreen
        } else if record.latency < 2.0 {
            latencyLabel.textColor = .systemOrange
        } else {
            latencyLabel.textColor = .systemRed
        }
        
        // Check if this record has already been submitted
        updateSubmitButtonState()
    }
    
    // MARK: - Actions
    
    @objc private func submitButtonTapped() {
        guard let record = record,
              let contributionManager = contributionManager,
              let contributionSyncManager = contributionSyncManager else {
            return
        }
        
        // Show activity indicator
        activityIndicator.startAnimating()
        submitButton.isHidden = true
        
        // Call validation and submission
        contributionManager.submitTranslation(record) { [weak self] result in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                
                switch result {
                case .success():
                    // Success - show confirmation
                    self?.showSuccessAlert()
                    self?.updateSubmitButtonState()
                    
                case .failure(let error):
                    // Show error
                    self?.showErrorAlert(error)
                    self?.submitButton.isHidden = false
                }
            }
        }
    }
    
    // MARK: - UI Updates
    
    private func updateSubmitButtonState() {
        // In a real app, we'd check if this record has been submitted
        // For now, always show the button
        submitButton.isHidden = false
        submitButton.isEnabled = true
    }
    
    private func showSuccessAlert() {
        let alert = UIAlertController(
            title: "Success",
            message: "Translation submitted successfully!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        delegate?.translationHistoryCell(self, wantsToShow: alert)
    }
    
    private func showErrorAlert(_ error: Error) {
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        delegate?.translationHistoryCell(self, wantsToShow: alert)
    }
    
    // MARK: - Helper Methods
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - TranslationHistoryCellDelegate

protocol TranslationHistoryCellDelegate: AnyObject {
    func translationHistoryCell(_ cell: TranslationHistoryCell, wantsToShow alert: UIAlertController)
}