// MARK: - TranslationViewController

import UIKit
import AVFoundation

/// Real-time translation display and user feedback interface
final class TranslationViewController: UIViewController {
    
    // MARK: - Properties
    private let realTranslationController: RealTranslationController
    private let audioTranslationBridge: AudioTranslationBridge
    
    // MARK: - UI Components
    private var translationView: TranslationView!
    private var controlPanel: ControlPanelView!
    private var latencyIndicator: LatencyIndicatorView!
    private var statusLabel: UILabel!
    
    // MARK: - State
    private var isTranslating = false
    private var currentLatency: TimeInterval = 0
    private var translationHistory: [TranslationRecord] = []
    private let settings = Settings.shared
    private var audioLevel: Float = 0
    
    // MARK: - Initialization
    init(realTranslationController: RealTranslationController,
         audioTranslationBridge: AudioTranslationBridge) {
        
        self.realTranslationController = realTranslationController
        self.audioTranslationBridge = audioTranslationBridge
        
        super.init(nibName: nil, bundle: nil)
        
        setupDelegates()
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
        
        // Update initial state
        updateUIState()
        
        // Battery monitoring
        monitorBatteryUsage()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Request microphone permission if needed
        requestMicrophonePermission()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Translation View
        translationView = TranslationView()
        translationView.delegate = self
        view.addSubview(translationView)
        
        // Control Panel
        controlPanel = ControlPanelView()
        controlPanel.delegate = self
        view.addSubview(controlPanel)
        
        // Latency Indicator
        latencyIndicator = LatencyIndicatorView()
        view.addSubview(latencyIndicator)
        
        // Status Label
        statusLabel = UILabel()
        statusLabel.font = .systemFont(ofSize: 14, weight: .medium)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 2
        statusLabel.textColor = .secondaryLabel
        view.addSubview(statusLabel)
    }
    
    private func setupConstraints() {
        // Translation View (main content)
        translationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            translationView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            translationView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            translationView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            translationView.heightAnchor.constraint(equalToConstant: 300)
        ])
        
        // Control Panel (bottom controls)
        controlPanel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            controlPanel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            controlPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            controlPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            controlPanel.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        // Latency Indicator (top right)
        latencyIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            latencyIndicator.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            latencyIndicator.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            latencyIndicator.widthAnchor.constraint(equalToConstant: 80),
            latencyIndicator.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // Status Label (center below translation view)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: translationView.bottomAnchor, constant: 10),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            statusLabel.bottomAnchor.constraint(equalTo: controlPanel.topAnchor, constant: -10)
        ])
    }
    
    private func setupGestures() {
        // Add tap gesture to translation view for quick start/stop
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(translationViewTapped))
        translationView.addGestureRecognizer(tapGesture)
        
        // Add pan gesture for volume control
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        translationView.addGestureRecognizer(panGesture)
    }
    
    private func setupDelegates() {
        realTranslationController.delegate = self
        audioTranslationBridge.delegate = self
    }
    
    // MARK: - Permission Handling
    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.statusLabel.text = "Microphone access granted"
                } else {
                    self?.statusLabel.text = "Microphone access denied - enable in Settings"
                    self?.controlPanel.setTranslateButton(enabled: false)
                }
            }
        }
    }
    
    // MARK: - State Management
    private func updateUIState() {
        let isAvailable = realTranslationController.isWithinLatencyThreshold
        controlPanel.setTranslateButton(enabled: isAvailable)
        
        let statusText: String
        switch realTranslationController.currentState {
        case .idle:
            statusText = "Ready to translate"
        case .capturing:
            statusText = "Capturing audio..."
        case .recognizing:
            statusText = "Recognizing speech..."
        case .translating:
            statusText = "Translating..."
        case .playing:
            statusText = "Playing translation..."
        case .error:
            statusText = "Error occurred"
        }
        
        statusLabel.text = statusText
    }
    
    private func updateLatencyDisplay() {
        latencyIndicator.updateLatency(currentLatency)
        
        // Update UI based on latency
        if currentLatency < 1.0 {
            latencyIndicator.color = .systemGreen
        } else if currentLatency < 2.0 {
            latencyIndicator.color = .systemOrange
        } else {
            latencyIndicator.color = .systemRed
        }
    }
    
    // MARK: - Action Handlers
    @objc private func translationViewTapped() {
        toggleTranslation()
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: translationView)
        
        switch gesture.state {
        case .began:
            // Start volume adjustment
            break
        case .changed:
            // Adjust volume based on vertical position
            let volume = max(0.0, min(1.0, 1.0 - (translation.y / 200.0)))
            realTranslationController.audioPlayback.volume = volume
        case .ended:
            // End volume adjustment
            break
        default:
            break
        }
    }
    
    private func toggleTranslation() {
        if isTranslating {
            stopTranslation()
        } else {
            startTranslation()
        }
    }
    
    private func startTranslation() {
        do {
            try realTranslationController.startTranslation()
            isTranslating = true
            controlPanel.setTranslateButton(title: "Stop", color: .systemRed)
            updateUIState()
        } catch {
            showError(error)
        }
    }
    
    private func stopTranslation() {
        realTranslationController.stopTranslation()
        isTranslating = false
        controlPanel.setTranslateButton(title: "Translate", color: .systemBlue)
        updateUIState()
    }
    
    // MARK: - Error Handling
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Translation Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        
        // Add retry action
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
            self.retryTranslation()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func retryTranslation() {
        // Attempt to restart translation
        do {
            try realTranslationController.startTranslation()
            isTranslating = true
            controlPanel.setTranslateButton(title: "Stop", color: .systemRed)
            updateUIState()
        } catch {
            showError(error)
        }
    }
}

// MARK: - TranslationViewController Extensions

extension TranslationViewController: RealTranslationControllerDelegate {
    func realTranslationControllerDidStart(_ controller: RealTranslationController) {
        isTranslating = true
        updateUIState()
    }
    
    func realTranslationControllerDidStop(_ controller: RealTranslationController, totalTime: TimeInterval) {
        isTranslating = false
        updateUIState()
    }
    
    func realTranslationControllerDidPause(_ controller: RealTranslationController) {
        updateUIState()
    }
    
    func realTranslationControllerDidResume(_ controller: RealTranslationController) {
        updateUIState()
    }
    
    func realTranslationController(_ controller: RealTranslationController, didUpdateMetrics metrics: RealTranslationController.TranslationMetrics) {
        currentLatency = metrics.lastTranslationLatency
        updateLatencyDisplay()
    }
    
    func realTranslationController(_ controller: RealTranslationController, didTransitionFrom oldState: RealTranslationController.TranslationState, to newState: RealTranslationController.TranslationState) {
        updateUIState()
    }
    
    func realTranslationController(_ controller: RealTranslationController, didTranslate text: String, toDogTranslation: String) {
        // Add to translation history
        let record = TranslationRecord(
            humanText: text,
            dogTranslation: toDogTranslation,
            timestamp: Date(),
            latency: currentLatency
        )
        translationHistory.insert(record, at: 0)
        
        // Update translation view
        translationView.addTranslation(human: text, dog: toDogTranslation)
        
        // Update status
        statusLabel.text = "Translated: \(text)"
        
        // Success feedback
        if settings.enableVibration {
            // Trigger vibration feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
    
    func realTranslationController(_ controller: RealTranslationController, didFailWithError error: Error) {
        showError(error)
        
        // Update UI to show error state
        controlPanel.setTranslateButton(title: "Translate", color: .systemBlue)
        isTranslating = false
        updateUIState()
    }
    
    func realTranslationController(_ controller: RealTranslationController, didPlayAudio duration: TimeInterval) {
        statusLabel.text = "Playing audio for \(String(format: "%.1f", duration))s"
    }
    
    func realTranslationController(_ controller: RealTranslationController, didUpdateAudioLevel level: Float) {
        // Update visual feedback for audio level
        translationView.updateAudioLevel(level)
    }
    
    func realTranslationController(_ controller: RealTranslationController, didRecognizePartialSpeech text: String) {
        // Show partial recognition for feedback
        translationView.showPartialRecognition(text)
    }
}

extension TranslationViewController: AudioTranslationBridgeDelegate {
    func audioTranslationBridgeDidStart(_ bridge: AudioTranslationBridge) {
        // Handle bridge start if needed
    }
    
    func audioTranslationBridgeDidStop(_ bridge: AudioTranslationBridge) {
        // Handle bridge stop if needed
    }
    
    func audioTranslationBridge(_ bridge: AudioTranslationBridge, didProcessBuffer buffer: AVAudioPCMBuffer, withResult result: Result<String, Error>, processingTime: TimeInterval) {
        // Handle buffer processing results
    }
    
    func audioTranslationBridge(_ bridge: AudioTranslationBridge, didFailWithError error: Error) {
        showError(error)
        
        // Update UI to show error state
        controlPanel.setTranslateButton(title: "Translate", color: .systemBlue)
        isTranslating = false
        updateUIState()
    }
    
    func audioTranslationBridge(_ bridge: AudioTranslationBridge, didUpdateProcessingStats stats: AudioTranslationBridge.ProcessingStats) {
        // Update processing stats display if needed
    }
}

// MARK: - TranslationViewController Extensions (UI Actions)

extension TranslationViewController: TranslationViewDelegate {
    func translationViewDidTapTranslate(_ view: TranslationView) {
        toggleTranslation()
    }
    
    func translationViewDidTapClear(_ view: TranslationView) {
        translationView.clearTranslations()
        translationHistory.removeAll()
    }
    
    func translationViewDidTapHistory(_ view: TranslationView) {
        showTranslationHistory()
    }
}

extension TranslationViewController: ControlPanelViewDelegate {
    func controlPanelDidTapTranslate(_ view: ControlPanelView) {
        toggleTranslation()
    }
    
    func controlPanelDidTapSettings(_ view: ControlPanelView) {
        showSettings()
    }
    
    func controlPanelDidTapHelp(_ view: ControlPanelView) {
        showHelp()
    }
}

// MARK: - Helper Methods

extension TranslationViewController {
    private func showTranslationHistory() {
        let historyVC = TranslationHistoryViewController(translationHistory: translationHistory)
        let navVC = UINavigationController(rootViewController: historyVC)
        present(navVC, animated: true)
    }
    
    private func showSettings() {
        let settingsVC = SettingsViewController()
        let navVC = UINavigationController(rootViewController: settingsVC)
        present(navVC, animated: true)
    }
    
    private func showHelp() {
        let helpVC = HelpViewController()
        let navVC = UINavigationController(rootViewController: helpVC)
        present(navVC, animated: true)
    }
    
    // MARK: - Battery Optimization
    
    private func optimizeForBattery() {
        // Reduce animation quality when battery is low
        if UIDevice.current.batteryState != .unplugged {
            UIView.setAnimationsEnabled(false)
        }
    }
    
    private func monitorBatteryUsage() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(batteryLevelChanged), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
    }
    
    @objc private func batteryLevelChanged() {
        let batteryLevel = UIDevice.current.batteryLevel
        if batteryLevel < 0.2 {
            // Reduce processing when battery is low
            realTranslationController.latencyThreshold = 3.0
        } else if batteryLevel < 0.5 {
            realTranslationController.latencyThreshold = 2.5
        } else {
            realTranslationController.latencyThreshold = 2.0
        }
    }
}

// MARK: - Data Structures

struct TranslationRecord: Codable {
    let humanText: String
    let dogTranslation: String
    let timestamp: Date
    let latency: TimeInterval
    
    init(humanText: String, dogTranslation: String, timestamp: Date, latency: TimeInterval = 0) {
        self.humanText = humanText
        self.dogTranslation = dogTranslation
        self.timestamp = timestamp
        self.latency = latency
    }
}