// MARK: - ContributionSyncManager

import Foundation

/// Manages contribution sync with backend services
final class ContributionSyncManager {
    
    // MARK: - Properties
    
    private let networkManager: NetworkManager
    private var syncQueue: [Contribution] = []
    private let syncQueueLock = NSLock()
    
    // MARK: - Initialization
    
    init(networkManager: NetworkManager = NetworkManager.shared) {
        self.networkManager = networkManager
        
        // Start sync manager
        startSyncManager()
    }
    
    // MARK: - Public API
    
    /// Checks if network is available
    func isNetworkAvailable() -> Bool {
        return networkManager.isNetworkAvailable
    }
    
    /// Submits a contribution to the backend
    func submitContribution(_ contribution: Contribution, completion: @escaping (Result<Void, Error>) -> Void) {
        // For now, simulate network submission
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1.0) {
            // Simulate network success
            if self.isNetworkAvailable() {
                completion(.success(()))
            } else {
                completion(.failure(NSError(domain: "ContributionSyncManager", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Network unavailable"]))) 
            }
        }
    }
    
    /// Queues a contribution for later sync
    func queueContributionForSync(_ contribution: Contribution) {
        syncQueueLock.lock()
        defer { syncQueueLock.unlock() }
        
        syncQueue.append(contribution)
        print("Queued contribution for sync: \(contribution.humanText ?? \"Unknown\")")
    }
    
    /// Attempts to sync queued contributions
    func syncQueuedContributions() {
        syncQueueLock.lock()
        let currentQueue = syncQueue
        syncQueue.removeAll()
        syncQueueLock.unlock()
        
        // Simulate sync process
        DispatchQueue.global(qos: .background).async {
            for contribution in currentQueue {
                self.submitContribution(contribution) { result in
                    switch result {
                    case .success():
                        print("Successfully synced contribution: \(contribution.humanText ?? \"Unknown\")")
                    case .failure(let error):
                        print("Failed to sync contribution: \(contribution.humanText ?? \"Unknown\") - \(error.localizedDescription)")
                        // Re-add to queue for retry
                        self.queueContributionForSync(contribution)
                    }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func startSyncManager() {
        // Start periodic sync
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.syncQueuedContributions()
        }
    }
}

// MARK: - NetworkManager

/// Simple network manager for connectivity checks
final class NetworkManager {
    
    static let shared = NetworkManager()
    
    var isNetworkAvailable: Bool {
        // For now, simulate network availability
        // In a real app, use NWPathMonitor or similar
        return true
    }
    
    private init() {
        // Setup network monitoring if needed
    }
}