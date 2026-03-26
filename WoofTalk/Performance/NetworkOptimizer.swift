import Foundation

final class NetworkOptimizer {
    
    static let shared = NetworkOptimizer()
    
    // MARK: - Cache
    private var responseCache: [String: CachedResponse] = [:]
    private let cacheLock = NSLock()
    private let maxCacheSize = 50 * 1024 * 1024 // 50MB
    private var currentCacheSize: Int = 0
    
    // MARK: - Connection Pool
    private var connectionPool: [URLSession] = []
    private let maxPoolSize = 4
    private var currentPoolIndex = 0
    
    // MARK: - Offline Queue
    private var offlineQueue: [QueuedRequest] = []
    private var isOffline = false
    
    // MARK: - Configuration
    private let cacheExpirationInterval: TimeInterval = 3600 // 1 hour
    private let maxRetries = 3
    private let baseRetryDelay: TimeInterval = 1.0
    
    private init() {
        setupNetworkMonitoring()
    }
    
    // MARK: - Network Monitoring
    private func setupNetworkMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(networkStatusChanged),
            name: NSNotification.Name("NetworkStatusChanged"),
            object: nil
        )
    }
    
    @objc private func networkStatusChanged() {
        if !isOffline {
            processOfflineQueue()
        }
    }
    
    // MARK: - Response Caching
    func cachedResponse(for request: URLRequest) -> Data? {
        let key = cacheKey(for: request)
        
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        guard let cached = responseCache[key], !cached.isExpired else {
            responseCache.removeValue(forKey: key)
            return nil
        }
        
        return cached.data
    }
    
    func cacheResponse(_ data: Data, for request: URLRequest, metadata: CacheMetadata?) {
        let key = cacheKey(for: request)
        
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        currentCacheSize += data.count
        
        if currentCacheSize > maxCacheSize {
            evictOldestCacheEntries(data.count)
        }
        
        responseCache[key] = CachedResponse(
            data: data,
            timestamp: Date(),
            etag: metadata?.etag,
            lastModified: metadata?.lastModified,
            expirationInterval: metadata?.cacheDuration ?? cacheExpirationInterval
        )
    }
    
    private func cacheKey(for request: URLRequest) -> String {
        return "\(request.httpMethod ?? "GET"):\(request.url?.absoluteString ?? "")"
    }
    
    private func evictOldestCacheEntries(_ requiredSize: Int) {
        var freedSize = 0
        let sortedKeys = responseCache.sorted { $0.value.timestamp < $1.value.timestamp }
        
        for (key, value) in sortedKeys {
            if freedSize >= requiredSize {
                break
            }
            responseCache.removeValue(forKey: key)
            freedSize += value.data.count
        }
        
        currentCacheSize -= freedSize
    }
    
    // MARK: - Conditional Request Support
    func conditionalRequest(for request: URLRequest) -> URLRequest? {
        let key = cacheKey(for: request)
        
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        guard let cached = responseCache[key] else { return nil }
        
        var modifiedRequest = request
        if let etag = cached.etag {
            modifiedRequest.setValue(etag, forHTTPHeaderField: "If-None-Match")
        } else if let lastModified = cached.lastModified {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            modifiedRequest.setValue(formatter.string(from: lastModified), forHTTPHeaderField: "If-Modified-Since")
        }
        
        return modifiedRequest
    }
    
    // MARK: - Request Compression
    func compressedPayload(_ data: Data) -> Data? {
        return try? (data as NSData).compressed(using: .zlib) as Data
    }
    
    func decompressedResponse(_ data: Data) -> Data? {
        return try? (data as NSData).decompressed(using: .zlib) as Data
    }
    
    // MARK: - Connection Pooling
    func getPooledSession() -> URLSession {
        if connectionPool.isEmpty {
            let config = URLSessionConfiguration.default
            config.httpMaximumConnectionsPerHost = 6
            config.timeoutIntervalForRequest = 30
            config.timeoutIntervalForResource = 60
            config.requestCachePolicy = .returnCacheDataElseLoad
            
            return URLSession(configuration: config)
        }
        
        let session = connectionPool[currentPoolIndex]
        currentPoolIndex = (currentPoolIndex + 1) % connectionPool.count
        return session
    }
    
    // MARK: - Retry with Exponential Backoff
    func retryConfiguration(for attempt: Int) -> RetryConfig {
        let delay = baseRetryDelay * pow(2.0, Double(attempt))
        let jitter = Double.random(in: 0...0.5)
        return RetryConfig(
            delay: delay + jitter,
            shouldRetry: attempt < maxRetries
        )
    }
    
    // MARK: - Offline Queue
    func queueRequest(_ request: QueuedRequest) {
        offlineQueue.append(request)
        
        if !isOffline {
            processOfflineQueue()
        }
    }
    
    private func processOfflineQueue() {
        guard !offlineQueue.isEmpty else { return }
        
        let requests = offlineQueue
        offlineQueue.removeAll()
        
        for request in requests {
            executeQueuedRequest(request)
        }
    }
    
    private func executeQueuedRequest(_ request: QueuedRequest) {
        // Execute the queued request when network is available
    }
    
    func setOfflineMode(_ offline: Bool) {
        isOffline = offline
        if !offline {
            processOfflineQueue()
        }
    }
    
    // MARK: - Cache Management
    func clearCache() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        responseCache.removeAll()
        currentCacheSize = 0
    }
    
    var cacheSize: Int {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return currentCacheSize
    }
}

// MARK: - Supporting Types
struct CachedResponse {
    let data: Data
    let timestamp: Date
    let etag: String?
    let lastModified: Date?
    let expirationInterval: TimeInterval
    
    var isExpired: Bool {
        return Date().timeIntervalSince(timestamp) > expirationInterval
    }
}

struct CacheMetadata {
    let etag: String?
    let lastModified: Date?
    let cacheDuration: TimeInterval?
}

struct QueuedRequest {
    let urlRequest: URLRequest
    let completion: (Result<Data, Error>) -> Void
    let timestamp: Date
    let priority: Priority
    
    enum Priority: Int {
        case low = 0
        case normal = 1
        case high = 2
    }
}

struct RetryConfig {
    let delay: TimeInterval
    let shouldRetry: Bool
}
