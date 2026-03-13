// MARK: - ConnectivityManager

import Foundation
import SystemConfiguration

/// Manages network connectivity status and offline detection
final class ConnectivityManager {
    
    // MARK: - Public Types
    
    /// Network connectivity status
    enum NetworkStatus: Equatable {
        case online
        case offline
        case unknown
    }
    
    /// Network change notification
    struct NetworkStatusChange: Equatable {
        let oldStatus: NetworkStatus
        let newStatus: NetworkStatus
        let timestamp: Date
    }
    
    // MARK: - Private Properties
    
    private var currentStatus: NetworkStatus = .unknown
    private var lastStatusChange: Date = .distantPast
    private let reachabilityQueue = DispatchQueue(label: "com.wooftalk.connectivity.reachability")
    private let callbackQueue = DispatchQueue(label: "com.wooftalk.connectivity.callback")
    
    // MARK: - Public Properties
    
    /// Current network status
    var status: NetworkStatus {
        get {
            var result: NetworkStatus = .unknown
            reachabilityQueue.sync {
                result = self.currentStatus
            }
            return result
        }
    }
    
    /// Last status change
    var lastStatusChangeTime: Date {
        var result: Date = .distantPast
        reachabilityQueue.sync {
            result = self.lastStatusChange
        }
        return result
    }
    
    // MARK: - Initialization
    
    init() {
        setupReachability()
    }
    
    // MARK: - Public Methods
    
    /// Check current network status
    func checkNetworkStatus() -> NetworkStatus {
        var flags: SCNetworkReachabilityFlags = []
        
        guard let reachability = SCNetworkReachabilityCreateWithName(nil, "google.com") else {
            return .unknown
        }
        
        var success = SCNetworkReachabilityGetFlags(reachability, &flags)
        
        if !success {
            return .unknown
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        let canConnectAutomatically = flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
        let canConnectWithoutUserInteraction = canConnectAutomatically && !flags.contains(.interventionRequired)
        
        let isConnected = isReachable && (!needsConnection || canConnectWithoutUserInteraction)
        
        let newStatus = isConnected ? NetworkStatus.online : NetworkStatus.offline
        
        reachabilityQueue.async {
            if self.currentStatus != newStatus {
                self.currentStatus = newStatus
                self.lastStatusChange = Date()
                self.notifyStatusChange(old: self.currentStatus, new: newStatus)
            }
        }
        
        return newStatus
    }
    
    /// Start monitoring network changes
    func startMonitoring() {
        reachabilityQueue.async {
            self.setupReachabilityMonitor()
        }
    }
    
    /// Stop monitoring network changes
    func stopMonitoring() {
        reachabilityQueue.async {
            self.stopReachabilityMonitor()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupReachability() {
        // Initial status check
        _ = checkNetworkStatus()
    }
    
    private func setupReachabilityMonitor() {
        // This would set up a real network reachability monitor
        // For now, we'll use periodic polling
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkNetworkStatus()
        }
    }
    
    private func stopReachabilityMonitor() {
        // Stop any monitoring timers
    }
    
    private func notifyStatusChange(old oldStatus: NetworkStatus, new newStatus: NetworkStatus) {
        let change = NetworkStatusChange(
            oldStatus: oldStatus,
            newStatus: newStatus,
            timestamp: Date()
        )
        
        // Notify observers (this would be implemented with NotificationCenter or delegate)
        print("Network status changed: \(change)")
    }
    
    // MARK: - Test Helpers
    
    /// Simulate network status change for testing
    func simulateNetworkStatus(_ status: NetworkStatus) {
        reachabilityQueue.async {
            let oldStatus = self.currentStatus
            self.currentStatus = status
            self.lastStatusChange = Date()
            self.notifyStatusChange(old: oldStatus, new: status)
        }
    }
}