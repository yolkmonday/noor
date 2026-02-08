import CoreData

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    private init() {
        // Create model programmatically
        let model = NSManagedObjectModel()
        model.entities = [
            PrayerLog.entityDescription(),
            AzanAudio.entityDescription()
        ]

        container = NSPersistentContainer(name: "Noor", managedObjectModel: model)

        // Store in Application Support
        let storeURL = PersistenceController.storeURL()
        let description = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    private static func storeURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let noorDir = appSupport.appendingPathComponent("Noor", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: noorDir, withIntermediateDirectories: true)

        return noorDir.appendingPathComponent("Noor.sqlite")
    }

    func save() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error.localizedDescription)")
            }
        }
    }
}
