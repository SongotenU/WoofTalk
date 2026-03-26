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
    
    func initialize() {
        guard !isInitialized else { return }
        
        isInitialized = true
        
        setupAlertHandlers()
        startPerformanceMonitoring()
    }
    
    private func setupAlertHandlers() {
        alertManager.registerHandler(for: .memoryWarning) { type, details in
            print("Performance Alert: \(type.rawValue) - \(details)")
            self.handleMemoryWarning()
        }
        
        alertManager.registerHandler(for: .memoryCritical) { type, details in
            print("Performance Alert: \(type.rawValue) - \(details)")
            self.handleMemoryCritical()
        }
        
        alertManager.registerHandler(for: .latencyWarning) { type, details in
            print("Performance Alert: \(type.rawValue) - \(details)")
        }
        
        alertManager.registerHandler(for: .batteryWarning) { type, details in
            print("Performance Alert: \(type.rawValue) - \(details)")
            self.adjustForLowBattery()
        }
    }
    
    private func startPerformanceMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
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
    
    private func adjustForLowBattery() {
        // Already handled by BatteryOptimizer
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
        if let cachedData = networkOptimizer.cachedResponse(for: request) {
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
    
    func optimizeAnalyticsUpload() {
        batteryOptimizer.coalesceAnalyticsUpload { [weak self] in
            self?.flushAnalytics()
        }
    }
    
    private func flushAnalytics() {
    }
    
    // MARK: - Status
    
    func getPerformanceStatus() -> PerformanceStatus {
        return PerformanceStatus(
            memoryUsageMB: Int(memoryManager.currentMemoryUsage / (1024 * 1024)),
            cacheSize: memoryManager.cacheMemorySize,
            networkCacheSize: networkOptimizer.cacheSize,
            resourceCacheSize: resourceManager.totalCacheSize,
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
    
    func useCachedResult(_ result: CachedTranslation) {
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
