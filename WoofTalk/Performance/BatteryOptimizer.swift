import Foundation

final class BatteryOptimizer {
    
    static let shared = BatteryOptimizer()
    
    enum BatteryState {
        case charging
        case low
        case critical
        case normal
    }
    
    private(set) var currentState: BatteryState = .normal
    
    private let lowBatteryThreshold: Float = 0.2
    private let criticalBatteryThreshold: Float = 0.1
    
    private var isEnergyEfficientMode = false
    private var adaptivePollingInterval: TimeInterval = 1.0
    private var batchProcessingEnabled = true
    
    private var pendingAnalyticsUploads: [() -> Void] = []
    private var uploadCoalesceWorkItem: DispatchWorkItem?
    private let uploadCoalesceInterval: TimeInterval = 60.0
    
    private var audioBufferQueue: [AudioBufferBatch] = []
    private var audioBatchTimer: Timer?
    private let audioBatchInterval: TimeInterval = 0.5
    
    private init() {
        setupBatteryMonitoring()
    }
    
    private func setupBatteryMonitoring() {
        updateBatteryState()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(lowPowerModeChanged),
            name: NSNotification.Name.NSProcessInfoPowerStateDidChange,
            object: nil
        )
    }
    
    @objc private func lowPowerModeChanged() {
        updateBatteryState()
    }
    
    private func updateBatteryState() {
        let isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        
        if isLowPowerMode {
            currentState = .low
            isEnergyEfficientMode = true
        } else {
            currentState = .normal
            isEnergyEfficientMode = false
        }
        
        applyOptimizationSettings()
        NotificationCenter.default.post(name: .batteryStateChanged, object: currentState)
    }
    
    private func applyOptimizationSettings() {
        switch currentState {
        case .charging:
            adaptivePollingInterval = 0.5
            batchProcessingEnabled = true
        case .normal:
            adaptivePollingInterval = 1.0
            batchProcessingEnabled = true
        case .low:
            adaptivePollingInterval = 2.0
            batchProcessingEnabled = true
        case .critical:
            adaptivePollingInterval = 5.0
            batchProcessingEnabled = false
        }
    }
    
    var pollingInterval: TimeInterval {
        return adaptivePollingInterval
    }
    
    var shouldBatchProcess: Bool {
        return batchProcessingEnabled
    }
    
    var isLowPowerMode: Bool {
        return isEnergyEfficientMode
    }
    
    func coalesceAnalyticsUpload(_ upload: @escaping () -> Void) {
        pendingAnalyticsUploads.append(upload)
        
        uploadCoalesceWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.flushPendingUploads()
        }
        
        uploadCoalesceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + uploadCoalesceInterval, execute: workItem)
    }
    
    private func flushPendingUploads() {
        let uploads = pendingAnalyticsUploads
        pendingAnalyticsUploads.removeAll()
        
        for upload in uploads {
            upload()
        }
    }
    
    func batchAudioBuffer(_ buffer: AudioBufferBatch) {
        audioBufferQueue.append(buffer)
        
        if audioBatchTimer == nil {
            audioBatchTimer = Timer.scheduledTimer(withTimeInterval: audioBatchInterval, repeats: false) { [weak self] _ in
                self?.processAudioBatch()
            }
        }
    }
    
    private func processAudioBatch() {
        audioBatchTimer = nil
        
        guard !audioBufferQueue.isEmpty else { return }
        
        let batch = audioBufferQueue
        audioBufferQueue.removeAll()
        
        processBatch(batch)
    }
    
    private func processBatch(_ batch: [AudioBufferBatch]) {
    }
    
    func shouldPrefetch(userActive: Bool) -> Bool {
        if currentState == .critical {
            return false
        }
        
        if currentState == .low && userActive {
            return false
        }
        
        return true
    }
    
    func adaptiveQualityForTranslation() -> AdaptiveQualityLevel {
        switch currentState {
        case .critical:
            return .minimal
        case .low:
            return .balanced
        case .normal, .charging:
            return .full
        }
    }
    
    enum AdaptiveQualityLevel {
        case full
        case balanced
        case minimal
        
        var qualityThreshold: Double {
            switch self {
            case .full: return 0.7
            case .balanced: return 0.5
            case .minimal: return 0.3
            }
        }
        
        var maxRetries: Int {
            switch self {
            case .full: return 3
            case .balanced: return 2
            case .minimal: return 1
            }
        }
    }
}

struct AudioBufferBatch {
    let buffer: Data
    let timestamp: Date
    let sampleRate: Double
}

extension Notification.Name {
    static let batteryStateChanged = Notification.Name("BatteryStateChanged")
}
