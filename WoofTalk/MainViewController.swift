import UIKit

class MainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "WoofTalk"

        let label = UILabel()
        label.text = "WoofTalk - Dog Translation App"
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .largeTitle)
        label.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Tap Record to start translating your dog's barks"
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let recordButton = UIButton(type: .system)
        recordButton.setTitle("Record", for: .normal)
        recordButton.titleLabel?.font = .preferredFont(forTextStyle: .title1)
        recordButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)
        view.addSubview(subtitleLabel)
        view.addSubview(recordButton)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),

            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),

            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 30)
        ])
    }
}
