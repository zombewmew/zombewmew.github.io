import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = Self.makeManagedObjectModel()
        container = NSPersistentContainer(name: "NavixyTest", managedObjectModel: model)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load persistent stores: \(error)")
            }
        }

        let viewContext = container.viewContext
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        viewContext.shouldDeleteInaccessibleFaults = true

        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: nil,
            queue: nil
        ) { notification in
            guard let savedContext = notification.object as? NSManagedObjectContext else { return }
            guard savedContext !== viewContext else { return }
            guard savedContext.persistentStoreCoordinator === viewContext.persistentStoreCoordinator else { return }

            viewContext.perform {
                viewContext.mergeChanges(fromContextDidSave: notification)
            }
        }
    }

    func makeBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    private static func makeManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let trackerEntity = NSEntityDescription()
        trackerEntity.name = "TrackerEntity"
        trackerEntity.managedObjectClassName = NSStringFromClass(TrackerEntity.self)

        let id = NSAttributeDescription()
        id.name = "id"
        id.attributeType = .integer64AttributeType
        id.isOptional = false

        let label = NSAttributeDescription()
        label.name = "label"
        label.attributeType = .stringAttributeType
        label.isOptional = false

        let modelName = NSAttributeDescription()
        modelName.name = "model"
        modelName.attributeType = .stringAttributeType
        modelName.isOptional = true

        let deviceID = NSAttributeDescription()
        deviceID.name = "deviceID"
        deviceID.attributeType = .stringAttributeType
        deviceID.isOptional = true

        let latitude = NSAttributeDescription()
        latitude.name = "latitude"
        latitude.attributeType = .doubleAttributeType
        latitude.isOptional = false
        latitude.defaultValue = 0.0

        let longitude = NSAttributeDescription()
        longitude.name = "longitude"
        longitude.attributeType = .doubleAttributeType
        longitude.isOptional = false
        longitude.defaultValue = 0.0

        let hasValidLocation = NSAttributeDescription()
        hasValidLocation.name = "hasValidLocation"
        hasValidLocation.attributeType = .booleanAttributeType
        hasValidLocation.isOptional = false
        hasValidLocation.defaultValue = false

        let heading = NSAttributeDescription()
        heading.name = "heading"
        heading.attributeType = .doubleAttributeType
        heading.isOptional = false
        heading.defaultValue = 0.0

        trackerEntity.properties = [
            id,
            label,
            modelName,
            deviceID,
            latitude,
            longitude,
            hasValidLocation,
            heading
        ]
        model.entities = [trackerEntity]

        return model
    }
}
