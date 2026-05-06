import SwiftUI

struct RootMapView: View {
    private let appEnvironment: AppEnvironment

    init(appEnvironment: AppEnvironment) {
        self.appEnvironment = appEnvironment
    }

    var body: some View {
        NavigationStack {
            TrackersMapView(
                appEnvironment: appEnvironment,
                pollingViewModel: appEnvironment.makeTrackerStatesPollingViewModel(trackerIDs: [])
            )
        }
    }
}
