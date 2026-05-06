import CoreData
import CoreLocation
import Foundation

@objc(TrackerEntity)
final class TrackerEntity: NSManagedObject, Identifiable {
    @NSManaged var id: Int64
    @NSManaged var label: String
    @NSManaged var model: String?
    @NSManaged var deviceID: String?
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var hasValidLocation: Bool
    @NSManaged var heading: Double
}

extension TrackerEntity {
    @nonobjc static func fetchRequest() -> NSFetchRequest<TrackerEntity> {
        NSFetchRequest<TrackerEntity>(entityName: "TrackerEntity")
    }

    static func sortedFetchRequest() -> NSFetchRequest<TrackerEntity> {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(TrackerEntity.label), ascending: true)]
        return request
    }

    var coordinate: CLLocationCoordinate2D? {
        guard hasValidLocation else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
