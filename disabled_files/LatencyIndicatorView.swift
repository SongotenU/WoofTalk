// MARK: - LatencyIndicatorView

import UIKit

final class LatencyIndicatorView: UIView {
    
    private let colorIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGreen
        view.layer.cornerRadius = 2
        view.clipsToBounds = true
        return view
    }()
    
    private let latencyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    private let unitLabel: UILabel = {
        let label = UILabel()
        label.text = "s"
        label.font = .systemFont(ofSize: 10)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .systemGray6
        layer.cornerRadius = 8
        clipsToBounds = true
        
        addSubview(colorIndicator)
        addSubview(latencyLabel)
        addSubview(unitLabel)
        
        colorIndicator.translatesAutoresizingMaskIntoConstraints = false
        latencyLabel.translatesAutoresizingMaskIntoConstraints = false
        unitLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            colorIndicator.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            colorIndicator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            colorIndicator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            colorIndicator.heightAnchor.constraint(equalToConstant: 4)
        ])
        
        NSLayoutConstraint.activate([
            latencyLabel.topAnchor.constraint(equalTo: colorIndicator.bottomAnchor, constant: 2),
            latencyLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
        
        NSLayoutConstraint.activate([
            unitLabel.topAnchor.constraint(equalTo: latencyLabel.bottomAnchor),
            unitLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }
    
    func updateLatency(_ latency: TimeInterval) {
        latencyLabel.text = String(format: "%.1f", latency)
    }
    
    var color: UIColor = .systemGreen {
        didSet {
            colorIndicator.backgroundColor = color
            latencyLabel.textColor = color
        }
    }
}