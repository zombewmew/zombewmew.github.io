import Combine
import Foundation

@MainActor
final class TrackerListViewModel: ObservableObject {
    @Published private(set) var isRefreshing = false
    @Published var bannerMessage: String?

    private let repository: TrackerRepository
    private var initialRefreshTriggered = false

    init(repository: TrackerRepository) {
        self.repository = repository
    }

    func onFirstAppear() {
        guard !initialRefreshTriggered else { return }
        initialRefreshTriggered = true
        Task {
            await refresh()
        }
    }

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            try await repository.refreshTrackers()
            bannerMessage = nil
        } catch {
            bannerMessage = errorMessage(for: error)
        }
    }

    private func errorMessage(for error: Error) -> String {
        if error is URLError {
            return "No internet connection. Showing saved trackers."
        }

        if let apiError = error as? APIClientError,
           case let .backend(status) = apiError {
            return "Refresh failed: \(status.description)"
        }

        return "Refresh failed. Showing saved trackers."
    }
}
