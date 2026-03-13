// MARK: - HelpViewController

import UIKit

final class HelpViewController: UIViewController {
    
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Help & Tips"
        
        scrollView = UIScrollView()
        view.addSubview(scrollView)
        
        contentView = UIView()
        scrollView.addSubview(contentView)
        
        setupHelpContent()
    }
    
    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupHelpContent() {
        let titleLabel = UILabel()
        titleLabel.text = "How to Use WoofTalk"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        
        let sections = createHelpSections()
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel] + sections)
        stackView.axis = .vertical
        stackView.spacing = 32
        stackView.alignment = .fill
        
        contentView.addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func createHelpSections() -> [UIView] {
        return [
            createFeatureSection(
                title: "Real-time Translation",
                description: "Speak naturally and WoofTalk will translate your words into dog vocalizations in real-time. The app processes audio continuously and provides translation with minimal latency."
            ),
            createFeatureSection(
                title: "Audio Level Feedback",
                description: "The audio level indicator shows the intensity of your voice. This helps you understand when the app is actively processing your speech and ensures optimal translation quality."
            ),
            createFeatureSection(
                title: "Latency Indicator",
                description: "The latency indicator shows how long it takes to process and translate your speech. Green means excellent performance (<1s), orange is acceptable (1-2s), and red indicates slow performance (>2s)."
            ),
            createFeatureSection(
                title: "Translation History",
                description: "All translations are automatically saved in your history. You can view past translations, see the original text and dog vocalization, and check the processing latency for each translation."
            ),
            createFeatureSection(
                title: "Settings",
                description: "Customize your experience by adjusting latency thresholds, audio quality, and vibration feedback. These settings help optimize performance based on your device capabilities and preferences."
            ),
            createFeatureSection(
                title: "Tips for Best Results",
                description: "For optimal translation quality: speak clearly and at a normal pace, minimize background noise, ensure good microphone access, and keep your device charged for continuous use."
            )
        ]
    }
    
    private func createFeatureSection(title: String, description: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = description
        descriptionLabel.font = .systemFont(ofSize: 15)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = .secondaryLabel
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        stackView.axis = .vertical
        stackView.spacing = 8
        
        return stackView
    }
}