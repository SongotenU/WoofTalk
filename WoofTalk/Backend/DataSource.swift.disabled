import Foundation
import Combine
import Supabase

protocol DataSource {
    func fetchTranslations() async throws -> [TranslationRecord]
    func saveTranslation(_ translation: TranslationRecord) async throws
    func fetchCommunityPhrases() async throws -> [CommunityPhrase]
    func submitPhrase(_ phrase: CommunityPhrase) async throws
    func follow(userId: String) async throws
    func unfollow(userId: String) async throws
}

@MainActor
final class LocalDataSource: DataSource {
    private let context: PersistenceController
    
    init(context: PersistenceController = .shared) {
        self.context = context
    }
    
    func fetchTranslations() async throws -> [TranslationRecord] {
        let request: NSFetchRequest<TranslationEntity> = TranslationEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        let entities = try context.container.viewContext.fetch(request)
        return entities.compactMap { entity in
            TranslationRecord(
                id: entity.id?.uuidString,
                userId: nil,
                humanText: entity.humanText ?? "",
                animalText: entity.animalText ?? "",
                sourceLanguage: entity.sourceLanguage ?? "human",
                targetLanguage: entity.targetLanguage ?? "dog",
                confidence: entity.confidence,
                qualityScore: entity.qualityScore,
                isFavorite: entity.isFavorite,
                createdAt: entity.timestamp
            )
        }
    }
    
    func saveTranslation(_ translation: TranslationRecord) async throws {
        let entity = TranslationEntity(context: context.container.viewContext)
        entity.id = UUID()
        entity.humanText = translation.humanText
        entity.animalText = translation.animalText
        entity.sourceLanguage = translation.sourceLanguage
        entity.targetLanguage = translation.targetLanguage
        entity.confidence = translation.confidence
        entity.qualityScore = translation.qualityScore ?? 0
        entity.isFavorite = translation.isFavorite
        entity.timestamp = Date()
        try context.container.viewContext.save()
    }
    
    func fetchCommunityPhrases() async throws -> [CommunityPhrase] {
        let request: NSFetchRequest<CommunityPhraseEntity> = CommunityPhraseEntity.fetchRequest()
        request.predicate = NSPredicate(format: "approvalStatus == %@", "approved")
        let entities = try context.container.viewContext.fetch(request)
        return entities.compactMap { entity in
            CommunityPhrase(
                id: entity.id?.uuidString,
                phraseText: entity.phraseText ?? "",
                language: entity.language ?? "dog",
                submittedBy: entity.submittedBy?.uuidString,
                approvalStatus: entity.approvalStatus,
                upvotes: Int(entity.upvotes),
                downvotes: Int(entity.downvotes),
                createdAt: entity.createdAt
            )
        }
    }
    
    func submitPhrase(_ phrase: CommunityPhrase) async throws {
        let entity = CommunityPhraseEntity(context: context.container.viewContext)
        entity.id = UUID()
        entity.phraseText = phrase.phraseText
        entity.language = phrase.language
        entity.approvalStatus = "pending"
        entity.upvotes = Int64(phrase.upvotes)
        entity.downvotes = Int64(phrase.downvotes)
        entity.createdAt = Date()
        try context.container.viewContext.save()
    }
    
    func follow(userId: String) async throws {}
    func unfollow(userId: String) async throws {}
}

@MainActor
final class CloudDataSource: DataSource {
    private let manager: SupabaseManager
    
    init(manager: SupabaseManager = .shared) {
        self.manager = manager
    }
    
    func fetchTranslations() async throws -> [TranslationRecord] {
        try await manager.fetchTranslations()
    }
    
    func saveTranslation(_ translation: TranslationRecord) async throws {
        try await manager.saveTranslation(translation)
    }
    
    func fetchCommunityPhrases() async throws -> [CommunityPhrase] {
        try await manager.fetchCommunityPhrases()
    }
    
    func submitPhrase(_ phrase: CommunityPhrase) async throws {
        try await manager.submitPhrase(phrase)
    }
    
    func follow(userId: String) async throws {
        try await manager.follow(userId: userId)
    }
    
    func unfollow(userId: String) async throws {
        try await manager.unfollow(userId: userId)
    }
}

@MainActor
final class SyncManager: ObservableObject {
    private let local: LocalDataSource
    private let cloud: CloudDataSource
    private var cancellables = Set<AnyCancellable>()
    private var writeQueue: [PendingWrite] = []
    private var isOnline = false
    
    @Published var syncStatus: SyncStatus = .idle
    
    init(local: LocalDataSource = .init(), cloud: CloudDataSource = .init()) {
        self.local = local
        self.cloud = cloud
        startNetworkMonitoring()
    }
    
    private func startNetworkMonitoring() {
        NotificationCenter.default.publisher(for: .reachabilityChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self, let online = notification.userInfo?["online"] as? Bool else { return }
                self.isOnline = online
                if online { self.flushWriteQueue() }
            }
            .store(in: &cancellables)
    }
    
    func fetchTranslations() async throws -> [TranslationRecord] {
        if isOnline {
            return try await cloud.fetchTranslations()
        }
        return try await local.fetchTranslations()
    }
    
    func saveTranslation(_ translation: TranslationRecord) async throws {
        try await local.saveTranslation(translation)
        if isOnline {
            try await cloud.saveTranslation(translation)
        } else {
            writeQueue.append(.translation(translation))
        }
    }
    
    func submitPhrase(_ phrase: CommunityPhrase) async throws {
        try await local.submitPhrase(phrase)
        if isOnline {
            try await cloud.submitPhrase(phrase)
        } else {
            writeQueue.append(.phrase(phrase))
        }
    }
    
    private func flushWriteQueue() {
        guard !writeQueue.isEmpty else { return }
        Task {
            syncStatus = .syncing
            var failed: [PendingWrite] = []
            for pending in writeQueue {
                do {
                    switch pending {
                    case .translation(let t):
                        try await cloud.saveTranslation(t)
                    case .phrase(let p):
                        try await cloud.submitPhrase(p)
                    }
                } catch {
                    failed.append(pending)
                }
            }
            writeQueue = failed
            syncStatus = writeQueue.isEmpty ? .synced : .partialSync
        }
    }
    
    func forceSync() async {
        isOnline = true
        flushWriteQueue()
    }
}

enum SyncStatus: Equatable {
    case idle, syncing, synced, partialSync, offline
    
    static func == (lhs: SyncStatus, rhs: SyncStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.syncing, .syncing), (.synced, .synced),
             (.partialSync, .partialSync), (.offline, .offline):
            return true
        default: return false
        }
    }
}

enum PendingWrite {
    case translation(TranslationRecord)
    case phrase(CommunityPhrase)
}

extension Notification.Name {
    static let reachabilityChanged = Notification.Name("reachabilityChanged")
}
