// MARK: - LeaderboardManager

import Foundation
import CoreData
import Combine

/// Entry in the leaderboard
struct LeaderboardEntry: Identifiable, Equatable {
    let id: UUID
    let rank: Int
    let user: User
    let score: Int
    let contributionCount: Int
    
    var displayName: String {
        return user.username ?? "Anonymous"
    }
}

/// Time period for leaderboard
enum LeaderboardPeriod: String, CaseIterable {
    case weekly = "weekly"
    case monthly = "monthly"
    case allTime = "all_time"
    
    var displayName: String {
        switch self {
        case .weekly: return "This Week"
        case .monthly: return "This Month"
        case .allTime: return "All Time"
        }
    }
}

/// Manages leaderboard rankings
final class LeaderboardManager: ObservableObject {
    
    // MARK: - Dependencies
    
    private let coreDataContext: NSManagedObjectContext
    
    // MARK: - Published Properties
    
    @Published private(set) var entries: [LeaderboardEntry] = []
    @Published private(set) var isLoading = false
    @Published private(set) var lastUpdated: Date?
    @Published var selectedPeriod: LeaderboardPeriod = .weekly
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let cacheKey = "leaderboard_cache"
    private let cacheDuration: TimeInterval = 300 // 5 minutes
    
    // MARK: - Static
    
    static let shared = LeaderboardManager(
        coreDataContext: PersistenceController.shared.container.viewContext
    )
    
    // MARK: - Initialization
    
    init(coreDataContext: NSManagedObjectContext) {
        self.coreDataContext = coreDataContext
        loadCachedLeaderboard()
        setupPeriodObserver()
    }
    
    // MARK: - Public API
    
    /// Refreshes the leaderboard
    func refresh() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let newEntries = self.calculateLeaderboard(for: self.selectedPeriod)
            
            DispatchQueue.main.async {
                self.entries = newEntries
                self.lastUpdated = Date()
                self.isLoading = false
                self.cacheLeaderboard()
                
                // Track leaderboard update event
                self.trackLeaderboardUpdate()
            }
        }
    }
    
    /// Gets the current user's rank
    /// - Returns: The rank of the current user, or nil if not on leaderboard
    func getCurrentUserRank() -> Int? {
        guard let currentUserID = UserProfileManager.currentUser?.id else { return nil }
        return entries.first { $0.user.id == currentUserID }?.rank
    }
    
    /// Gets top N entries
    /// - Parameter count: Number of entries to return
    /// - Returns: Array of top entries
    func getTopEntries(count: Int) -> [LeaderboardEntry] {
        return Array(entries.prefix(count))
    }
    
    /// Checks if current user's rank changed and notifies
    func checkForRankChange() {
        let previousRank = UserDefaults.standard.integer(forKey: "previous_leaderboard_rank")
        let currentRank = getCurrentUserRank() ?? 0
        
        if currentRank > 0 && previousRank != currentRank {
            let difference = abs(currentRank - previousRank)
            
            if currentRank < previousRank {
                // Improved rank
                NotificationManager.shared.sendLeaderboardChangeNotification(
                    newRank: currentRank,
                    improvement: difference
                )
            }
            
            UserDefaults.standard.set(currentRank, forKey: "previous_leaderboard_rank")
        }
    }
    
    // MARK: - Private Methods
    
    private func calculateLeaderboard(for period: LeaderboardPeriod) -> [LeaderboardEntry] {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "username", ascending: true)]
        
        do {
            let users = try coreDataContext.fetch(fetchRequest)
            
            let scoredUsers = users.compactMap { user -> (User, Int)? in
                guard let userID = user.id else { return nil }
                
                let score = calculateScore(for: user, period: period)
                guard score > 0 else { return nil }
                
                return (user, score)
            }
            .sorted { $0.1 > $1.1 }
            
            return scoredUsers.enumerated().compactMap { index, item in
                LeaderboardEntry(
                    id: UUID(),
                    rank: index + 1,
                    user: item.0,
                    score: item.1,
                    contributionCount: getApprovedContributionCount(for: item.0)
                )
            }
        } catch {
            print("Error fetching leaderboard: \(error)")
            return []
        }
    }
    
    private func calculateScore(for user: User, period: LeaderboardPeriod) -> Int {
        let approvedContributions = getApprovedContributions(for: user)
        
        let filteredContributions: [Contribution]
        switch period {
        case .weekly:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            filteredContributions = approvedContributions.filter { ($0.timestamp ?? Date.distantPast) >= weekAgo }
        case .monthly:
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            filteredContributions = approvedContributions.filter { ($0.timestamp ?? Date.distantPast) >= monthAgo }
        case .allTime:
            filteredContributions = approvedContributions
        }
        
        return filteredContributions.reduce(0) { total, contribution in
            let qualityMultiplier = (contribution.qualityScore + 1) / 2 // 0-1 range
            return total + Int(10 * qualityMultiplier)
        }
    }
    
    private func getApprovedContributions(for user: User) -> [Contribution] {
        guard let contributions = user.contributions else { return [] }
        return contributions.filter { $0.displayStatus == .approved }
    }
    
    private func getApprovedContributionCount(for user: User) -> Int {
        return getApprovedContributions(for: user).count
    }
    
    private func setupPeriodObserver() {
        $selectedPeriod
            .dropFirst()
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
    }
    
    private func cacheLeaderboard() {
        guard let data = try? JSONEncoder().encode(entries.map { entry in
            [
                "id": entry.id.uuidString,
                "rank": entry.rank,
                "userID": entry.user.id?.uuidString ?? "",
                "score": entry.score,
                "contributionCount": entry.contributionCount
            ]
        }) else { return }
        
        UserDefaults.standard.set(data, forKey: cacheKey)
        UserDefaults.standard.set(Date(), forKey: "\(cacheKey)_timestamp")
    }
    
    private func loadCachedLeaderboard() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let timestamp = UserDefaults.standard.object(forKey: "\(cacheKey)_timestamp") as? Date,
              Date().timeIntervalSince(timestamp) < cacheDuration else { return }
        
        // Cache loading is simplified - in production would reconstruct User objects
        lastUpdated = timestamp
    }
    
    private func trackLeaderboardUpdate() {
        let eventData: [String: Any] = [
            "event": "leaderboard_updated",
            "timestamp": Date().timeIntervalSince1970,
            "entry_count": entries.count,
            "period": selectedPeriod.rawValue
        ]
        
        print("[Leaderboard] Update event: \(eventData)")
    }
}

// MARK: - Leaderboard View

struct LeaderboardView: View {
    @StateObject private var viewModel = LeaderboardViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Period selector
                Picker("Period", selection: $viewModel.selectedPeriod) {
                    ForEach(LeaderboardPeriod.allCases, id: \.self) { period in
                        Text(period.displayName).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if viewModel.isLoading && viewModel.entries.isEmpty {
                    Spacer()
                    ProgressView("Loading leaderboard...")
                    Spacer()
                } else if viewModel.entries.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "trophy",
                        title: "No rankings yet",
                        message: "Be the first to contribute!"
                    )
                    Spacer()
                } else {
                    // User's own rank banner
                    if let userRank = viewModel.getCurrentUserRank() {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Your rank: #\(userRank)")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                    }
                    
                    List(viewModel.entries, id: \.id) { entry in
                        LeaderboardRow(entry: entry)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Leaderboard")
            .refreshable {
                viewModel.refresh()
            }
        }
        .onAppear {
            viewModel.refresh()
        }
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 40, height: 40)
                
                if entry.rank <= 3 {
                    Image(systemName: rankIcon)
                        .foregroundColor(.white)
                        .font(.headline)
                } else {
                    Text("\(entry.rank)")
                        .foregroundColor(.white)
                        .font(.headline)
                }
            }
            
            // User info
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.headline)
                
                Text("\(entry.contributionCount) contributions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Score
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.score)")
                    .font(.title2.bold())
                    .foregroundColor(.accentColor)
                
                Text("points")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var rankColor: Color {
        switch entry.rank {
        case 1: return .gold
        case 2: return .silver
        case 3: return .bronze
        default: return .gray
        }
    }
    
    private var rankIcon: String {
        switch entry.rank {
        case 1: return "crown.fill"
        case 2: return "2.circle.fill"
        case 3: return "3.circle.fill"
        default: return ""
        }
    }
}

// MARK: - Leaderboard ViewModel

@MainActor
class LeaderboardViewModel: ObservableObject {
    @Published var entries: [LeaderboardEntry] = []
    @Published var isLoading = false
    @Published var selectedPeriod: LeaderboardPeriod = .weekly {
        didSet {
            refresh()
        }
    }
    
    private let manager = LeaderboardManager.shared
    
    func refresh() {
        isLoading = true
        manager.refresh()
        
        // Observe manager's published properties
        Task {
            for await _ in AsyncStream<Void> { continuation in
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    if !manager.isLoading {
                        continuation.finish()
                    }
                }
            }
            
            self.entries = manager.entries
            self.isLoading = manager.isLoading
        }
    }
    
    func getCurrentUserRank() -> Int? {
        return manager.getCurrentUserRank()
    }
}

// MARK: - Color Extension

extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
    static let silver = Color(red: 0.75, green: 0.75, blue: 0.75)
    static let bronze = Color(red: 0.8, green: 0.5, blue: 0.2)
}

// MARK: - Preview

#if DEBUG
struct LeaderboardView_Previews: PreviewProvider {
    static var previews: some View {
        LeaderboardView()
    }
}
#endif
