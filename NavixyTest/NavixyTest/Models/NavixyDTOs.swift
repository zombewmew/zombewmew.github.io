import Foundation

struct APIStatus: Decodable, Error, Sendable {
    let code: Int
    let description: String
}

enum APIClientError: Error {
    case unsuccessfulResponse
    case emptyPayload
    case unexpectedAuthResponse
    case backend(APIStatus)

    var isInvalidSession: Bool {
        if case let .backend(status) = self {
            return status.code == 4
        }
        return false
    }
}

struct AuthResponse: Decodable {
    let type: String
    let hash: String?
}

struct TrackersResponse: Decodable {
    let list: [Tracker]
}

struct TrackerStatesResponse: Decodable {
    let states: [String: TrackerState]
}

struct APIEnvelope<Payload: Decodable>: Decodable {
    let success: Bool
    let status: APIStatus?
    let payload: Payload?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        success = try container.decodeIfPresent(Bool.self, forKey: .init("success")) ?? false
        status = try container.decodeIfPresent(APIStatus.self, forKey: .init("status"))
        payload = try? Payload(from: decoder)
    }
}

struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(_ stringValue: String) {
        self.stringValue = stringValue
    }

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}
