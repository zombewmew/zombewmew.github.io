import SwiftUI

struct TrackerDetailView: View {
    @Environment(\.scenePhase) private var scenePhase

    @ObservedObject var tracker: TrackerEntity
    @StateObject private var pollingViewModel: TrackerStatesPollingViewModel

    init(tracker: TrackerEntity, pollingViewModel: TrackerStatesPollingViewModel) {
        self.tracker = tracker
        _pollingViewModel = StateObject(wrappedValue: pollingViewModel)
    }

    var body: some View {
        List {
            if let bannerMessage = pollingViewModel.bannerMessage {
                Section {
                    Text(bannerMessage)
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }

            Section("Tracker") {
                TrackerInfoCard(
                    tracker: tracker,
                    showLabel: false,
                    showHeading: false
                )
                    .padding(.vertical, 4)
            }
        }
        .navigationTitle(tracker.label)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            pollingViewModel.onAppear()
        }
        .onDisappear {
            pollingViewModel.onDisappear()
        }
        .onChange(of: scenePhase) { _, newValue in
            pollingViewModel.scenePhaseChanged(newValue)
        }
    }
}
