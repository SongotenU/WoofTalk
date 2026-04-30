import UIKit
import SwiftUI
import RevenueCat

final class SettingsViewController: UIViewController {

    private var tableView: UITableView!
    private let settings = Settings.shared

    // Total number of settings rows — update this when adding/removing rows
    private let settingsRowCount = 14

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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsValueCell")
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

extension SettingsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { settingsRowCount }

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
        case 7:
            return subscriptionCell()
        case 8:
            cell.textLabel?.text = "Restore Purchases"
            cell.accessoryType = .disclosureIndicator
        case 9:
            let entitlement = EntitlementManager.shared
            if entitlement.isPremium {
                cell.textLabel?.text = "Manage Subscription"
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.textLabel?.text = ""
                cell.isHidden = true
            }
        case 10:
            cell.textLabel?.text = "Export My Data"
            cell.accessoryType = .disclosureIndicator
            cell.accessibilityLabel = "Export My Data"
            cell.accessibilityHint = "Exports all your personal data in a portable format"
        case 11:
            cell.textLabel?.text = "Delete Account"
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.textColor = .systemRed
            cell.accessibilityLabel = "Delete Account"
            cell.accessibilityHint = "Permanently deletes your account and all associated data"
        case 12:
            if EntitlementManager.shared.isPremium {
                cell.textLabel?.text = "Cancel Subscription"
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.textColor = .systemRed
            } else {
                cell.isHidden = true
            }
        case 13:
            cell.textLabel?.text = "Refer a Friend"
            cell.accessoryType = .disclosureIndicator
        default:
            cell.textLabel?.text = ""
        }
        return cell
    }

    private func subscriptionCell() -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "SettingsValueCell")
        cell.selectionStyle = .none
        cell.textLabel?.text = "Subscription"
        let entitlement = EntitlementManager.shared
        if entitlement.isPremium {
            cell.detailTextLabel?.text = entitlement.isTrialActive ? "Trial" : "Pro"
            cell.detailTextLabel?.textColor = .systemGreen
        } else {
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }

    private func createLatencyThresholdControl() -> UISlider {
        let slider = UISlider()
        slider.minimumValue = 1.0
        slider.maximumValue = 3.0
        slider.value = Float(settings.latencyThreshold)
        slider.addTarget(self, action: #selector(latencyThresholdChanged(_:)), for: .valueChanged)
        slider.accessibilityLabel = "Latency Threshold"
        slider.accessibilityHint = "Adjusts translation latency threshold"
        slider.accessibilityValue = "\(settings.latencyThreshold) seconds"
        return slider
    }

    private func createAudioQualityControl() -> UISegmentedControl {
        let segmented = UISegmentedControl(items: ["Low", "Medium", "High"])
        segmented.selectedSegmentIndex = settings.audioQuality.rawValue
        segmented.addTarget(self, action: #selector(audioQualityChanged(_:)), for: .valueChanged)
        segmented.accessibilityLabel = "Audio Quality"
        segmented.accessibilityHint = "Select audio quality: Low, Medium, or High"
        return segmented
    }

    private func createLanguageControl() -> UISegmentedControl {
        let segmented = UISegmentedControl(items: ["English", "Spanish", "French"])
        segmented.selectedSegmentIndex = 0
        segmented.addTarget(self, action: #selector(languageChanged(_:)), for: .valueChanged)
        segmented.accessibilityLabel = "Translation Language"
        segmented.accessibilityHint = "Select translation language"
        return segmented
    }

    private func createVibrationSwitch() -> UISwitch {
        let toggle = UISwitch()
        toggle.isOn = settings.enableVibration
        toggle.addTarget(self, action: #selector(vibrationChanged(_:)), for: .valueChanged)
        toggle.accessibilityLabel = "Enable Vibration"
        toggle.accessibilityHint = "Toggles vibration feedback"
        return toggle
    }

    private func createTranslationModeControl() -> UISegmentedControl {
        let segmented = UISegmentedControl(items: ["AI", "Rule-Based", "Auto"])
        let modes: [TranslationMode] = [.ai, .ruleBased, .auto]
        if let index = modes.firstIndex(of: settings.translationMode) {
            segmented.selectedSegmentIndex = index
        }
        segmented.addTarget(self, action: #selector(translationModeChanged(_:)), for: .valueChanged)
        segmented.accessibilityLabel = "Translation Mode"
        segmented.accessibilityHint = "Select translation mode: AI, Rule-Based, or Auto"
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

    @objc private func languageChanged(_ sender: UISegmentedControl) {}

    @objc private func vibrationChanged(_ toggle: UISwitch) {
        settings.enableVibration = toggle.isOn
    }
}

// MARK: - UITableViewDelegate

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 60 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 5: showClearHistoryConfirmation()
        case 6: showAbout()
        case 7: presentPaywallIfAllowed()
        case 8: restorePurchases()
        case 9: if EntitlementManager.shared.isPremium { openManageSubscription() }
        case 10: exportUserData()
        case 11: confirmDeleteAccount()
        case 12: if EntitlementManager.shared.isPremium { presentCancellationSurvey() }
        case 13: presentReferralView()
        default: break
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    private func presentPaywallIfAllowed() {
        // Check if auth is still loading before showing "Sign In Required"
        if AuthManager.shared.isLoading {
            presentAlert(title: "Loading", message: "Please wait while we verify your account...")
            return
        }
        guard EntitlementManager.shared.isReadyToAccessPaywall else {
            presentAlert(title: "Sign In Required", message: "Please sign in to manage your subscription.")
            return
        }
        let hostingController = UIHostingController(rootView: PaywallView())
        hostingController.isModalInPresentation = true
        present(hostingController, animated: true) {
            Task {
                await EntitlementManager.shared.refreshEntitlements()
                self.tableView.reloadData()
            }
        }
    }

    private func restorePurchases() {
        Task {
            do {
                _ = try await Purchases.shared.restorePurchases()
                await EntitlementManager.shared.refreshEntitlements()
                tableView.reloadData()
                presentAlert(title: "Purchases Restored", message: "Your subscription has been restored.")
            } catch {
                presentAlert(title: "Restore Failed", message: error.localizedDescription)
            }
        }
    }

    private func openManageSubscription() {
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else { return }
        UIApplication.shared.open(url)
    }

    private func showClearHistoryConfirmation() {
        let alert = UIAlertController(title: "Clear Translation History", message: "This will permanently delete all translation records.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { _ in })
        present(alert, animated: true)
    }

    private func showAbout() {
        navigationController?.pushViewController(AboutViewController(), animated: true)
    }

    private func exportUserData() {
        Task {
            do {
                let data = try await AuthManager.shared.exportUserData()
                let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
                let activityVC = UIActivityViewController(activityItems: [jsonData], applicationActivities: nil)
                present(activityVC, animated: true)
            } catch {
                presentAlert(title: "Export Failed", message: error.localizedDescription)
            }
        }
    }

    private func confirmDeleteAccount() {
        let alert = UIAlertController(title: "Delete Account", message: "This will permanently delete your account and all associated data. This action cannot be undone.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            Task {
                do {
                    try await AuthManager.shared.deleteAccount()
                    presentAlert(title: "Account Deleted", message: "Your account has been successfully deleted.")
                } catch {
                    presentAlert(title: "Deletion Failed", message: error.localizedDescription)
                }
            }
        })
        present(alert, animated: true)
    }

    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func presentCancellationSurvey() {
        let hostingController = UIHostingController(rootView: CancellationSurveyView {
            self.dismiss(animated: true) {
                self.tableView.reloadData()
            }
        })
        present(hostingController, animated: true)
    }

    private func presentReferralView() {
        // For now, show an alert with referral code
        // In production, this would be a proper ReferralView
        guard let userId = AuthManager.shared.currentUser?.id else { return }
        let referralCode = "REF\(userId.prefix(6).uppercased())"
        let alert = UIAlertController(
            title: "Refer a Friend",
            message: "Your referral code: \(referralCode)\nShare this code with friends. When they subscribe, you both get 1 month free.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - AboutViewController

final class AboutViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
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
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }
}
