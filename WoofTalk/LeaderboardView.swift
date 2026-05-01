import SwiftUI
import CoreData

struct LeaderboardView: View {
    @StateObject private var manager = LeaderboardManager.shared
    @State private var selectedTab = 0
    @State private var activeDogs: [DogProfile] = []

    var body: some View {
        NavigationView {
            VStack {
                Picker("Category", selection: $selectedTab) {
                    Text("Translators").tag(0)
                    Text("Active Dogs").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                if selectedTab == 0 {
                    List(manager.entries) { entry in
                        HStack(spacing: 14) {
                            Text("#\(entry.rank)")
                                .font(.headline.monospacedDigit())
                                .foregroundColor(rankColor(entry.rank))
                                .frame(width: 40)
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                            VStack(alignment: .leading) {
                                Text(entry.displayName).font(.headline)
                                Text("\(entry.contributionCount) translations").font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\(entry.score) pts").font(.subheadline.bold()).foregroundColor(.accentColor)
                        }
                        .padding(.vertical, 4)
                    }
                } else {
                    List(Array(activeDogs.enumerated()), id: \.element.id) { index, dog in
                        HStack(spacing: 14) {
                            Text("#\(index + 1)")
                                .font(.headline.monospacedDigit())
                                .foregroundColor(rankColor(index + 1))
                                .frame(width: 40)
                            if let data = dog.photoData, let image = UIImage(data: data) {
                                Image(uiImage: image).resizable().frame(width: 40, height: 40).clipShape(Circle())
                            } else {
                                Image(systemName: "pawprint.circle.fill").font(.title2).foregroundColor(.accentColor)
                            }
                            VStack(alignment: .leading) {
                                Text(dog.name ?? "Unnamed").font(.headline)
                                Text(dog.displayBreed).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            if let owner = dog.owner {
                                Text(owner.username ?? "").font(.caption).foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Leaderboard")
            .onAppear {
                manager.refresh()
                loadActiveDogs()
            }
            .refreshable {
                manager.refresh()
                loadActiveDogs()
            }
        }
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .brown
        default: return .secondary
        }
    }

    private func loadActiveDogs() {
        let fetchRequest: NSFetchRequest<CommunityPhrase> = CommunityPhrase.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "usageCount", ascending: false)]

        let phrases = (try? PersistenceController.shared.container.viewContext.fetch(fetchRequest)) ?? []
        let dogManager = DogProfileManager.shared
        let allDogs = dogManager.getAllDogs()
        let topOwners = Array(Set(phrases.prefix(20).compactMap { $0.submitter }))
        activeDogs = allDogs.filter { dog in topOwners.contains { $0.id == dog.owner?.id } }.prefix(10).map { $0 }
    }
}

#if DEBUG
struct LeaderboardView_Previews: PreviewProvider {
    static var previews: some View {
        LeaderboardView()
    }
}
#endif
