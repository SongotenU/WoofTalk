import Foundation

enum ReportFormat: String, CaseIterable {
    case json, csv
}

enum ReportPeriod: String, CaseIterable {
    case daily, weekly, monthly, all

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

    func generateReport(format: ReportFormat, period: ReportPeriod = .daily) throws -> Data {
        let dateRange = period.dateRange
        let report = createReport(period: period, startDate: dateRange.start)

        switch format {
        case .json:
            return try generateJSONReport(report)
        case .csv:
            return try generateCSVReport(report)
        }
    }

    func generateReportURL(format: ReportFormat, period: ReportPeriod = .daily, fileName: String? = nil) throws -> URL {
        let data = try generateReport(format: format, period: period)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let defaultName = "analytics_report_\(dateFormatter.string(from: Date()))"
        let name = (fileName ?? defaultName) + ".\(format.rawValue)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try data.write(to: tempURL)
        return tempURL
    }

    private func createReport(period: ReportPeriod, startDate: Date) -> AnalyticsReport {
        let summary = aggregator.getDashboardSummary(since: startDate)
        let qualityReport = aggregator.getQualityReport(since: startDate)
        let performanceReport = aggregator.getPerformanceReport(since: startDate)
        let usageReport = aggregator.getUsageReport(since: startDate)

        return AnalyticsReport(
            period: period.rawValue,
            generatedAt: Date(),
            summary: summary,
            qualityReport: qualityReport,
            performanceReport: performanceReport,
            usageReport: usageReport
        )
    }

    private func generateJSONReport(_ report: AnalyticsReport) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(report)
    }

    private func generateCSVReport(_ report: AnalyticsReport) throws -> Data {
        var csv = "Metric,Value\n"
        csv += "Total Translations,\(report.summary.translationCount)\n"
        csv += "Average Quality Score,\(String(format: "%.2f", report.summary.averageQualityScore))\n"
        csv += "Average Latency (ms),\(String(format: "%.2f", report.summary.averageLatencyMs))\n"
        csv += "Success Rate,\(String(format: "%.2f", report.summary.successRate))\n"
        csv += "Active Features,\(report.summary.activeFeatures)\n"
        return csv.data(using: .utf8) ?? Data()
    }
}

struct AnalyticsReport: Codable {
    let period: String
    let generatedAt: Date
    let summary: AnalyticsDashboardSummary
    let qualityReport: QualityReport
    let performanceReport: PerformanceReport
    let usageReport: UsageReport
}
