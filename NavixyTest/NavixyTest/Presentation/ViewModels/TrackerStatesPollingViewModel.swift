import Combine
import SwiftUI

@MainActor
final class TrackerStatesPollingViewModel: ObservableObject {
    @Published var bannerMessage: String?

    private let repository: TrackerRepository
    private let pollIntervalNanoseconds: UInt64 = 5_000_000_000

    private var trackerIDs: [Int64]
    private var pollTask: Task<Void, Never>?
    private var isScreenVisible = false
    private var isAppActive = true

    init(repository: TrackerRepository, trackerIDs: [Int64]) {
        self.repository = repository
        self.trackerIDs = trackerIDs
    }

    func updateTrackerIDs(_ trackerIDs: [Int64]) {
        self.trackerIDs = trackerIDs
        restartPollingIfNeeded()
    }

    func onAppear() {
        isScreenVisible = true
        restartPollingIfNeeded()
    }

    func onDisappear() {
        isScreenVisible = false
        stopPolling()
    }

    func scenePhaseChanged(_ scenePhase: ScenePhase) {
        isAppActive = scenePhase == .active
        restartPollingIfNeeded()
    }

    deinit {
        pollTask?.cancel()
    }

    private func restartPollingIfNeeded() {
        let shouldPoll = isScreenVisible && isAppActive && !trackerIDs.isEmpty
        if shouldPoll {
            startPollingIfNeeded()
        } else {
            stopPolling()
        }
    }

    private func startPollingIfNeeded() {
        guard pollTask == nil else { return }

        pollTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                do {
                    try await self.repository.refreshTrackerStates(trackerIDs: self.trackerIDs)
                    await MainActor.run {
                        self.bannerMessage = nil
                    }
                } catch {
                    await MainActor.run {
                        self.bannerMessage = self.errorMessage(for: error)
                    }
                }

                do {
                    try await Task.sleep(nanoseconds: self.pollIntervalNanoseconds)
                } catch {
                    break
                }
            }
        }
    }

    private func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    private func errorMessage(for error: Error) -> String {
        if error is URLError {
            return "Could not update coordinates. Showing saved position."
        }

        if let apiError = error as? APIClientError,
           case let .backend(status) = apiError {
            return "Coordinate refresh failed: \(status.description)"
        }

        return "Could not update coordinates. Showing saved position."
    }
}
