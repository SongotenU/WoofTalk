// MARK: - OfflineModeViewController

import UIKit

/// View controller for offline mode interface
final class OfflineModeViewController: UIViewController {
    
    // MARK: - Public Types
    
    /// Offline mode state
    enum OfflineModeState: Equatable {
        case connected
        case disconnected
        case degraded
        case unknown
        case error(String)
    }
    
    /// Translation capability
    enum TranslationCapability: Equatable {
        case full
        case partial
        case limited
        case none
    }
    
    // MARK: - Private Properties
    
    private let offlineManager: OfflineManager
    private let connectivityIndicator: ConnectivityIndicatorView
    private let capabilityDisplay: CapabilityDisplayView
    private let actionButton: ActionButton
    private let statusLabel: UILabel
    private let scrollView: UIScrollView
    
    private var currentState: OfflineModeState = .unknown
    private var currentCapability: TranslationCapability = .none
    
    // MARK: - Initialization
    
    init(offlineManager: OfflineManager = OfflineManager()) {
        self.offlineManager = offlineManager
        self.connectivityIndicator = ConnectivityIndicatorView()
        self.capabilityDisplay = CapabilityDisplayView()
        self.actionButton = ActionButton()
        self.statusLabel = UILabel()
        self.scrollView = UIScrollView()
        
        super.init(nibName: nil, bundle: nil)
        
        setupObservers()
        setupInitialState()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
        setupGestures()
        
        // Initial state update
        updateState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Start monitoring
        offlineManager.connectivityManager.startMonitoring()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Stop monitoring
        offlineManager.connectivityManager.stopMonitoring()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Offline Mode"
        
        // Scroll view
        view.addSubview(scrollView)
        
        // Content view
        let contentView = UIView()
        scrollView.addSubview(contentView)
        
        // Connectivity indicator
        contentView.addSubview(connectivityIndicator)
        
        // Capability display
        contentView.addSubview(capabilityDisplay)
        
        // Action button
        contentView.addSubview(actionButton)
        
        // Status label
        contentView.addSubview(statusLabel)
        
        // Configure views
        setupViewConfigurations()
    }
    
    private func setupConstraints() {
        // Scroll view fills the view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Content view
        let contentView = scrollView.subviews.first!
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Connectivity indicator
        connectivityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            connectivityIndicator.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            connectivityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            connectivityIndicator.widthAnchor.constraint(equalToConstant: 200),
            connectivityIndicator.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        // Capability display
        capabilityDisplay.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            capabilityDisplay.topAnchor.constraint(equalTo: connectivityIndicator.bottomAnchor, constant: 30),
            capabilityDisplay.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            capabilityDisplay.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            capabilityDisplay.heightAnchor.constraint(equalToConstant: 120)
        ])
        
        // Action button
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            actionButton.topAnchor.constraint(equalTo: capabilityDisplay.bottomAnchor, constant: 30),
            actionButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            actionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            actionButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Status label
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            statusLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    private func setupGestures() {
        // Add tap gesture to action button
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(actionButtonTapped))
        actionButton.addGestureRecognizer(tapGesture)
    }
    
    private func setupObservers() {
        // Observe network status changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(networkStatusChanged),
            name: Notification.Name("NetworkStatusChanged"),
            object: nil
        )
        
        // Observe cache updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cacheUpdated),
            name: Notification.Name("CacheUpdated"),
            object: nil
        )
    }
    
    private func setupInitialState() {
        currentState = .unknown
        currentCapability = .none
        updateState()
    }
    
    private func setupViewConfigurations() {
        // Connectivity indicator
        connectivityIndicator.style = .large
        connectivityIndicator.color = .systemGray
        
        // Capability display
        capabilityDisplay.style = .detailed
        capabilityDisplay.color = .systemGray
        
        // Action button
        actionButton.style = .primary
        actionButton.title = "Manage Offline Cache"
        actionButton.isEnabled = false
        
        // Status label
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        statusLabel.font = .preferredFont(forTextStyle: .body)
        statusLabel.textColor = .secondaryLabel
    }
    
    // MARK: - State Management
    
    private func updateState() {
        // Update connectivity
        updateConnectivity()
        
        // Update capability
        updateCapability()
        
        // Update UI
        updateUI()
    }
    
    private func updateConnectivity() {
        let status = offlineManager.connectivityManager.status
        switch status {
        case .online:
            currentState = .connected
        case .offline:
            currentState = .disconnected
        case .unknown:
            currentState = .unknown
        }
    }
    
    private func updateCapability() {
        let availability = offlineManager.translationAvailability
        switch availability {
        case .fullyAvailable:
            currentCapability = .full
        case .partiallyAvailable:
            currentCapability = .partial
        case .limited:
            currentCapability = .limited
        case .unavailable:
            currentCapability = .none
        }
    }
    
    private func updateUI() {
        // Update connectivity indicator
        updateConnectivityIndicator()
        
        // Update capability display
        updateCapabilityDisplay()
        
        // Update action button
        updateActionButton()
        
        // Update status label
        updateStatusLabel()
    }
    
    private func updateConnectivityIndicator() {
        switch currentState {
        case .connected:
            connectivityIndicator.style = .large
            connectivityIndicator.color = .systemGreen
            connectivityIndicator.title = "Online"
        case .disconnected:
            connectivityIndicator.style = .large
            connectivityIndicator.color = .systemRed
            connectivityIndicator.title = "Offline"
        case .unknown:
            connectivityIndicator.style = .large
            connectivityIndicator.color = .systemGray
            connectivityIndicator.title = "Unknown"
        case .error(let message):
            connectivityIndicator.style = .large
            connectivityIndicator.color = .systemOrange
            connectivityIndicator.title = "Error"
            connectivityIndicator.subtitle = message
        case .degraded:
            connectivityIndicator.style = .large
            connectivityIndicator.color = .systemYellow
            connectivityIndicator.title = "Degraded"
        }
    }
    
    private func updateCapabilityDisplay() {
        let assessment = offlineManager.assessCapabilities()
        
        capabilityDisplay.title = "Translation Capability"
        capabilityDisplay.subtitle = "\(assessment.coveragePercentage)% coverage"
        capabilityDisplay.progress = assessment.coveragePercentage / 100
        capabilityDisplay.status = assessment.status
        
        switch assessment.status {
        case .online:
            capabilityDisplay.color = .systemGreen
        case .offline:
            capabilityDisplay.color = .systemBlue
        case .degraded:
            capabilityDisplay.color = .systemYellow
        case .unknown:
            capabilityDisplay.color = .systemGray
        }
    }
    
    private func updateActionButton() {
        switch currentCapability {
        case .full, .partial:
            actionButton.isEnabled = true
            actionButton.title = "Manage Offline Cache"
            actionButton.color = .systemBlue
        case .limited:
            actionButton.isEnabled = true
            actionButton.title = "Limited Offline Mode"
            actionButton.color = .systemOrange
        case .none:
            actionButton.isEnabled = false
            actionButton.title = "Offline Mode Unavailable"
            actionButton.color = .systemGray
        }
    }
    
    private func updateStatusLabel() {
        let stats = offlineManager.getCacheStatistics()
        let assessment = offlineManager.assessCapabilities()
        
        let statusText: String
        switch currentState {
        case .connected:
            statusText = "Online - All features available"
        case .disconnected:
            statusText = "Offline - \(assessment.coveragePercentage)% of translations cached"
        case .unknown:
            statusText = "Connection status unknown"
        case .error(let message):
            statusText = "Error: \(message)"
        case .degraded:
            statusText = "Degraded connection - some features limited"
        }
        
        statusLabel.text = statusText
    }
    
    // MARK: - Action Handlers
    
    @objc private func actionButtonTapped() {
        showOfflineOptions()
    }
    
    @objc private func networkStatusChanged() {
        updateState()
    }
    
    @objc private func cacheUpdated() {
        updateState()
    }
    
    // MARK: - Helper Methods
    
    private func showOfflineOptions() {
        let alert = UIAlertController(
            title: "Offline Options",
            message: "Manage your offline translation cache",
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "Clear Cache", style: .destructive) { _ in
            self.clearCache()
        })
        
        alert.addAction(UIAlertAction(title: "View Cache Stats", style: .default) { _ in
            self.viewCacheStats()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func clearCache() {
        let confirmAlert = UIAlertController(
            title: "Clear Cache",
            message: "This will remove all cached translations. Are you sure?",
            preferredStyle: .alert
        )
        
        confirmAlert.addAction(UIAlertAction(title: "Clear", style: .destructive) { _ in
            self.offlineManager.clearCache()
            self.updateState()
        })
        
        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(confirmAlert, animated: true)
    }
    
    private func viewCacheStats() {
        let stats = offlineManager.getCacheStatistics()
        let assessment = offlineManager.assessCapabilities()
        
        let statsAlert = UIAlertController(
            title: "Cache Statistics",
            message: "\nTotal Phrases: \(stats.totalPhrases)\nCached: \(stats.cachedPhrases)\nCoverage: \(assessment.coveragePercentage)%\nStorage: \(stats.storageUsage)KB",
            preferredStyle: .alert
        )
        
        statsAlert.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(statsAlert, animated: true)
    }
    
    // MARK: - Cleanup
    
    deinit {
        // Remove observers
        NotificationCenter.default.removeObserver(self)
        
        // Stop monitoring
        offlineManager.connectivityManager.stopMonitoring()
    }
}