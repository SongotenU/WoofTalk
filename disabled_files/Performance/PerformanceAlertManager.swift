import Foundation

final class PerformanceAlertManager {
    
    static let shared = PerformanceAlertManager()
    
    struct AlertThresholds {
        var memoryWarningMB: Int = 100
        var memoryCriticalMB: Int = 200
        var latencyWarningMs: Int = 1000
        var latencyCriticalMs: Int = 3000
        var networkLatencyWarningMs: Int = 2000
        var networkLatencyCriticalMs: Int = 5000
    }
    
    private var thresholds = AlertThresholds()
    private var alertHandlers: [AlertType: [AlertHandler]] = [:]
    private let alertLock = NSLock()
    
    private var performanceHistory: [PerformanceMetric] = []
    private let maxHistorySize = 100
    
    enum AlertType: String {
        case memoryWarning
        case memoryCritical
        case latencyWarning
        case latencyCritical
        case batteryWarning
        case batteryCritical
        case networkLatencyWarning
        case networkLatencyCritical
        case appLaunchSlow
    }
    
    typealias AlertHandler = (AlertType, [String: Any]) -> Void
    
    private init() {}
    
    func setThresholds(_ newThresholds: AlertThresholds) {
        thresholds = newThresholds
    }
    
    func registerHandler(for alertType: AlertType, handler: @escaping AlertHandler) {
        alertLock.lock()
        defer { alertLock.unlock() }
        
        if alertHandlers[alertType] == nil {
            alertHandlers[alertType] = []
        }
        alertHandlers[alertType]?.append(handler)
    }
    
    func recordMetric(_ metric: PerformanceMetric) {
        performanceHistory.append(metric)
        
        if performanceHistory.count > maxHistorySize {
            performanceHistory.removeFirst()
        }
        
        checkMetricThresholds(metric)
    }
    
    func recordMemoryUsage(_ bytes: UInt64) {
        let mb = Int(bytes / (1024 * 1024))
        
        let metric = PerformanceMetric(
            type: .memory,
            value: Double(mb),
            timestamp: Date()
        )
        
        recordMetric(metric)
    }
    
    func recordLatency(_ ms: Int) {
        let metric = PerformanceMetric(
            type: .latency,
            value: Double(ms),
            timestamp: Date()
        )
        
        recordMetric(metric)
    }
    
    func recordNetworkLatency(_ ms: Int) {
        let metric = PerformanceMetric(
            type: .networkLatency,
            value: Double(ms),
            timestamp: Date()
        )
        
        recordMetric(metric)
    }
    
    func recordAppLaunchTime(_ ms: Int) {
        if ms > 3000 {
            triggerAlert(.appLaunchSlow, details: ["launchTime": ms])
        }
    }
    
    private func checkMetricThresholds(_ metric: PerformanceMetric) {
        switch metric.type {
        case .memory:
            if metric.value > Double(thresholds.memoryCriticalMB) {
                triggerAlert(.memoryCritical, details: ["memoryMB": metric.value])
            } else if metric.value > Double(thresholds.memoryWarningMB) {
                triggerAlert(.memoryWarning, details: ["memoryMB": metric.value])
            }
            
        case .latency:
            if metric.value > Double(thresholds.latencyCriticalMs) {
                triggerAlert(.latencyCritical, details: ["latencyMs": metric.value])
            } else if metric.value > Double(thresholds.latencyWarningMs) {
                triggerAlert(.latencyWarning, details: ["latencyMs": metric.value])
            }
            
        case .networkLatency:
            if metric.value > Double(thresholds.networkLatencyCriticalMs) {
                triggerAlert(.networkLatencyCritical, details: ["latencyMs": metric.value])
            } else if metric.value > Double(thresholds.networkLatencyWarningMs) {
                triggerAlert(.networkLatencyWarning, details: ["latencyMs": metric.value])
            }
            
        default:
            break
        }
    }
    
    private func triggerAlert(_ type: AlertType, details: [String: Any]) {
        alertLock.lock()
        let handlers = alertHandlers[type] ?? []
        alertLock.unlock()
        
        for handler in handlers {
            handler(type, details)
        }
    }
    
    func getRecentMetrics(limit: Int = 10) -> [PerformanceMetric] {
        let count = min(limit, performanceHistory.count)
        return Array(performanceHistory.suffix(count))
    }
    
    func getMetricsSummary() -> MetricsSummary {
        guard !performanceHistory.isEmpty else {
            return MetricsSummary.empty
        }
        
        let memoryMetrics = performanceHistory.filter { $0.type == .memory }
        let latencyMetrics = performanceHistory.filter { $0.type == .latency }
        
        return MetricsSummary(
            avgMemory: average(of: memoryMetrics),
            maxMemory: maxValue(of: memoryMetrics),
            avgLatency: average(of: latencyMetrics),
            maxLatency: maxValue(of: latencyMetrics),
            sampleCount: performanceHistory.count
        )
    }
    
    private func average(of metrics: [PerformanceMetric]) -> Double {
        guard !metrics.isEmpty else { return 0 }
        let sum = metrics.reduce(0.0) { $0 + $1.value }
        return sum / Double(metrics.count)
    }
    
    private func maxValue(of metrics: [PerformanceMetric]) -> Double {
        return metrics.map { $0.value }.max() ?? 0
    }
}

struct PerformanceMetric {
    enum MetricType: String {
        case memory
        case latency
        case networkLatency
        case battery
        case cpu
    }
    
    let type: MetricType
    let value: Double
    let timestamp: Date
}

struct MetricsSummary {
    let avgMemory: Double
    let maxMemory: Double
    let avgLatency: Double
    let maxLatency: Double
    let sampleCount: Int
    
    static let empty = MetricsSummary(avgMemory: 0, maxMemory: 0, avgLatency: 0, maxLatency: 0, sampleCount: 0)
}
