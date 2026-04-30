import UIKit

final class AnalyticsViewController: UIViewController {
    private let analyticsService = TranslationAnalyticsService.shared
    private var summary: AnalyticsDashboardSummary?

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private lazy var contentStack: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.spacing = 20
        return sv
    }()

    private let headerLabel: UILabel = {
        let l = UILabel()
        l.text = "Analytics Dashboard"
        l.font = .systemFont(ofSize: 28, weight: .bold)
        l.textAlignment = .center
        return l
    }()

    private lazy var translationsCard = metricCard(title: "Total Translations", icon: "text.bubble")
    private lazy var qualityCard = metricCard(title: "Quality Score", icon: "star.fill")
    private lazy var latencyCard = metricCard(title: "Avg Latency", icon: "speedometer")
    private lazy var successRateCard = metricCard(title: "Success Rate", icon: "checkmark.circle.fill")

    private lazy var refreshButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Refresh", for: .normal)
        b.addTarget(self, action: #selector(refresh), for: .touchUpInside)
        return b
    }()

    private lazy var exportButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Export", for: .normal)
        b.addTarget(self, action: #selector(exportReport), for: .touchUpInside)
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Analytics"
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(customView: exportButton),
            UIBarButtonItem(customView: refreshButton)
        ]
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
        contentStack.addArrangedSubview(headerLabel)
        contentStack.addArrangedSubview(metricsGrid())
        contentStack.addArrangedSubview(performanceSection())
        contentStack.addArrangedSubview(qualitySection())
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }

    private func metricsGrid() -> UIStackView {
        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 16
        let top = UIStackView(arrangedSubviews: [translationsCard, qualityCard])
        top.axis = .horizontal; top.spacing = 16; top.distribution = .fillEqually
        let bottom = UIStackView(arrangedSubviews: [latencyCard, successRateCard])
        bottom.axis = .horizontal; bottom.spacing = 16; bottom.distribution = .fillEqually
        grid.addArrangedSubview(top)
        grid.addArrangedSubview(bottom)
        return grid
    }

    private func metricCard(title: String, icon: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 12
        let iv = UIImageView(image: UIImage(systemName: icon))
        iv.tintColor = .systemBlue
        iv.translatesAutoresizingMaskIntoConstraints = false
        let value = UILabel()
        value.font = .systemFont(ofSize: 24, weight: .bold)
        value.text = "--"
        value.translatesAutoresizingMaskIntoConstraints = false
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(iv); card.addSubview(value); card.addSubview(label)
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 100),
            iv.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            iv.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            iv.widthAnchor.constraint(equalToConstant: 24), iv.heightAnchor.constraint(equalToConstant: 24),
            value.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            value.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12)
        ])
        return card
    }

    private func performanceSection() -> UIView {
        sectionView(title: "Performance", rows: [
            ("Min Latency", nil), ("Max Latency", nil), ("Average", nil), ("P95", nil), ("P99", nil)
        ])
    }

    private func qualitySection() -> UIView {
        sectionView(title: "Translation Quality", rows: [
            ("High Quality", UIColor.systemGreen), ("Medium Quality", UIColor.systemYellow),
            ("Low Quality", UIColor.systemOrange), ("Very Low", UIColor.systemRed)
        ])
    }

    private func sectionView(title: String, rows: [(String, UIColor?)]) -> UIView {
        let section = UIView()
        section.backgroundColor = .secondarySystemBackground
        section.layer.cornerRadius = 12
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        let stack = UIStackView()
        stack.axis = .vertical; stack.spacing = 8; stack.translatesAutoresizingMaskIntoConstraints = false
        for (label, color) in rows {
            stack.addArrangedSubview(color != nil ? qualityRow(label: label, color: color!) : statRow(label: label))
        }
        section.addSubview(titleLabel); section.addSubview(stack)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: section.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: section.leadingAnchor, constant: 16),
            stack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: section.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: section.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: section.bottomAnchor, constant: -16)
        ])
        return section
    }

    private func statRow(label: String) -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal; row.distribution = .equalSpacing
        row.addArrangedSubview(UILabel().withText(label, color: .secondaryLabel))
        row.addArrangedSubview(UILabel().withText("--"))
        return row
    }

    private func qualityRow(label: String, color: UIColor) -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal; row.spacing = 8
        let dot = UIView()
        dot.backgroundColor = color
        dot.layer.cornerRadius = 4
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.widthAnchor.constraint(equalToConstant: 8).isActive = true
        dot.heightAnchor.constraint(equalToConstant: 8).isActive = true
        row.addArrangedSubview(dot)
        row.addArrangedSubview(UILabel().withText(label, color: .secondaryLabel))
        row.addArrangedSubview(UIView())
        row.addArrangedSubview(UILabel().withText("0"))
        return row
    }

    private func loadData() {
        summary = analyticsService.getDashboardSummary()
        updateUI()
    }

    private func updateUI() {
        let agg = analyticsService.aggregator
        let perf = agg.getPerformanceReport().statistics
        let qual = agg.getQualityReport().statistics

        let cards = [translationsCard, qualityCard, latencyCard, successRateCard]
        let values: [String] = [
            "\(summary?.translationCount ?? 0)",
            String(format: "%.0f%%", (summary?.averageQualityScore ?? 0) * 100),
            String(format: "%.0fms", summary?.averageLatencyMs ?? 0),
            String(format: "%.1f%%", summary?.successRate ?? 0)
        ]
        for (card, val) in zip(cards, values) {
            (card.subviews.compactMap { $0 as? UILabel }.first)?.text = val
        }
    }

    @objc private func refresh() { loadData() }

    @objc private func exportReport() {
        let alert = UIAlertController(title: "Export Report", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "JSON", style: .default) { [weak self] _ in self?.doExport(.json) })
        alert.addAction(UIAlertAction(title: "CSV", style: .default) { [weak self] _ in self?.doExport(.csv) })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let pop = alert.popoverPresentationController { pop.sourceView = exportButton; pop.sourceRect = exportButton.bounds }
        present(alert, animated: true)
    }

    private func doExport(_ format: ReportFormat) {
        do {
            let url = try analyticsService.generateReportURL(format: format, period: .daily)
            let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            if let pop = vc.popoverPresentationController { pop.sourceView = exportButton; pop.sourceRect = exportButton.bounds }
            present(vc, animated: true)
        } catch {
            let alert = UIAlertController(title: "Error", message: "Export failed: \(error.localizedDescription)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
}

extension UILabel {
    func withText(_ text: String, color: UIColor? = nil) -> UILabel {
        self.text = text
        if let color = color { self.textColor = color }
        return self
    }
}
