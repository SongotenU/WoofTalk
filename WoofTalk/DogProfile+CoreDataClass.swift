import Foundation
import CoreData
import SwiftUI

@objc(DogProfile)
public class DogProfile: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var breed: String?
    @NSManaged public var photoData: Data?
    @NSManaged public var bio: String?
    @NSManaged public var age: Int16
    @NSManaged public var createdDate: Date?
    @NSManaged public var owner: User?
    @NSManaged public var phrases: NSSet?

    static func create(name: String, breed: String, owner: User, context: NSManagedObjectContext,
                      photoData: Data? = nil, bio: String? = nil, age: Int16 = 0) -> DogProfile {
        let dog = DogProfile(context: context)
        dog.id = UUID()
        dog.name = name
        dog.breed = breed
        dog.photoData = photoData
        dog.bio = bio
        dog.age = age
        dog.createdDate = Date()
        dog.owner = owner
        return dog
    }

    var displayAge: String {
        guard age > 0 else { return "Age unknown" }
        return age == 1 ? "1 year old" : "\(age) years old"
    }

    var displayBreed: String { breed ?? "Unknown breed" }

    var photoImage: UIImage? {
        guard let data = photoData else { return nil }
        return UIImage(data: data)
    }
}

// MARK: - DogProfileManager

final class DogProfileManager {
    static let shared = DogProfileManager(context: PersistenceController.shared.container.viewContext)
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func getDogs(for user: User) -> [DogProfile] {
        let fetchRequest: NSFetchRequest<DogProfile> = DogProfile.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "owner == %@", user)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return (try? context.fetch(fetchRequest)) ?? []
    }

    func getAllDogs() -> [DogProfile] {
        let fetchRequest: NSFetchRequest<DogProfile> = DogProfile.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return (try? context.fetch(fetchRequest)) ?? []
    }

    func getDog(by id: UUID) -> DogProfile? {
        let fetchRequest: NSFetchRequest<DogProfile> = DogProfile.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        return try? context.fetch(fetchRequest).first
    }

    func deleteDog(_ dog: DogProfile) throws {
        context.delete(dog)
        try context.save()
    }
}

// MARK: - FetchRequest extension

extension DogProfile {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DogProfile> {
        return NSFetchRequest<DogProfile>(entityName: "DogProfile")
    }
}
