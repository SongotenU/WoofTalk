import Foundation

final class LatencyMonitor {
    static let shared = LatencyMonitor()
    
    private var latencyHistory: [LatencyRecord] = []
    private let maxHistorySize = 1000
    private let queue = DispatchQueue(label: "com.wooftalk.latencymonitor", qos: .utility)
    
    struct LatencyRecord: Codable {
        let timestamp: Date
        let latency: TimeInterval
        let translationType: String
        let success: Bool
    }
    
    private init() {}
    
    func recordLatency(_ latency: TimeInterval, translationType: String, success: Bool) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let record = LatencyRecord(
                timestamp: Date(),
                latency: latency,
                translationType: translationType,
                success: success
            )
            
            self.latencyHistory.append(record)
            
            if self.latencyHistory.count > self.maxHistorySize {
                self.latencyHistory.removeFirst(self.latencyHistory.count - self.maxHistorySize)
            }
            
            NotificationCenter.default.post(
                name: .latencyRecorded,
                object: nil,
                userInfo: ["latency": latency, "type": translationType]
            )
        }
    }
    
    func getAverageLatency(duration: TimeInterval = 60) -> TimeInterval {
        queue.sync {
            let cutoff = Date().addingTimeInterval(-duration)
            let recentRecords = latencyHistory.filter { $0.timestamp > cutoff }
            
            guard !recentRecords.isEmpty else { return 0 }
            
            let totalLatency = recentRecords.reduce(0.0) { $0 + $1.latency }
            return totalLatency / Double(recentRecords.count)
        }
    }
    
    func getP50Latency(duration: TimeInterval = 60) -> TimeInterval {
        queue.sync {
            let cutoff = Date().addingTimeInterval(-duration)
            let recentRecords = latencyHistory.filter { $0.timestamp > cutoff }
            
            guard !recentRecords.isEmpty else { return 0 }
            
            let sortedLatencies = recentRecords.map { $0.latency }.sorted()
            let midIndex = sortedLatencies.count / 2
            
            if sortedLatencies.count % 2 == 0 {
                return (sortedLatencies[midIndex - 1] + sortedLatencies[midIndex]) / 2
            } else {
                return sortedLatencies[midIndex]
            }
        }
    }
    
    func getP95Latency(duration: TimeInterval = 60) -> TimeInterval {
        queue.sync {
            let cutoff = Date().addingTimeInterval(-duration)
            let recentRecords = latencyHistory.filter { $0.timestamp > cutoff }
            
            guard !recentRecords.isEmpty else { return 0 }
            
            let sortedLatencies = recentRecords.map { $0.latency }.sorted()
            let index = Int(Double(sortedLatencies.count) * 0.95)
            
            return sortedLatencies[min(index, sortedLatencies.count - 1)]
        }
    }
    
    func getP99Latency(duration: TimeInterval = 60) -> TimeInterval {
        queue.sync {
            let cutoff = Date().addingTimeInterval(-duration)
            let recentRecords = latencyHistory.filter { $0.timestamp > cutoff }
            
            guard !recentRecords.isEmpty else { return 0 }
            
            let sortedLatencies = recentRecords.map { $0.latency }.sorted()
            let index = Int(Double(sortedLatencies.count) * 0.99)
            
            return sortedLatencies[min(index, sortedLatencies.count - 1)]
        }
    }
    
    func getSuccessRate(duration: TimeInterval = 60) -> Double {
        queue.sync {
            let cutoff = Date().addingTimeInterval(-duration)
            let recentRecords = latencyHistory.filter { $0.timestamp > cutoff }
            
            guard !recentRecords.isEmpty else { return 0 }
            
            let successCount = recentRecords.filter { $0.success }.count
            return Double(successCount) / Double(recentRecords.count)
        }
    }
    
    func getLatencyDistribution() -> [String: Int] {
        queue.sync {
            var distribution: [String: Int] = [
                "<500ms": 0,
                "500ms-1s": 0,
                "1s-2s": 0,
                ">2s": 0
            ]
            
            for record in latencyHistory {
                if record.latency < 0.5 {
                    distribution["<500ms", default: 0] += 1
                } else if record.latency < 1.0 {
                    distribution["500ms-1s", default: 0] += 1
                } else if record.latency < 2.0 {
                    distribution["1s-2s", default: 0] += 1
                } else {
                    distribution[">2s", default: 0] += 1
                }
            }
            
            return distribution
        }
    }
    
    func getReport() -> LatencyReport {
        queue.sync {
            LatencyReport(
                averageLatency: getAverageLatency(),
                p50Latency: getP50Latency(),
                p95Latency: getP95Latency(),
                p99Latency: getP99Latency(),
                successRate: getSuccessRate(),
                totalTranslations: latencyHistory.count,
                distribution: getLatencyDistribution()
            )
        }
    }
    
    func clearHistory() {
        queue.async { [weak self] in
            self?.latencyHistory.removeAll()
        }
    }
}

struct LatencyReport {
    let averageLatency: TimeInterval
    let p50Latency: TimeInterval
    let p95Latency: TimeInterval
    let p99Latency: TimeInterval
    let successRate: Double
    let totalTranslations: Int
    let distribution: [String: Int]
    
    var meetsTarget: Bool {
        return averageLatency < 1.0
    }
    
    var summary: String {
        return """
        Latency Report
        ==============
        Average: \(String(format: "%.2f", averageLatency))s
        P50: \(String(format: "%.2f", p50Latency))s
        P95: \(String(format: "%.2f", p95Latency))s
        P99: \(String(format: "%.2f", p99Latency))s
        Success Rate: \(String(format: "%.1f", successRate * 100))%
        Total: \(totalTranslations)
        Target Met: \(meetsTarget ? "YES" : "NO")
        """
    }
}

extension Notification.Name {
    static let latencyRecorded = Notification.Name("latencyRecorded")
}
