// MARK: - SettingsViewController

import UIKit
import TranslationModeManager  // Not needed if same target, but safe

final class SettingsViewController: UIViewController {
    
    private var tableView: UITableView!
    private var settings = Settings.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Settings"
        
        tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")
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

extension SettingsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
        cell.selectionStyle = .none
        
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Latency Threshold"
            cell.accessoryView = createLatencyThresholdControl()
        case 1:
            cell.textLabel?.text = "Audio Quality"
            cell.accessoryView = createAudioQualityControl()
        case 2:
            cell.textLabel?.text = "Translation Language"
            cell.accessoryView = createLanguageControl()
        case 3:
            cell.textLabel?.text = "Translation Mode"
            cell.accessoryView = createTranslationModeControl()
        case 4:
            cell.textLabel?.text = "Enable Vibration"
            cell.accessoryView = createVibrationSwitch()
        case 5:
            cell.textLabel?.text = "Clear History"
            cell.accessoryType = .disclosureIndicator
        case 6:
            cell.textLabel?.text = "About"
            cell.accessoryType = .disclosureIndicator
        default:
            cell.textLabel?.text = ""
        }
        
        return cell
    }
    
    private func createLatencyThresholdControl() -> UIView {
        let slider = UISlider()
        slider.minimumValue = 1.0
        slider.maximumValue = 3.0
        slider.value = Float(settings.latencyThreshold)
        slider.addTarget(self, action: #selector(latencyThresholdChanged(_:)), for: .valueChanged)
        return slider
    }
    
    private func createAudioQualityControl() -> UIView {
        let segmented = UISegmentedControl(items: ["Low", "Medium", "High"])
        segmented.selectedSegmentIndex = settings.audioQuality.rawValue
        segmented.addTarget(self, action: #selector(audioQualityChanged(_:)), for: .valueChanged)
        return segmented
    }
    
    private func createLanguageControl() -> UIView {
        let segmented = UISegmentedControl(items: ["English", "Spanish", "French"])
        segmented.selectedSegmentIndex = 0 // Default to English
        segmented.addTarget(self, action: #selector(languageChanged(_:)), for: .valueChanged)
        return segmented
    }
    
    private func createVibrationSwitch() -> UIView {
        let toggle = UISwitch()
        toggle.isOn = settings.enableVibration
        toggle.addTarget(self, action: #selector(vibrationChanged(_:)), for: .valueChanged)
        return toggle
    }
    
    private func createTranslationModeControl() -> UIView {
        let segmented = UISegmentedControl(items: ["AI", "Rule-Based", "Auto"])
        // Find the current mode's index
        let modes: [TranslationMode] = [.ai, .ruleBased, .auto]
        if let index = modes.firstIndex(of: settings.translationMode) {
            segmented.selectedSegmentIndex = index
        } else {
            segmented.selectedSegmentIndex = 1 // Default to Rule-Based if not found
        }
        segmented.addTarget(self, action: #selector(translationModeChanged(_:)), for: .valueChanged)
        return segmented
    }
    
    @objc private func latencyThresholdChanged(_ sender: UISlider) {
        settings.latencyThreshold = Double(sender.value)
    }
    
    @objc private func audioQualityChanged(_ sender: UISegmentedControl) {
        settings.audioQuality = AudioQuality(rawValue: sender.selectedSegmentIndex) ?? .medium
    }
    
    @objc private func translationModeChanged(_ sender: UISegmentedControl) {
        let modes: [TranslationMode] = [.ai, .ruleBased, .auto]
        if sender.selectedSegmentIndex < modes.count {
            settings.translationMode = modes[sender.selectedSegmentIndex]
        }
    }
    
    @objc private func languageChanged(_ sender: UISegmentedControl) {
        // Handle language change
    }
    
    @objc private func vibrationChanged(_ toggle: UISwitch) {
        settings.enableVibration = toggle.isOn
    }
}

// MARK: - UITableViewDelegate

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case 4:
            showClearHistoryConfirmation()
        case 5:
            showAbout()
        default:
            break
        }
    }
    
    private func showClearHistoryConfirmation() {
        let alert = UIAlertController(
            title: "Clear Translation History",
            message: "This will permanently delete all translation records.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { _ in
            // Clear history logic
        })
        present(alert, animated: true)
    }
    
    private func showAbout() {
        let aboutVC = AboutViewController()
        navigationController?.pushViewController(aboutVC, animated: true)
    }
}

// MARK: - AboutViewController

final class AboutViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "About"
        
        let titleLabel = UILabel()
        titleLabel.text = "WoofTalk"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        
        let versionLabel = UILabel()
        versionLabel.text = "Version 1.0.0"
        versionLabel.font = .systemFont(ofSize: 16)
        versionLabel.textAlignment = .center
        versionLabel.textColor = .secondaryLabel
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = "Real-time dog translation app with offline capability"
        descriptionLabel.font = .systemFont(ofSize: 16)
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = .secondaryLabel
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, versionLabel, descriptionLabel])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .center
        
        view.addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }
}

// MARK: - Settings

final class Settings {
    static let shared = Settings()
    
    var latencyThreshold: Double = 2.0
    var audioQuality: AudioQuality = .medium
    var enableVibration: Bool = true
    var targetLanguage: String = "Dog"
}

enum AudioQuality: Int {
    case low = 0
    case medium = 1
    case high = 2
}