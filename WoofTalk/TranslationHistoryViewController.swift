// MARK: - TranslationHistoryViewController

import UIKit

final class TranslationHistoryViewController: UIViewController, TranslationHistoryCellDelegate {
    
    // MARK: - Properties
    private let translationHistory: [TranslationRecord]
    private var tableView: UITableView!
    private let contributionManager: ContributionManager
    private let contributionSyncManager: ContributionSyncManager
    
    init(translationHistory: [TranslationRecord], contributionManager: ContributionManager, contributionSyncManager: ContributionSyncManager) {
        self.translationHistory = translationHistory
        self.contributionManager = contributionManager
        self.contributionSyncManager = contributionSyncManager
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
        cell.configure(with: record, contributionManager: contributionManager, contributionSyncManager: contributionSyncManager)
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

// MARK: - TranslationHistoryCellDelegate

extension TranslationHistoryViewController: TranslationHistoryCellDelegate {
    func translationHistoryCell(_ cell: TranslationHistoryCell, wantsToShow alert: UIAlertController) {
        present(alert, animated: true)
    }
}