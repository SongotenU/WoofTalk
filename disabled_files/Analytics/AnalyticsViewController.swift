// MARK: - Analytics View Controller

import UIKit

final class AnalyticsViewController: UIViewController {
    
    // MARK: - Properties
    
    private let analyticsService = TranslationAnalyticsService.shared
    
    private var summary: AnalyticsDashboardSummary?
    private var performanceStats: PerformanceStatistics?
    private var qualityStats: QualityStatistics?
    
    // MARK: - UI Elements
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        return scrollView
    }()
    
    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        return stackView
    }()
    
    private lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Analytics Dashboard"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var translationsCard = createMetricCard(title: "Total Translations", icon: "text.bubble")
    private lazy var qualityCard = createMetricCard(title: "Quality Score", icon: "star.fill")
    private lazy var latencyCard = createMetricCard(title: "Avg Latency", icon: "speedometer")
    private lazy var successRateCard = createMetricCard(title: "Success Rate", icon: "checkmark.circle.fill")
    
    private lazy var refreshButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Refresh", for: .normal)
        button.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var exportButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Export Report", for: .normal)
        button.addTarget(self, action: #selector(exportTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Analytics"
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(customView: exportButton),
            UIBarButtonItem(customView: refreshButton)
        ]
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
        
        contentStackView.addArrangedSubview(headerLabel)
        
        let metricsGrid = createMetricsGrid()
        contentStackView.addArrangedSubview(metricsGrid)
        
        let performanceSection = createPerformanceSection()
        contentStackView.addArrangedSubview(performanceSection)
        
        let qualitySection = createQualitySection()
        contentStackView.addArrangedSubview(qualitySection)
    }
    
    private func createMetricsGrid() -> UIView {
        let gridStack = UIStackView()
        gridStack.axis = .vertical
        gridStack.spacing = 16
        
        let topRow = UIStackView(arrangedSubviews: [translationsCard, qualityCard])
        topRow.axis = .horizontal
        topRow.spacing = 16
        topRow.distribution = .fillEqually
        
        let bottomRow = UIStackView(arrangedSubviews: [latencyCard, successRateCard])
        bottomRow.axis = .horizontal
        bottomRow.spacing = 16
        bottomRow.distribution = .fillEqually
        
        gridStack.addArrangedSubview(topRow)
        gridStack.addArrangedSubview(bottomRow)
        
        return gridStack
    }
    
    private func createMetricCard(title: String, icon: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 12
        
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .systemBlue
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        let valueLabel = UILabel()
        valueLabel.font = .systemFont(ofSize: 24, weight: .bold)
        valueLabel.text = "--"
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.tag = 100
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        card.addSubview(iconView)
        card.addSubview(valueLabel)
        card.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 100),
            
            iconView.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            iconView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            valueLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            valueLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            
            titleLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12)
        ])
        
        return card
    }
    
    private func createPerformanceSection() -> UIView {
        let section = UIView()
        section.backgroundColor = .secondarySystemBackground
        section.layer.cornerRadius = 12
        
        let titleLabel = UILabel()
        titleLabel.text = "Performance"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(createStatRow(label: "Min Latency", valueTag: 201))
        stackView.addArrangedSubview(createStatRow(label: "Max Latency", valueTag: 202))
        stackView.addArrangedSubview(createStatRow(label: "Average", valueTag: 203))
        stackView.addArrangedSubview(createStatRow(label: "P95", valueTag: 204))
        stackView.addArrangedSubview(createStatRow(label: "P99", valueTag: 205))
        
        section.addSubview(titleLabel)
        section.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: section.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: section.leadingAnchor, constant: 16),
            
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: section.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: section.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: section.bottomAnchor, constant: -16)
        ])
        
        return section
    }
    
    private func createQualitySection() -> UIView {
        let section = UIView()
        section.backgroundColor = .secondarySystemBackground
        section.layer.cornerRadius = 12
        
        let titleLabel = UILabel()
        titleLabel.text = "Translation Quality"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(createQualityRow(label: "High Quality", color: .systemGreen, valueTag: 301))
        stackView.addArrangedSubview(createQualityRow(label: "Medium Quality", color: .systemYellow, valueTag: 302))
        stackView.addArrangedSubview(createQualityRow(label: "Low Quality", color: .systemOrange, valueTag: 303))
        stackView.addArrangedSubview(createQualityRow(label: "Very Low", color: .systemRed, valueTag: 304))
        
        section.addSubview(titleLabel)
        section.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: section.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: section.leadingAnchor, constant: 16),
            
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: section.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: section.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: section.bottomAnchor, constant: -16)
        ])
        
        return section
    }
    
    private func createStatRow(label: String, valueTag: Int) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .equalSpacing
        
        let labelView = UILabel()
        labelView.text = label
        labelView.textColor = .secondaryLabel
        
        let valueView = UILabel()
        valueView.text = "--"
        valueView.tag = valueTag
        
        row.addArrangedSubview(labelView)
        row.addArrangedSubview(valueView)
        
        return row
    }
    
    private func createQualityRow(label: String, color: UIColor, valueTag: Int) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        
        let dot = UIView()
        dot.backgroundColor = color
        dot.layer.cornerRadius = 4
        dot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: 8),
            dot.heightAnchor.constraint(equalToConstant: 8)
        ])
        
        let labelView = UILabel()
        labelView.text = label
        labelView.textColor = .secondaryLabel
        
        let valueView = UILabel()
        valueView.text = "0"
        valueView.tag = valueTag
        
        row.addArrangedSubview(dot)
        row.addArrangedSubview(labelView)
        
        let spacer = UIView()
        row.addArrangedSubview(spacer)
        
        row.addArrangedSubview(valueView)
        
        return row
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        summary = analyticsService.getDashboardSummary()
        
        let aggregator = analyticsService.aggregator
        performanceStats = aggregator.getPerformanceReport().statistics
        qualityStats = aggregator.getQualityReport().statistics
        
        updateUI()
    }
    
    private func updateUI() {
        if let valueLabel = translationsCard.viewWithTag(100) as? UILabel {
            valueLabel.text = "\(summary?.translationCount ?? 0)"
        }
        
        if let valueLabel = qualityCard.viewWithTag(100) as? UILabel {
            valueLabel.text = String(format: "%.0f%%", (summary?.averageQualityScore ?? 0) * 100)
        }
        
        if let valueLabel = latencyCard.viewWithTag(100) as? UILabel {
            valueLabel.text = String(format: "%.0fms", summary?.averageLatencyMs ?? 0)
        }
        
        if let valueLabel = successRateCard.viewWithTag(100) as? UILabel {
            valueLabel.text = String(format: "%.1f%%", summary?.successRate ?? 0)
        }
        
        if let valueLabel = contentStackView.viewWithTag(201) as? UILabel {
            valueLabel.text = String(format: "%.0fms", performanceStats?.minLatencyMs ?? 0)
        }
        if let valueLabel = contentStackView.viewWithTag(202) as? UILabel {
            valueLabel.text = String(format: "%.0fms", performanceStats?.maxLatencyMs ?? 0)
        }
        if let valueLabel = contentStackView.viewWithTag(203) as? UILabel {
            valueLabel.text = String(format: "%.0fms", performanceStats?.averageLatencyMs ?? 0)
        }
        if let valueLabel = contentStackView.viewWithTag(204) as? UILabel {
            valueLabel.text = String(format: "%.0fms", performanceStats?.p95LatencyMs ?? 0)
        }
        if let valueLabel = contentStackView.viewWithTag(205) as? UILabel {
            valueLabel.text = String(format: "%.0fms", performanceStats?.p99LatencyMs ?? 0)
        }
        
        if let valueLabel = contentStackView.viewWithTag(301) as? UILabel {
            valueLabel.text = "\(qualityStats?.highQualityCount ?? 0)"
        }
        if let valueLabel = contentStackView.viewWithTag(302) as? UILabel {
            valueLabel.text = "\(qualityStats?.mediumQualityCount ?? 0)"
        }
        if let valueLabel = contentStackView.viewWithTag(303) as? UILabel {
            valueLabel.text = "\(qualityStats?.lowQualityCount ?? 0)"
        }
        if let valueLabel = contentStackView.viewWithTag(304) as? UILabel {
            valueLabel.text = "\(qualityStats?.veryLowQualityCount ?? 0)"
        }
    }
    
    // MARK: - Actions
    
    @objc private func refreshTapped() {
        loadData()
    }
    
    @objc private func exportTapped() {
        let alert = UIAlertController(title: "Export Report", message: "Choose report format", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "JSON", style: .default) { [weak self] _ in
            self?.exportReport(format: .json)
        })
        
        alert.addAction(UIAlertAction(title: "CSV", style: .default) { [weak self] _ in
            self?.exportReport(format: .csv)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = exportButton
            popover.sourceRect = exportButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func exportReport(format: ReportFormat) {
        do {
            let url = try analyticsService.generateReportURL(format: format, period: .daily)
            
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = exportButton
                popover.sourceRect = exportButton.bounds
            }
            
            present(activityVC, animated: true)
        } catch {
            let alert = UIAlertController(title: "Error", message: "Failed to export report: \(error.localizedDescription)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
}
