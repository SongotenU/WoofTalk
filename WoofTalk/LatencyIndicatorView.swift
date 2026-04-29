// MARK: - LatencyIndicatorView

import UIKit

final class LatencyIndicatorView: UIView {

    private let colorIndicator: UIView
    private let latencyLabel: UILabel
    private let unitLabel: UILabel

    override init(frame: CGRect) {
        colorIndicator = UIView()
        colorIndicator.backgroundColor = .systemGreen
        colorIndicator.layer.cornerRadius = 2
        colorIndicator.clipsToBounds = true

        latencyLabel = UILabel()
        latencyLabel.font = .systemFont(ofSize: 12, weight: .medium)
        latencyLabel.textAlignment = .center

        unitLabel = UILabel()
        unitLabel.text = "s"
        unitLabel.font = .systemFont(ofSize: 10)
        unitLabel.textAlignment = .center
        unitLabel.textColor = .secondaryLabel

        super.init(frame: frame)

        backgroundColor = .systemGray6
        layer.cornerRadius = 8
        clipsToBounds = true

        [colorIndicator, latencyLabel, unitLabel].forEach { addSubview($0) }

        colorIndicator.translatesAutoresizingMaskIntoConstraints = false
        latencyLabel.translatesAutoresizingMaskIntoConstraints = false
        unitLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            colorIndicator.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            colorIndicator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            colorIndicator.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            colorIndicator.heightAnchor.constraint(equalToConstant: 4),

            latencyLabel.topAnchor.constraint(equalTo: colorIndicator.bottomAnchor, constant: 2),
            latencyLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            unitLabel.topAnchor.constraint(equalTo: latencyLabel.bottomAnchor),
            unitLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateLatency(_ latency: TimeInterval) {
        latencyLabel.text = String(format: "%.1f", latency)
        colorIndicator.backgroundColor = {
            switch latency {
            case ..<0.5: return .systemGreen
            case ..<1.0: return .systemYellow
            case ..<2.0: return .systemOrange
            default: return .systemRed
            }
        }()
    }
}
