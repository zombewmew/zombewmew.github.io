import CoreData
import SwiftUI

struct TrackerListView: View {
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @FetchRequest(fetchRequest: TrackerEntity.sortedFetchRequest(), animation: .default)
    private var trackers: FetchedResults<TrackerEntity>

    private let appEnvironment: AppEnvironment
    @StateObject private var viewModel: TrackerListViewModel

    init(appEnvironment: AppEnvironment, viewModel: TrackerListViewModel) {
        self.appEnvironment = appEnvironment
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            List(trackers) { tracker in
                NavigationLink {
                    TrackerDetailView(
                        tracker: tracker,
                        pollingViewModel: appEnvironment.makeTrackerStatesPollingViewModel(trackerIDs: [tracker.id])
                    )
                } label: {
                    Text(tracker.label)
                        .font(.body)
                    .padding(.vertical, 4)
                }
            }
            .overlay {
                if trackers.isEmpty && viewModel.isRefreshing {
                    ProgressView("Loading trackers...")
                } else if trackers.isEmpty {
                    ContentUnavailableView(
                        "No trackers yet",
                        systemImage: "antenna.radiowaves.left.and.right",
                        description: Text("Pull to refresh when the network is available.")
                    )
                }
            }
        }
        .navigationTitle("Trackers")
        .safeAreaInset(edge: .top) {
            VStack(spacing: 8) {
                if viewModel.isRefreshing {
                    StatusBanner(message: "Refreshing trackers...")
                }

                if networkMonitor.isOffline {
                    StatusBanner(message: "Offline mode. Showing saved trackers.")
                }

                if let bannerMessage = viewModel.bannerMessage {
                    StatusBanner(message: bannerMessage, tint: .orange)
                }
            }
            .padding(.horizontal)
        }
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            viewModel.onFirstAppear()
        }
    }
}

private struct StatusBanner: View {
    let message: String
    var tint: Color = .blue

    var body: some View {
        Text(message)
            .font(.footnote)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(tint.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    TrackerListView(
        appEnvironment: AppEnvironment(),
        viewModel: AppEnvironment().makeTrackerListViewModel()
    )
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(NetworkMonitor())
}
