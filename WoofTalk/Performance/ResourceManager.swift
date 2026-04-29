import Foundation

final class ResourceManager {
    
    static let shared = ResourceManager()
    
    private var lazyResources: [String: Any] = [:]
    private let resourceLock = NSLock()

    private var paginationState: [String: PaginationState] = [:]

    private init() {}
    
    func lazyResource<T>(for key: String, loader: @escaping () -> T) -> T {
        resourceLock.lock()
        defer { resourceLock.unlock() }
        
        if let existing = lazyResources[key] as? Box<T> {
            return existing.value
        }
        
        let resource = Box(loader: loader)
        lazyResources[key] = resource
        return resource.value
    }
    
    func preloadResource(for key: String) {}
    
    func invalidateResource(for key: String) {
        resourceLock.lock()
        defer { resourceLock.unlock() }
        
        lazyResources.removeValue(forKey: key)
    }
    
    func paginatedResults<T>(
        for query: String,
        pageSize: Int,
        loader: @escaping (Int, Int) -> [T]
    ) -> PaginationIterator<T> {
        return PaginationIterator(
            query: query,
            pageSize: pageSize,
            loader: loader,
            stateManager: self
        )
    }
    
    func hasMorePages(for query: String) -> Bool {
        let state = paginationState[query]
        return state?.hasMore ?? true
    }
    
    func updatePaginationState(for query: String, currentPage: Int, hasMore: Bool) {
        paginationState[query] = PaginationState(
            currentPage: currentPage,
            hasMore: hasMore
        )
    }
    
    func clearNonEssentialCaches() {
        resourceLock.lock()
        defer { resourceLock.unlock() }

        let essentialKeys = ["user_profile", "app_config", "language_packs"]
        lazyResources = lazyResources.filter { essentialKeys.contains($0.key) }
    }
    
    func clearAllResources() {
        resourceLock.lock()
        defer { resourceLock.unlock() }

        lazyResources.removeAll()
        paginationState.removeAll()
    }
}

private class Box<T> {
    private var _value: T?
    private let loader: () -> T

    init(loader: @escaping () -> T) {
        self.loader = loader
    }

    var value: T {
        if _value == nil { _value = loader() }
        return _value!
    }
}

private struct PaginationState {
    let currentPage: Int
    let hasMore: Bool
}

struct PaginationIterator<T> {
    private let query: String
    private let pageSize: Int
    private let loader: (Int, Int) -> [T]
    private weak var stateManager: ResourceManager?
    
    private var currentPage: Int = 0
    private var hasMore: Bool = true
    private var cachedItems: [T] = []
    private var cacheIndex: Int = 0
    
    init(query: String, pageSize: Int, loader: @escaping (Int, Int) -> [T], stateManager: ResourceManager) {
        self.query = query
        self.pageSize = pageSize
        self.loader = loader
        self.stateManager = stateManager
    }
    
    mutating func next() -> [T] {
        if cacheIndex < cachedItems.count {
            let endIndex = min(cacheIndex + pageSize, cachedItems.count)
            let items = Array(cachedItems[cacheIndex..<endIndex])
            cacheIndex = endIndex
            return items
        }
        
        guard hasMore else { return [] }
        
        let newItems = loader(currentPage, pageSize)
        
        if newItems.count < pageSize {
            hasMore = false
        } else {
            currentPage += 1
        }
        
        cachedItems.append(contentsOf: newItems)
        stateManager?.updatePaginationState(for: query, currentPage: currentPage, hasMore: hasMore)
        
        cacheIndex = cachedItems.count - newItems.count
        return newItems
    }
    
    var hasMorePages: Bool {
        return hasMore || cacheIndex < cachedItems.count
    }
}
