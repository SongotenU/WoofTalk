import UIKit

// MARK: - TranslationViewDelegate

protocol TranslationViewDelegate: AnyObject {
    func translationViewDidTapTranslate(_ view: TranslationView)
    func translationViewDidTapClear(_ view: TranslationView)
    func translationViewDidTapHistory(_ view: TranslationView)
}

// MARK: - TranslationView

final class TranslationView: UIView {
    
    weak var delegate: TranslationViewDelegate?
    
    private let inputLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let translatedLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .semibold)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.text = "Ready to translate"
        return label
    }()
    
    private let translateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Translate", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        return button
    }()
    
    private let clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Clear", for: .normal)
        button.backgroundColor = .systemGray
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        return button
    }()
    
    private let historyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "clock.arrow.circlepath"), for: .normal)
        button.tintColor = .systemBlue
        return button
    }()
    
    private let audioLevelView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 2
        view.alpha = 0.3
        return view
    }()
    
    private let qualityScoreLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        translateButton.addTarget(self, action: #selector(translateTapped), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        historyButton.addTarget(self, action: #selector(historyTapped), for: .touchUpInside)
        
        let verticalStack = UIStackView(arrangedSubviews: [inputLabel, translatedLabel, qualityScoreLabel, statusLabel])
        verticalStack.axis = .vertical
        verticalStack.spacing = 8
        verticalStack.translatesAutoresizingMaskIntoConstraints = false
        
        let buttonStack = UIStackView(arrangedSubviews: [translateButton, clearButton, historyButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(verticalStack)
        addSubview(buttonStack)
        addSubview(audioLevelView)
        
        NSLayoutConstraint.activate([
            verticalStack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            verticalStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            verticalStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            audioLevelView.topAnchor.constraint(equalTo: verticalStack.bottomAnchor, constant: 10),
            audioLevelView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            audioLevelView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            audioLevelView.heightAnchor.constraint(equalToConstant: 6),
            
            buttonStack.topAnchor.constraint(equalTo: audioLevelView.bottomAnchor, constant: 20),
            buttonStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            buttonStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            buttonStack.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func translateTapped() {
        delegate?.translationViewDidTapTranslate(self)
    }
    
    @objc private func clearTapped() {
        delegate?.translationViewDidTapClear(self)
    }
    
    @objc private func historyTapped() {
        delegate?.translationViewDidTapHistory(self)
    }
    
    // MARK: - Public Methods
    
    func addTranslation(human: String, dog: String) {
        inputLabel.text = human
        translatedLabel.text = dog
    }
    
    func clearTranslations() {
        inputLabel.text = ""
        translatedLabel.text = ""
        statusLabel.text = "Ready to translate"
        qualityScoreLabel.isHidden = true
    }
    
    func showPartialRecognition(_ text: String) {
        statusLabel.text = "Recognizing: \(text)"
    }
    
    func updateAudioLevel(_ level: Float) {
        // Map level (0-1) to alpha or width
        audioLevelView.alpha = CGFloat(level)
    }
    
    func showQualityScore(_ score: TranslationQualityScore) {
        qualityScoreLabel.text = "Quality: \(Int(score.confidence * 100))% (\(score.qualityTier.rawValue))"
        qualityScoreLabel.isHidden = false
    }
}
