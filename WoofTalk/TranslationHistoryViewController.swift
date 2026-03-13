// MARK: - TranslationHistoryViewController

import UIKit

final class TranslationHistoryViewController: UIViewController {
    
    private let translationHistory: [TranslationRecord]
    private var tableView: UITableView!
    
    init(translationHistory: [TranslationRecord]) {
        self.translationHistory = translationHistory
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Translation History"
        
        tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TranslationHistoryCell.self, forCellReuseIdentifier: "HistoryCell")
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)
    }
    
    private func setupConstraints() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - UITableViewDataSource

extension TranslationHistoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return translationHistory.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as! TranslationHistoryCell
        let record = translationHistory[indexPath.row]
        cell.configure(with: record)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension TranslationHistoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - TranslationHistoryCell

final class TranslationHistoryCell: UITableViewCell {
    
    private let humanTextLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 2
        return label
    }()
    
    private let dogTranslationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 2
        label.textColor = .systemBlue
        return label
    }()
    
    private let timestampLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let latencyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .right
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        
        let stackView = UIStackView(arrangedSubviews: [humanTextLabel, dogTranslationLabel, timestampLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        
        let rightStack = UIStackView(arrangedSubviews: [latencyLabel])
        rightStack.axis = .vertical
        rightStack.alignment = .trailing
        
        let container = UIStackView(arrangedSubviews: [stackView, rightStack])
        container.spacing = 16
        container.alignment = .top
        
        contentView.addSubview(container)
        
        container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with record: TranslationRecord) {
        humanTextLabel.text = "Human: \(record.humanText)"
        dogTranslationLabel.text = "Dog: \(record.dogTranslation)"
        timestampLabel.text = formatTimestamp(record.timestamp)
        latencyLabel.text = String(format: "%.1f s", record.latency)
        
        // Color latency based on performance
        if record.latency < 1.0 {
            latencyLabel.textColor = .systemGreen
        } else if record.latency < 2.0 {
            latencyLabel.textColor = .systemOrange
        } else {
            latencyLabel.textColor = .systemRed
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}