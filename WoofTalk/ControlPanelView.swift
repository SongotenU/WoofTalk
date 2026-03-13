// MARK: - ControlPanelView

import UIKit

final class ControlPanelView: UIView {
    
    weak var delegate: ControlPanelViewDelegate?
    
    private let translateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Translate", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(translateButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private let statusStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(translateButton)
        addSubview(statusStackView)
        
        translateButton.translatesAutoresizingMaskIntoConstraints = false
        statusStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            translateButton.topAnchor.constraint(equalTo: topAnchor),
            translateButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            translateButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            translateButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        NSLayoutConstraint.activate([
            statusStackView.topAnchor.constraint(equalTo: translateButton.bottomAnchor, constant: 12),
            statusStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            statusStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            statusStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        setupStatusIndicators()
    }
    
    private func setupStatusIndicators() {
        let readyIndicator = createStatusIndicator(title: "Ready", color: .systemGreen)
        let activeIndicator = createStatusIndicator(title: "Active", color: .systemBlue)
        let latencyIndicator = createStatusIndicator(title: "Latency", color: .systemGray)
        
        statusStackView.addArrangedSubview(readyIndicator)
        statusStackView.addArrangedSubview(activeIndicator)
        statusStackView.addArrangedSubview(latencyIndicator)
    }
    
    private func createStatusIndicator(title: String, color: UIColor) -> UIView {
        let container = UIView()
        
        let circleView = UIView()
        circleView.backgroundColor = color
        circleView.layer.cornerRadius = 4
        circleView.clipsToBounds = true
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 10)
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center
        
        let stackView = UIStackView(arrangedSubviews: [circleView, titleLabel])
        stackView.axis = .vertical
        stackView.spacing = 2
        
        container.addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        circleView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            circleView.widthAnchor.constraint(equalToConstant: 8),
            circleView.heightAnchor.constraint(equalToConstant: 8)
        ])
        
        return container
    }
    
    func setTranslateButton(enabled: Bool) {
        translateButton.isEnabled = enabled
        translateButton.alpha = enabled ? 1.0 : 0.6
    }
    
    func setTranslateButton(title: String, color: UIColor) {
        translateButton.setTitle(title, for: .normal)
        translateButton.backgroundColor = color
    }
    
    func setReadyIndicator(active: Bool) {
        updateIndicator(at: 0, active: active)
    }
    
    func setActiveIndicator(active: Bool) {
        updateIndicator(at: 1, active: active)
    }
    
    func setLatencyIndicator(color: UIColor) {
        if let indicator = statusStackView.arrangedSubviews[2].subviews.first as? UIView {
            indicator.backgroundColor = color
        }
    }
    
    private func updateIndicator(at index: Int, active: Bool) {
        if let indicator = statusStackView.arrangedSubviews[index].subviews.first as? UIView {
            indicator.backgroundColor = active ? .systemGreen : .systemGray
        }
    }
    
    @objc private func translateButtonTapped() {
        delegate?.controlPanelDidTapTranslate(self)
    }
}