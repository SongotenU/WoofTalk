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
                .accessibilityLabel("Search phrases")

                HStack {
                    Button(action: { isGridView.toggle() }) {
                        Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                            .font(.title2)
                    }
                    .foregroundColor(.primary)
                    .accessibilityLabel(isGridView ? "Switch to list view" : "Switch to grid view")
                    .accessibilityHint("Toggles between grid and list layout")

                    Spacer()

                    Button(action: { withAnimation { showingFilters.toggle() } }) {
                        HStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text("Filters")
                        }
                    }
                    .foregroundColor(.primary)
                    .accessibilityLabel("Filters")
                    .accessibilityHint("Toggle filter options")
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
            .accessibilityLabel("Community Phrases Browser")
            .refreshable {
                await viewModel.refresh()
            }
        }
        .onAppear {
            viewModel.loadPhrases()
        }
        .onChange(of: viewModel.minQualityFilter) {
            viewModel.loadPhrases()
        }
        .onChange(of: viewModel.sortOption) {
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
                        .accessibilityLabel("Phrase: \(phrase.name ?? "Unknown")")
                        .accessibilityHint("Double tap to view details")
                    }
                }
                .padding()

                if viewModel.hasMore {
                    Button("Load More") {
                        viewModel.loadMore()
                    }
                    .padding()
                    .accessibilityLabel("Load more phrases")
                    .accessibilityHint("Loads additional phrases")
                }
            }
            .accessibilityLabel("Phrase grid")
        } else {
            List(viewModel.phrases, id: \.id) { phrase in
                NavigationLink(destination: CommunityPhraseDetailView(phrase: phrase)) {
                    CommunityPhraseCell(phrase: phrase)
                }
                .accessibilityLabel("Phrase: \(phrase.name ?? "Unknown")")
                .accessibilityHint("Double tap to view details")
            }
            .listStyle(PlainListStyle())
            .accessibilityLabel("Phrase list")
        }
    }
}

@MainActor
class CommunityPhraseBrowserViewModel: ObservableObject {
    @Published var phrases: [CommunityPhrase] = []
    @Published var isLoading = false
    @Published var hasMore = false
    @Published var minQualityFilter: Double? = nil
    @Published var sortOption: SortOption = .quality

    private let searchService = CommunityPhraseSearchService.shared
    private var currentPage = 0
    private let pageSize = 20

    func loadPhrases() {
        isLoading = true
        currentPage = 0
        phrases = searchService.getPhrases(
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
            loadPhrases()
            return
        }
        phrases = searchService.getPhrases(
            searchQuery: query,
            minQuality: minQualityFilter,
            sortBy: .relevance,
            offset: 0,
            limit: pageSize
        )
        hasMore = phrases.count == pageSize
        isLoading = false
    }

    func refresh() async {
        await withCheckedContinuation { continuation in
            CommunityPhraseCacheManager.shared.syncWithCloud { result in
                if case .success = result {
                    Task { @MainActor in loadPhrases() }
                }
                continuation.resume()
            }
        }
    }

    func loadMore() {
        currentPage += 1
        let morePhrases = searchService.getPhrases(
            minQuality: minQualityFilter,
            sortBy: sortOption,
            offset: currentPage * pageSize,
            limit: pageSize
        )
        phrases.append(contentsOf: morePhrases)
        hasMore = morePhrases.count == pageSize
    }
}
