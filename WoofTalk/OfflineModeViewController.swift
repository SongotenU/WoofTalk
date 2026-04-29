import UIKit

class OfflineModeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Offline Mode"
        setupOfflineLabel()
    }

    private func setupOfflineLabel() {
        let offlineLabel = UILabel()
        offlineLabel.text = "Offline Mode\n\nYou can view and manage your translation history and cached translations when offline."
        offlineLabel.numberOfLines = 0
        offlineLabel.textAlignment = .center
        offlineLabel.font = .preferredFont(forTextStyle: .title1)
        view.addSubview(offlineLabel)
        offlineLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            offlineLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            offlineLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            offlineLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            offlineLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
}
