import SwiftUI
import CoreData

struct DogProfileView: View {
    let dog: DogProfile
    @State private var dogImage: UIImage?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Photo
                if let image = dogImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 150, height: 150)
                        .overlay(Image(systemName: "pawprint.fill").font(.system(size: 50)).foregroundColor(.gray))
                }

                // Name and breed
                VStack(spacing: 4) {
                    Text(dog.name ?? "Unnamed")
                        .font(.title.bold())
                    Text(dog.displayBreed)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(dog.displayAge)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Bio
                if let bio = dog.bio, !bio.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.headline)
                        Text(bio)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }

                // Owner
                if let owner = dog.owner {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Owner")
                            .font(.headline)
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                            Text(owner.username ?? "Unknown")
                                .font(.body)
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }

                // Phrases by this dog's owner
                if let phrases = dog.owner.flatMap({ DogProfileManager.shared.getDogs(for: $0) }),
                   !phrases.isEmpty {
                    Text("This owner has \(phrases.count) dog(s)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle(dog.name ?? "Dog Profile")
        .onAppear { dogImage = dog.photoImage }
    }
}

// MARK: - DogProfileListView

struct DogProfileListView: View {
    @StateObject private var manager = DogProfileManager.shared
    @State private var dogs: [DogProfile] = []
    @State private var showingAddDog = false

    var body: some View {
        NavigationView {
            List(dogs, id: \.id) { dog in
                NavigationLink(destination: DogProfileView(dog: dog)) {
                    HStack(spacing: 12) {
                        if let imageData = dog.photoData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 50, height: 50)
                                .overlay(Image(systemName: "pawprint.fill").foregroundColor(.gray))
                        }
                        VStack(alignment: .leading) {
                            Text(dog.name ?? "Unnamed").font(.headline)
                            Text(dog.displayBreed).font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Dogs")
            .onAppear { loadDogs() }
            .refreshable { loadDogs() }
        }
    }

    private func loadDogs() {
        guard let user = UserProfileManager.currentUser else { return }
        dogs = manager.getDogs(for: user)
    }
}

#if DEBUG
struct DogProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let dog = DogProfile.create(name: "Buddy", breed: "Golden Retriever", owner: User.mockUser, context: context)
        return DogProfileView(dog: dog)
    }
}
#endif
