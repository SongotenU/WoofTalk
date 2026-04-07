// MARK: - Analytics Report Generator

import Foundation

enum ReportFormat: String, CaseIterable {
    case json = "json"
    case csv = "csv"
}

enum ReportPeriod: String, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case all = "all"
    
    var dateRange: (start: Date, end: Date) {
        let now = Date()
        let calendar = Calendar.current
        
        switch self {
        case .daily:
            return (calendar.date(byAdding: .day, value: -1, to: now) ?? now, now)
        case .weekly:
            return (calendar.date(byAdding: .day, value: -7, to: now) ?? now, now)
        case .monthly:
            return (calendar.date(byAdding: .month, value: -1, to: now) ?? now, now)
        case .all:
            return (Date.distantPast, now)
        }
    }
}

final class AnalyticsReportGenerator {
    
    private let aggregator: AnalyticsAggregator
    
    init(aggregator: AnalyticsAggregator) {
        self.aggregator = aggregator
    }
    
    // MARK: - Report Generation
    
    func generateReport(
        format: ReportFormat,
        period: ReportPeriod = .daily
    ) throws -> Data {
        let dateRange = period.dateRange
        let report = createReport(period: period, startDate: dateRange.start)
        
        switch format {
        case .json:
            return try generateJSONReport(report)
        case .csv:
            return try generateCSVReport(report)
        }
    }
    
    func generateReportURL(
        format: ReportFormat,
        period: ReportPeriod = .daily,
        fileName: String? = nil
    ) throws -> URL {
        let data = try generateReport(format: format, period: period)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        let name = fileName ?? "analytics_\(period.rawValue)_\(dateString)"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("\(name).\(format.rawValue)")
        
        try data.write(to: fileURL)
        return fileURL
    }
    
    // MARK: - Private Methods
    
    private func createReport(period: ReportPeriod, startDate: Date) -> ComprehensiveReport {
        let qualityReport = aggregator.getQualityReport(since: startDate)
        let performanceReport = aggregator.getPerformanceReport(since: startDate)
        let usageReport = aggregator.getUsageReport()
        let summary = aggregator.getDashboardSummary(since: startDate)
        
        return ComprehensiveReport(
            period: period.rawValue,
            summary: summary,
            quality: qualityReport,
            performance: performanceReport,
            usage: usageReport,
            generatedAt: Date()
        )
    }
    
    private func generateJSONReport(_ report: ComprehensiveReport) throws -> Data {
        var json: [String: Any] = [:]
        
        json["period"] = report.period
        json["generatedAt"] = ISO8601DateFormatter().string(from: report.generatedAt)
        
        json["summary"] = [
            "translationCount": report.summary.translationCount,
            "averageQualityScore": report.summary.averageQualityScore,
            "averageLatencyMs": report.summary.averageLatencyMs,
            "successRate": report.summary.successRate,
            "activeFeatures": report.summary.activeFeatures
        ]
        
        json["quality"] = [
            "totalTranslations": report.quality.statistics.totalTranslations,
            "averageConfidence": report.quality.statistics.averageConfidence,
            "averageAccuracy": report.quality.statistics.averageAccuracy,
            "highQualityCount": report.quality.statistics.highQualityCount,
            "mediumQualityCount": report.quality.statistics.mediumQualityCount,
            "lowQualityCount": report.quality.statistics.lowQualityCount
        ]
        
        json["performance"] = [
            "totalTranslations": report.performance.statistics.totalTranslations,
            "successRate": report.performance.statistics.successRate,
            "minLatencyMs": report.performance.statistics.minLatencyMs,
            "maxLatencyMs": report.performance.statistics.maxLatencyMs,
            "averageLatencyMs": report.performance.statistics.averageLatencyMs,
            "p95LatencyMs": report.performance.statistics.p95LatencyMs,
            "p99LatencyMs": report.performance.statistics.p99LatencyMs
        ]
        
        var featuresJson: [[String: Any]] = []
        for feature in report.usage.topFeatures {
            featuresJson.append([
                "featureName": feature.featureName,
                "usageCount": feature.usageCount
            ])
        }
        json["usage"] = [
            "topFeatures": featuresJson,
            "totalTranslations": report.usage.totalTranslations,
            "weeklyUsage": report.usage.weeklyUsage,
            "monthlyUsage": report.usage.monthlyUsage
        ]
        
        return try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
    }
    
    private func generateCSVReport(_ report: ComprehensiveReport) throws -> Data {
        var csvContent = "Analytics Report - \(report.period)\n"
        csvContent += "Generated:,\(report.generatedAt.ISO8601Format())\n\n"
        
        csvContent += "SUMMARY\n"
        csvContent += "Metric,Value\n"
        csvContent += "Total Translations,\(report.summary.translationCount)\n"
        csvContent += "Average Quality Score,\(String(format: "%.2f", report.summary.averageQualityScore))\n"
        csvContent += "Average Latency (ms),\(String(format: "%.2f", report.summary.averageLatencyMs))\n"
        csvContent += "Success Rate,%,\(String(format: "%.1f", report.summary.successRate))\n"
        csvContent += "Active Features,\(report.summary.activeFeatures)\n\n"
        
        csvContent += "QUALITY STATISTICS\n"
        csvContent += "Metric,Value\n"
        csvContent += "Total Translations,\(report.quality.statistics.totalTranslations)\n"
        csvContent += "Average Confidence,\(String(format: "%.2f", report.quality.statistics.averageConfidence))\n"
        csvContent += "Average Accuracy,\(String(format: "%.2f", report.quality.statistics.averageAccuracy))\n"
        csvContent += "High Quality Count,\(report.quality.statistics.highQualityCount)\n"
        csvContent += "Medium Quality Count,\(report.quality.statistics.mediumQualityCount)\n"
        csvContent += "Low Quality Count,\(report.quality.statistics.lowQualityCount)\n\n"
        
        csvContent += "PERFORMANCE STATISTICS\n"
        csvContent += "Metric,Value\n"
        csvContent += "Total Translations,\(report.performance.statistics.totalTranslations)\n"
        csvContent += "Success Rate,%,\(String(format: "%.1f", report.performance.statistics.successRate))\n"
        csvContent += "Min Latency (ms),\(String(format: "%.2f", report.performance.statistics.minLatencyMs))\n"
        csvContent += "Max Latency (ms),\(String(format: "%.2f", report.performance.statistics.maxLatencyMs))\n"
        csvContent += "Average Latency (ms),\(String(format: "%.2f", report.performance.statistics.averageLatencyMs))\n"
        csvContent += "P95 Latency (ms),\(String(format: "%.2f", report.performance.statistics.p95LatencyMs))\n"
        csvContent += "P99 Latency (ms),\(String(format: "%.2f", report.performance.statistics.p99LatencyMs))\n\n"
        
        csvContent += "USAGE STATISTICS\n"
        csvContent += "Feature,Usage Count\n"
        for feature in report.usage.topFeatures {
            csvContent += "\(feature.featureName),\(feature.usageCount)\n"
        }
        
        return csvContent.data(using: .utf8) ?? Data()
    }
}

// MARK: - Comprehensive Report

struct ComprehensiveReport {
    let period: String
    let summary: AnalyticsDashboardSummary
    let quality: QualityReport
    let performance: PerformanceReport
    let usage: UsageReport
    let generatedAt: Date
}
