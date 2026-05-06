import Foundation

final class AppEnvironment {
    let persistenceController: PersistenceController
    let networkMonitor: NetworkMonitor

    private let repository: TrackerRepository

    init(
        persistenceController: PersistenceController = .shared,
        networkMonitor: NetworkMonitor = NetworkMonitor()
    ) {
        self.persistenceController = persistenceController
        self.networkMonitor = networkMonitor

        let sessionStore = SessionStore()
        let apiClient = NavixyAPIClient()
        self.repository = TrackerRepository(
            apiClient: apiClient,
            persistenceController: persistenceController,
            sessionStore: sessionStore
        )
    }

    func makeTrackerListViewModel() -> TrackerListViewModel {
        TrackerListViewModel(repository: repository)
    }

    func makeTrackerStatesPollingViewModel(trackerIDs: [Int64]) -> TrackerStatesPollingViewModel {
        TrackerStatesPollingViewModel(repository: repository, trackerIDs: trackerIDs)
    }
}
