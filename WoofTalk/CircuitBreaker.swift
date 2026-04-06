// MARK: - CircuitBreaker

import Foundation

/// Circuit breaker state machine for resilient service calls
enum CircuitState: Equatable {
    case closed
    case open(reopenedAt: Date)
    case halfOpen
}

final class CircuitBreaker {
    private var state: CircuitState = .closed
    private var consecutiveFailures: Int = 0
    private let failureThreshold: Int
    private let resetTimeout: TimeInterval
    private let lock = NSLock()

    var currentState: CircuitState {
        lock.lock()
        defer { lock.unlock() }
        if case .open(let reopenedAt) = state {
            if Date().timeIntervalSince(reopenedAt) >= resetTimeout {
                state = .halfOpen
            }
        }
        return state
    }

    var consecutiveFailureCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return consecutiveFailures
    }

    init(failureThreshold: Int = 5, resetTimeout: TimeInterval = 30) {
        self.failureThreshold = failureThreshold
        self.resetTimeout = resetTimeout
    }

    func execute<T>(_ operation: () async throws -> T) async throws -> T {
        lock.lock()
        let currentState = self.currentState
        lock.unlock()

        guard currentState != .open else {
            throw CircuitBreakerError.circuitOpen
        }

        do {
            let result = try await operation()
            onSuccess()
            return result
        } catch {
            onFailure()
            throw error
        }
    }

    func onSuccess() {
        lock.lock()
        consecutiveFailures = 0
        state = .closed
        lock.unlock()
    }

    func onFailure() {
        lock.lock()
        consecutiveFailures += 1
        if consecutiveFailures >= failureThreshold {
            state = .open(reopenedAt: Date())
        }
        lock.unlock()
    }

    func reset() {
        lock.lock()
        state = .closed
        consecutiveFailures = 0
        lock.unlock()
    }
}

enum CircuitBreakerError: Error, LocalizedError {
    case circuitOpen

    var errorDescription: String? {
        switch self {
        case .circuitOpen:
            return "Circuit breaker is open — skipping call to prevent cascading failures"
        }
    }
}
