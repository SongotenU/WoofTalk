import Foundation

/// Manages contribution sync with backend
final class ContributionSyncManager {

    private let networkManager: NetworkManager
    private var syncQueue: [Contribution] = []
    private let lock = NSLock()
    private var syncTimer: Timer?

    init(networkManager: NetworkManager = .shared) {
        self.networkManager = networkManager
        syncTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.syncQueuedContributions()
        }
    }

    func isNetworkAvailable() -> Bool {
        networkManager.isNetworkAvailable
    }

    func submitContribution(_ contribution: Contribution, completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1) {
            completion(self.networkManager.isNetworkAvailable ? .success(()) : .failure(NSError(domain: "ContributionSyncManager", code: 1001)))
        }
    }

    func queueContributionForSync(_ contribution: Contribution) {
        lock.lock(); defer { lock.unlock() }
        syncQueue.append(contribution)
    }

    func syncQueuedContributions() {
        lock.lock()
        let queued = syncQueue; syncQueue.removeAll()
        lock.unlock()

        for contribution in queued {
            submitContribution(contribution) { _ in }
        }
    }
}
