import CoreData
import Foundation

final class TrackerRepository {
    private let apiClient: NavixyAPIClient
    private let persistenceController: PersistenceController
    private let sessionStore: SessionStore

    init(
        apiClient: NavixyAPIClient,
        persistenceController: PersistenceController,
        sessionStore: SessionStore
    ) {
        self.apiClient = apiClient
        self.persistenceController = persistenceController
        self.sessionStore = sessionStore
    }

    func refreshTrackers() async throws {
        do {
            let hash = try await validSessionHash()
            let trackers = try await apiClient.fetchTrackers(hash: hash)
            try await persist(trackers: trackers)
        } catch let error as APIClientError where error.isInvalidSession {
            sessionStore.clear()
            let hash = try await validSessionHash()
            let trackers = try await apiClient.fetchTrackers(hash: hash)
            try await persist(trackers: trackers)
        }
    }

    func refreshTrackerStates(trackerIDs: [Int64]) async throws {
        guard !trackerIDs.isEmpty else { return }

        do {
            let hash = try await validSessionHash()
            let states = try await apiClient.fetchTrackerStates(hash: hash, trackerIDs: trackerIDs)
            try await persist(states: states)
        } catch let error as APIClientError where error.isInvalidSession {
            sessionStore.clear()
            let hash = try await validSessionHash()
            let states = try await apiClient.fetchTrackerStates(hash: hash, trackerIDs: trackerIDs)
            try await persist(states: states)
        }
    }

    private func validSessionHash() async throws -> String {
        if let existingHash = sessionStore.sessionHash, !existingHash.isEmpty {
            return existingHash
        }

        let hash = try await apiClient.authenticate(
            login: Constants.DemoCredentials.login,
            password: Constants.DemoCredentials.password
        )
        sessionStore.sessionHash = hash
        return hash
    }

    private func persist(trackers: [Tracker]) async throws {
        let context = persistenceController.makeBackgroundContext()

        try await context.perform {
            let request = TrackerEntity.fetchRequest()
            let existingTrackers = try context.fetch(request)
            var existingByID = Dictionary(uniqueKeysWithValues: existingTrackers.map { ($0.id, $0) })
            let incomingIDs = Set(trackers.map { Int64($0.id) })

            for tracker in trackers {
                let entity = existingByID.removeValue(forKey: Int64(tracker.id)) ?? TrackerEntity(context: context)
                entity.id = Int64(tracker.id)
                entity.label = tracker.label
                entity.model = tracker.source.model
                entity.deviceID = tracker.source.deviceID
            }

            for staleTracker in existingTrackers where !incomingIDs.contains(staleTracker.id) {
                context.delete(staleTracker)
            }

            if context.hasChanges {
                try context.save()
            }
        }
    }

    private func persist(states: [Int64: TrackerState]) async throws {
        let context = persistenceController.makeBackgroundContext()

        try await context.perform {
            guard !states.isEmpty else { return }

            let request = TrackerEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id IN %@", states.keys.map(NSNumber.init(value:)))
            let trackers = try context.fetch(request)
            let trackersByID = Dictionary(uniqueKeysWithValues: trackers.map { ($0.id, $0) })

            for (trackerID, state) in states {
                guard let tracker = trackersByID[trackerID] else {
                    continue
                }

                guard let gps = state.gps else {
                    continue
                }

                guard let latitude = gps.lat, let longitude = gps.lng else {
                    continue
                }

                tracker.latitude = latitude
                tracker.longitude = longitude
                tracker.heading = gps.heading ?? 0
                tracker.hasValidLocation = true
            }

            if context.hasChanges {
                try context.save()
            }
        }
    }
}
