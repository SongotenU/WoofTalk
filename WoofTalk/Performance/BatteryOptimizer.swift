import Foundation
import UIKit

/// Monitors battery state and optimizes app behavior for low power situations
final class BatteryOptimizer {

    static let shared = BatteryOptimizer()

    private var displayLink: CADisplayLink?
    private var isMonitoring = false
    private(set) var currentStrategy: PowerStrategy = .normal

    private init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        checkBatteryState()
    }

    /// Start monitoring battery state
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        NotificationCenter.default.addObserver(self, selector: #selector(batteryStateChanged), name: UIDevice.batteryStateDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(batteryLevelChanged), name: UIDevice.batteryLevelDidChangeNotification, object: nil)
        displayLink = CADisplayLink(target: self, selector: #selector(checkBatteryState))
        displayLink?.preferredFramesPerSecond = 1
    }

    /// Stop monitoring
    func stopMonitoring() {
        isMonitoring = false
        displayLink?.invalidate()
        displayLink = nil
        NotificationCenter.default.removeObserver(self)
    }

    /// Get current battery level (0.0 - 1.0)
    var batteryLevel: Float {
        return UIDevice.current.batteryLevel
    }

    /// Get current battery state
    var batteryState: UIDevice.BatteryState {
        return UIDevice.current.batteryState
    }

    /// Check if device is in low power mode
    var isLowPowerMode: Bool {
        return ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    /// Apply power strategy based on current battery state
    func applyPowerStrategy(_ strategy: PowerStrategy) {
        currentStrategy = strategy
        switch strategy {
        case .normal:
            break
        case .reduced:
            NotificationCenter.default.post(name: .init("ReduceAnimations"), object: nil)
        case .minimal:
            NotificationCenter.default.post(name: .init("StopBackgroundTasks"), object: nil)
            NotificationCenter.default.post(name: .init("ReduceAnimations"), object: nil)
        }
    }

    @objc private func batteryStateChanged() { checkBatteryState() }
    @objc private func batteryLevelChanged() { checkBatteryState() }

    @objc private func checkBatteryState() {
        let level = batteryLevel
        let state = batteryState
        let isLowPower = isLowPowerMode

        if isLowPower || state == .unplugged && level < 0.2 {
            applyPowerStrategy(.minimal)
        } else if state == .unplugged && level < 0.5 {
            applyPowerStrategy(.reduced)
        } else {
            applyPowerStrategy(.normal)
        }
    }
}

deinit {
    displayLink?.invalidate()
    NotificationCenter.default.removeObserver(self)
}

enum PowerStrategy {
    case normal
    case reduced
    case minimal
}
