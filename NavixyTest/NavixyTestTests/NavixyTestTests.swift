import Foundation
import Testing
@testable import NavixyTest

struct NavixyTestTests {

    @Test
    func trackerDecodingMapsSourceFields() throws {
        let data = """
        {
          "id": 101,
          "label": "Courier Car",
          "source": {
            "device_id": "359111111111111",
            "model": "navixy-mobile"
          }
        }
        """.data(using: .utf8)!

        let tracker = try JSONDecoder().decode(Tracker.self, from: data)

        #expect(tracker.id == 101)
        #expect(tracker.label == "Courier Car")
        #expect(tracker.source.deviceID == "359111111111111")
        #expect(tracker.source.model == "navixy-mobile")
    }

    @Test
    func gpsDecodingReadsNestedLocationAndIntHeading() throws {
        let data = """
        {
          "gps": {
            "location": {
              "lat": 52.25258,
              "lng": 21.036773
            },
            "heading": 45
          }
        }
        """.data(using: .utf8)!

        let state = try JSONDecoder().decode(TrackerState.self, from: data)

        #expect(state.gps?.lat == 52.25258)
        #expect(state.gps?.lng == 21.036773)
        #expect(state.gps?.heading == 45.0)
    }

    @Test
    func gpsDecodingFallsBackToLonWhenLngMissing() throws {
        let data = """
        {
          "gps": {
            "location": {
              "lat": 48.14755666666667,
              "lon": 16.414931666666668
            },
            "heading": 90.5
          }
        }
        """.data(using: .utf8)!

        let state = try JSONDecoder().decode(TrackerState.self, from: data)

        #expect(state.gps?.lat == 48.14755666666667)
        #expect(state.gps?.lng == 16.414931666666668)
        #expect(state.gps?.heading == 90.5)
    }

    @Test
    func sessionStorePersistsAndClearsHash() {
        let suiteName = "NavixyTestTests.SessionStore"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let store = SessionStore(defaults: defaults)

        #expect(store.sessionHash == nil)

        store.sessionHash = "demo-hash"
        #expect(store.sessionHash == "demo-hash")

        store.clear()
        #expect(store.sessionHash == nil)

        defaults.removePersistentDomain(forName: suiteName)
    }

    @Test
    func invalidSessionErrorIsDetectedFromBackendCode() {
        let invalidSessionError = APIClientError.backend(APIStatus(code: 4, description: "Invalid session"))
        let genericError = APIClientError.backend(APIStatus(code: 1, description: "Other error"))

        #expect(invalidSessionError.isInvalidSession)
        #expect(genericError.isInvalidSession == false)
    }
}
