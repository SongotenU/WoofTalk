// MARK: - CommunityPhraseBrowserView

import SwiftUI
import CoreData

struct CommunityPhraseBrowserView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = CommunityPhraseBrowserViewModel()
    
    @State private var searchText = ""
    @State private var isGridView = true
    @State private var showingFilters = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SearchBarView(text: $searchText) {
                    viewModel.search(query: searchText)
                }
                .padding()
                
                HStack {
                    Button(action: { isGridView.toggle() }) {
                        Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                            .font(.title2)
                    }
                    .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: { withAnimation { showingFilters.toggle() } }) {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text("Filters")
                        }
                    }
                    .foregroundColor(.primary)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                if showingFilters {
                    FilterOptionsView(
                        selectedQuality: $viewModel.minQualityFilter,
                        selectedSort: $viewModel.sortOption
                    )
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                if !viewModel.isOnline {
                    OfflineBannerView()
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading phrases...")
                    Spacer()
                } else if viewModel.phrases.isEmpty {
                    EmptyStateView(
                        icon: "doc.text.magnifyingglass",
                        title: "No phrases found",
                        message: "Try adjusting your search or filters"
                    )
                } else {
                    phraseContent
                }
            }
            .navigationTitle("Community Phrases")
            .refreshable {
                await viewModel.refresh()
            }
        }
        .onAppear {
            viewModel.loadPhrases()
        }
        .onChange(of: viewModel.minQualityFilter) { _, _ in
            viewModel.loadPhrases()
        }
        .onChange(of: viewModel.sortOption) { _, _ in
            viewModel.loadPhrases()
        }
    }
    
    @ViewBuilder
    private var phraseContent: some View {
        if isGridView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 150), spacing: 12)
                ], spacing: 12) {
                    ForEach(viewModel.phrases, id: \.id) { phrase in
                        NavigationLink(destination: CommunityPhraseDetailView(phrase: phrase)) {
                            CommunityPhraseGridCell(phrase: phrase)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
                
                if viewModel.hasMore {
                    Button("Load More") {
                        viewModel.loadMore()
                    }
                    .padding()
                }
            }
        } else {
            List(viewModel.phrases, id: \.id) { phrase in
                NavigationLink(destination: CommunityPhraseDetailView(phrase: phrase)) {
                    CommunityPhraseCell(phrase: phrase)
                }
            }
            .listStyle(PlainListStyle())
        }
    }
}

@MainActor
class CommunityPhraseBrowserViewModel: ObservableObject {
    @Published var phrases: [CommunityPhrase] = []
    @Published var isLoading = false
    @Published var isOnline = true
    @Published var hasMore = false
    @Published var minQualityFilter: Double? = nil
    @Published var sortOption: SortOption = .quality
    
    private let cacheManager = CommunityPhraseCacheManager.shared
    private var currentPage = 0
    private let pageSize = 20
    
    func loadPhrases() {
        isLoading = true
        currentPage = 0
        phrases = cacheManager.getCachedPhrases(
            minQuality: minQualityFilter,
            sortBy: sortOption,
            offset: 0,
            limit: pageSize
        )
        hasMore = phrases.count == pageSize
        isLoading = false
    }
    
    func search(query: String) {
        isLoading = true
        currentPage = 0
        if query.isEmpty {
            phrases = cacheManager.getCachedPhrases(
                minQuality: minQualityFilter,
                sortBy: sortOption,
                offset: 0,
                limit: pageSize
            )
        } else {
            phrases = cacheManager.getCachedPhrases(
                searchQuery: query,
                minQuality: minQualityFilter,
                sortBy: .relevance,
                offset: 0,
                limit: pageSize
            )
        }
        hasMore = phrases.count == pageSize
        isLoading = false
    }
    
    func refresh() async {
        isOnline = await checkConnectivity()
        if isOnline {
            await withCheckedContinuation { continuation in
                cacheManager.syncWithCloud { result in
                    switch result {
                    case .success:
                        Task { @MainActor in
                            loadPhrases()
                            continuation.resume()
                        }
                    case .failure:
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    func loadMore() {
        currentPage += 1
        let morePhrases = cacheManager.getCachedPhrases(
            offset: currentPage * pageSize,
            limit: pageSize,
            minQuality: minQualityFilter,
            sortBy: sortOption
        )
        phrases.append(contentsOf: morePhrases)
        hasMore = morePhrases.count == pageSize
    }
    
    private func checkConnectivity() async -> Bool {
        return true
    }
}
