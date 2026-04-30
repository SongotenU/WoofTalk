import UIKit

protocol TranslationViewDelegate: AnyObject {
    func translationViewDidTapTranslate(_ view: TranslationView)
    func translationViewDidTapClear(_ view: TranslationView)
    func translationViewDidTapHistory(_ view: TranslationView)
}

final class TranslationView: UIView {

    weak var delegate: TranslationViewDelegate?

    private let inputLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics.default.scaledFont(for: .systemFont(ofSize: 18))
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityLabel = "Input text"
        label.accessibilityTraits = .staticText
        return label
    }()

    private let translatedLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics.default.scaledFont(for: .systemFont(ofSize: 24, weight: .semibold))
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityLabel = "Translated text"
        label.accessibilityTraits = .staticText
        return label
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics.default.scaledFont(for: .systemFont(ofSize: 14))
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.text = "Ready to translate"
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityLabel = "Status"
        label.accessibilityTraits = .staticText
        return label
    }()

    private let translateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Translate", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.accessibilityLabel = "Translate"
        button.accessibilityHint = "Double tap to translate your input"
        button.accessibilityTraits = .button
        return button
    }()

    private let clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Clear", for: .normal)
        button.backgroundColor = .systemGray
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.accessibilityLabel = "Clear"
        button.accessibilityHint = "Double tap to clear input and translation"
        button.accessibilityTraits = .button
        return button
    }()

    private let historyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("History", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.accessibilityLabel = "History"
        button.accessibilityHint = "Double tap to view translation history"
        button.accessibilityTraits = .button
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = .systemBackground

        let stackView = UIStackView(arrangedSubviews: [inputLabel, translatedLabel, statusLabel, translateButton, clearButton, historyButton])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])

        translateButton.addTarget(self, action: #selector(didTapTranslate), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(didTapClear), for: .touchUpInside)
        historyButton.addTarget(self, action: #selector(didTapHistory), for: .touchUpInside)
    }

    func updateInputText(_ text: String) { inputLabel.text = text }
    func updateTranslatedText(_ text: String) { translatedLabel.text = text }
    func updateStatus(_ text: String) { statusLabel.text = text }

    @objc private func didTapTranslate() { delegate?.translationViewDidTapTranslate(self) }
    @objc private func didTapClear() { delegate?.translationViewDidTapClear(self) }
    @objc private func didTapHistory() { delegate?.translationViewDidTapHistory(self) }
}
