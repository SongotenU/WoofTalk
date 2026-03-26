// MARK: - MockContributionSyncManager

import Foundation

/// Mock contribution sync manager for testing
final class MockContributionSyncManager: ContributionSyncManagerProtocol {
    
    // MARK: - Properties
    
    var isNetworkAvailable: Bool
    var shouldThrowError: Bool
    var syncDelay: TimeInterval
    
    // MARK: - Initialization
    
    init(networkAvailable: Bool = true, shouldThrowError: Bool = false, syncDelay: TimeInterval = 0) {
        self.isNetworkAvailable = networkAvailable
        self.shouldThrowError = shouldThrowError
        self.syncDelay = syncDelay
    }
    
    // MARK: - ContributionSyncManagerProtocol
    
    func isNetworkAvailable() -> Bool {
        return isNetworkAvailable
    }
    
    func syncContribution(_ contribution: Contribution, completion: @escaping (Result<Void, ContributionSyncError>) -> Void) {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + syncDelay) {
            if self.shouldThrowError {
                completion(.failure(.networkError))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func syncAllContributions(completion: @escaping (Result<Void, ContributionSyncError>) -> Void) {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + syncDelay) {
            if self.shouldThrowError {
                completion(.failure(.networkError))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func getPendingContributions() -> [Contribution] {
        // Mock implementation - return empty array
        return []
    }
    
    func getContribution(withID id: UUID) -> Contribution? {
        // Mock implementation - return nil
        return nil
    }
    
    func deleteContribution(withID id: UUID, completion: @escaping (Result<Void, ContributionSyncError>) -> Void) {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + syncDelay) {
            if self.shouldThrowError {
                completion(.failure(.networkError))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func updateContribution(_ contribution: Contribution, completion: @escaping (Result<Void, ContributionSyncError>) -> Void) {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + syncDelay) {
            if self.shouldThrowError {
                completion(.failure(.networkError))
            } else {
                completion(.success(()))
            }
        }
    }
}