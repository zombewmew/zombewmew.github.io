import Foundation

struct TrackerState: Decodable, Sendable {
    let gps: GPSState?
}

struct GPSState: Decodable, Sendable {
    let lat: Double?
    let lng: Double?
    let heading: Double?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let location = try container.decodeIfPresent(Location.self, forKey: .location)
        let fallbackLat = try container.decodeIfPresent(Double.self, forKey: .lat)
        let fallbackLng = try container.decodeIfPresent(Double.self, forKey: .lng)
        let fallbackLon = try container.decodeIfPresent(Double.self, forKey: .lon)

        lat = location?.lat ?? fallbackLat
        lng = location?.lng ?? location?.lon ?? fallbackLng ?? fallbackLon
        heading =
            try container.decodeIfPresent(Double.self, forKey: .heading) ??
            (try container.decodeIfPresent(Int.self, forKey: .heading)).map(Double.init)
    }

    private enum CodingKeys: String, CodingKey {
        case lat
        case lng
        case lon
        case location
        case heading
    }

    private struct Location: Decodable, Sendable {
        let lat: Double?
        let lng: Double?
        let lon: Double?
    }
}
