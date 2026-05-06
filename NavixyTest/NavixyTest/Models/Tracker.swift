import Foundation

struct Tracker: Decodable, Identifiable, Sendable {
    struct Source: Decodable, Sendable {
        let deviceID: String?
        let model: String?

        enum CodingKeys: String, CodingKey {
            case deviceID = "device_id"
            case model
        }
    }

    let id: Int
    let label: String
    let source: Source
}
