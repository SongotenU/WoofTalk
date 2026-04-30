import Foundation

enum CircuitState: Equatable {
    case closed
    case open(reopenedAt: Date)
    case halfOpen
}

final class CircuitBreaker {
    private var state: CircuitState = .closed
    private var consecutiveFailures = 0
    private let failureThreshold: Int
    private let resetTimeout: TimeInterval
    private let lock = NSLock()

    var currentState: CircuitState {
        guard case .open(let reopenedAt) = state,
              Date().timeIntervalSince(reopenedAt) >= resetTimeout
        else { return state }
        state = .halfOpen
        return .halfOpen
    }

    var consecutiveFailureCount: Int {
        lock.lock(); defer { lock.unlock() }
        return consecutiveFailures
    }

    init(failureThreshold: Int = 5, resetTimeout: TimeInterval = 30) {
        self.failureThreshold = failureThreshold
        self.resetTimeout = resetTimeout
    }

    func onSuccess() {
        lock.lock(); defer { lock.unlock() }
        consecutiveFailures = 0
        state = .closed
    }

    func onFailure() {
        lock.lock(); defer { lock.unlock() }
        consecutiveFailures += 1
        if consecutiveFailures >= failureThreshold {
            state = .open(reopenedAt: Date())
        }
    }

    func reset() {
        lock.lock(); defer { lock.unlock() }
        state = .closed
        consecutiveFailures = 0
    }
}

enum CircuitBreakerError: Error, LocalizedError {
    case circuitOpen

    var errorDescription: String? { "Circuit breaker is open — skipping call to prevent cascading failures" }
}
