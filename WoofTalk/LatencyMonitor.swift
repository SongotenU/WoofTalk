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
        queue.async {
            let record = LatencyRecord(timestamp: Date(), latency: latency, translationType: translationType, success: success)
            self.latencyHistory.append(record)
            if self.latencyHistory.count > self.maxHistorySize {
                self.latencyHistory.removeFirst(self.latencyHistory.count - self.maxHistorySize)
            }
            NotificationCenter.default.post(name: .latencyRecorded, object: nil, userInfo: ["latency": latency, "type": translationType])
        }
    }
    
    private func recentRecords(duration: TimeInterval) -> [LatencyRecord] {
        let cutoff = Date().addingTimeInterval(-duration)
        return latencyHistory.filter { $0.timestamp > cutoff }
    }
    
    private func percentileLatency(_ records: [LatencyRecord], p: Double) -> TimeInterval {
        guard !records.isEmpty else { return 0.0 }
        let sorted = records.map { $0.latency }.sorted()
        let index = min(Int(Double(sorted.count) * p), sorted.count - 1)
        return sorted[index]
    }
    
    func getAverageLatency(duration: TimeInterval = 60) -> TimeInterval {
        queue.sync {
            let records = recentRecords(duration: duration)
            guard !records.isEmpty else { return 0.0 }
            return records.reduce(0.0) { $0 + $1.latency } / Double(records.count)
        }
    }

    func getP50Latency(duration: TimeInterval = 60) -> TimeInterval {
        queue.sync {
            let records = recentRecords(duration: duration)
            guard !records.isEmpty else { return 0.0 }
            let sorted = records.map { $0.latency }.sorted()
            let mid = sorted.count / 2
            return sorted.count % 2 == 0 ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid]
        }
    }

    func getP95Latency(duration: TimeInterval = 60) -> TimeInterval {
        queue.sync { percentileLatency(recentRecords(duration: duration), p: 0.95) }
    }

    func getP99Latency(duration: TimeInterval = 60) -> TimeInterval {
        queue.sync { percentileLatency(recentRecords(duration: duration), p: 0.99) }
    }

    func getSuccessRate(duration: TimeInterval = 60) -> Double {
        queue.sync {
            let records = recentRecords(duration: duration)
            guard !records.isEmpty else { return 0.0 }
            return Double(records.filter { $0.success }.count) / Double(records.count)
        }
    }

    func getLatencyDistribution() -> [String: Int] {
        queue.sync {
            var distribution = ["<500ms": 0, "500ms-1s": 0, "1s-2s": 0, ">2s": 0]
            for record in latencyHistory {
                switch record.latency {
                case ..<0.5: distribution["<500ms"]! += 1
                case ..<1.0: distribution["500ms-1s"]! += 1
                case ..<2.0: distribution["1s-2s"]! += 1
                default: distribution[">2s"]! += 1
                }
            }
            return distribution
        }
    }
    
    func getRecentLatencies(count: Int = 10) -> [LatencyRecord] {
        queue.sync {
            let endIndex = min(count, latencyHistory.count)
            return Array(latencyHistory.suffix(endIndex))
        }
    }
}
