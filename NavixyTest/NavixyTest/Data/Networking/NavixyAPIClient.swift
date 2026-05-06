import Foundation

struct NavixyAPIClient {
    private let baseURL = Constants.API.baseURL
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    func authenticate(login: String, password: String) async throws -> String {
        let response: AuthResponse = try await send(
            path: "user/auth",
            body: [
                "login": login,
                "password": password
            ]
        )

        guard response.type == "authenticated", let hash = response.hash else {
            throw APIClientError.unexpectedAuthResponse
        }

        return hash
    }

    func fetchTrackers(hash: String) async throws -> [Tracker] {
        let response: TrackersResponse = try await send(
            path: "tracker/list",
            body: ["hash": hash]
        )

        return response.list
    }

    func fetchTrackerStates(hash: String, trackerIDs: [Int64]) async throws -> [Int64: TrackerState] {
        let response: TrackerStatesResponse = try await send(
            path: "tracker/get_states",
            body: [
                "hash": hash,
                "trackers": trackerIDs,
                "list_blocked": true,
                "allow_not_exist": true
            ]
        )

        var result: [Int64: TrackerState] = [:]
        for (key, value) in response.states {
            guard let trackerID = Int64(key) else { continue }
            result[trackerID] = value
        }
        return result
    }

    private func send<Response: Decodable>(path: String, body: [String: Any]) async throws -> Response {
        let url = baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        logRequest(request)

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            print("HTTP error: \(error)")
            throw error
        }

        logResponse(data: data, response: response)

        let envelope = try decoder.decode(APIEnvelope<Response>.self, from: data)
        if let status = envelope.status {
            throw APIClientError.backend(status)
        }

        guard envelope.success else {
            throw APIClientError.unsuccessfulResponse
        }

        guard let value = envelope.payload else {
            throw APIClientError.emptyPayload
        }

        return value
    }

    private func logRequest(_ request: URLRequest) {
        let url = request.url?.absoluteString ?? "unknown-url"
        let body = request.httpBody.flatMap { String(data: $0, encoding: .utf8) } ?? "<empty>"
        print("➡️ \(request.httpMethod ?? "POST") \(url)")
        print("➡️ body: \(body)")
    }

    private func logResponse(data: Data, response: URLResponse) {
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        let body = String(data: data, encoding: .utf8) ?? "<non-utf8-body>"
        print("⬅️ status: \(statusCode)")
        print("⬅️ body: \(body)")
    }
}
