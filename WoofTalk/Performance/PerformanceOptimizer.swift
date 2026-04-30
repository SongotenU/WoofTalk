import os.log
import Foundation

final class PerformanceOptimizer {
    
    static let shared = PerformanceOptimizer()
    
    private let memoryManager = MemoryManager.shared
    private let batteryOptimizer = BatteryOptimizer.shared
    private let networkOptimizer = NetworkOptimizer.shared
    private let resourceManager = ResourceManager.shared
    private let alertManager = PerformanceAlertManager.shared
    
    private var isInitialized = false
    
    private init() {}

    private var performanceTimer: Timer?

    deinit {
        performanceTimer?.invalidate()
    }
    
    func initialize() {
        guard !isInitialized else { return }
        
        isInitialized = true
        
        setupAlertHandlers()
        startPerformanceMonitoring()
    }
    
    private func setupAlertHandlers() {
        alertManager.registerHandler(for: .memoryWarning) { [weak self] _, _ in
            self?.handleMemoryWarning()
        }

        alertManager.registerHandler(for: .memoryCritical) { [weak self] _, _ in
            self?.handleMemoryCritical()
        }
    }
    
    private func startPerformanceMonitoring() {
        performanceTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.recordPerformanceMetrics()
        }
        
        recordPerformanceMetrics()
    }
    
    private func recordPerformanceMetrics() {
        let memoryUsage = memoryManager.currentMemoryUsage
        alertManager.recordMemoryUsage(memoryUsage)
    }
    
    private func handleMemoryWarning() {
        memoryManager.reduceCacheSizes(by: 0.5)
    }
    
    private func handleMemoryCritical() {
        memoryManager.clearAllCaches()
        resourceManager.clearNonEssentialCaches()
    }

    // MARK: - Integration Points
    
    func optimizeTranslationRequest(_ request: inout TranslationOptimizationRequest) {
        if batteryOptimizer.isLowPowerMode {
            let quality = batteryOptimizer.adaptiveQualityForTranslation()
            request.qualityThreshold = quality.qualityThreshold
            request.maxRetries = quality.maxRetries
        }
        
        if let cached = memoryManager.cachedTranslation(for: request.cacheKey) {
            request.useCachedResult(cached)
        }
    }
    
    func optimizeNetworkRequest(_ request: URLRequest) -> URLRequest? {
        if networkOptimizer.cachedResponse(for: request) != nil {
            return nil
        }
        return networkOptimizer.conditionalRequest(for: request)
    }
    
    func optimizeRealTimeProcessing() -> RealTimeOptimizationConfig {
        return RealTimeOptimizationConfig(
            pollingInterval: batteryOptimizer.pollingInterval,
            batchProcessing: batteryOptimizer.shouldBatchProcess,
            prefetchEnabled: batteryOptimizer.shouldPrefetch(userActive: true)
        )
    }

    // MARK: - Status
    
    func getPerformanceStatus() -> PerformanceStatus {
        return PerformanceStatus(
            memoryUsageMB: Int(memoryManager.currentMemoryUsage / (1024 * 1024)),
            cacheSize: memoryManager.cacheMemorySize,
            networkCacheSize: networkOptimizer.cacheSize,
            resourceCacheSize: resourceManager.paginationState.count,
            batteryState: batteryOptimizer.currentState,
            metricsSummary: alertManager.getMetricsSummary()
        )
    }
}

// MARK: - Request Types
struct TranslationOptimizationRequest {
    let text: String
    let sourceLanguage: String
    let targetLanguage: String

    var qualityThreshold: Double = 0.7
    var maxRetries: Int = 3

    var cacheKey: String {
        return "\(sourceLanguage):\(targetLanguage):\(text)"
    }
}

struct RealTimeOptimizationConfig {
    let pollingInterval: TimeInterval
    let batchProcessing: Bool
    let prefetchEnabled: Bool
}

struct PerformanceStatus {
    let memoryUsageMB: Int
    let cacheSize: Int
    let networkCacheSize: Int
    let resourceCacheSize: Int
    let batteryState: BatteryOptimizer.BatteryState
    let metricsSummary: MetricsSummary
}
