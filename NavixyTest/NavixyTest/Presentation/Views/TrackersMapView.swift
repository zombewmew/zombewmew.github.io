import CoreData
import MapKit
import SwiftUI

struct TrackersMapView: View {
    @Environment(\.scenePhase) private var scenePhase
    @FetchRequest(fetchRequest: TrackerEntity.sortedFetchRequest(), animation: .default)
    private var trackers: FetchedResults<TrackerEntity>

    private let appEnvironment: AppEnvironment?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var selectedTrackerID: NSManagedObjectID?
    @StateObject private var pollingViewModel: TrackerStatesPollingViewModel

    init(appEnvironment: AppEnvironment? = nil, pollingViewModel: TrackerStatesPollingViewModel) {
        self.appEnvironment = appEnvironment
        _pollingViewModel = StateObject(wrappedValue: pollingViewModel)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition) {
                ForEach(trackersWithCoordinates) { tracker in
                    if let coordinate = tracker.coordinate {
                        Annotation("", coordinate: coordinate, anchor: .bottom) {
                            Button {
                                focusOnTracker(tracker, zoomDelta: 0.008)
                            } label: {
                                VStack(spacing: 6) {
                                    Image("Arrow")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 36, height: 36)
                                        .rotationEffect(.degrees(markerRotation(for: tracker)))
                                        .animation(.easeInOut(duration: 0.25), value: tracker.heading)

                                    Text(tracker.label)
                                        .font(.caption.weight(.medium))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.thinMaterial, in: Capsule())
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .onTapGesture {
                selectedTrackerID = nil
            }
            .onMapCameraChange(frequency: .continuous) { context in
                visibleRegion = context.region
            }

            VStack(spacing: 8) {
                if let bannerMessage = pollingViewModel.bannerMessage {
                    Text(bannerMessage)
                        .font(.footnote)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.orange.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if trackersWithCoordinates.isEmpty {
                    Text("No coordinates yet. Open tracker details or wait for polling to update positions.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                HStack {
                    Spacer()

                    VStack(spacing: 10) {
                        mapZoomButton(symbol: "location.viewfinder") {
                            selectedTrackerID = nil
                            updateCameraToAllTrackers(animated: true)
                        }

                        mapZoomButton(symbol: "plus") {
                            adjustZoom(scale: 0.5)
                        }

                        mapZoomButton(symbol: "minus") {
                            adjustZoom(scale: 2.0)
                        }
                    }
                }
            }
            .padding()

            VStack {
                Spacer()

                if let selectedTracker {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            Spacer()

                            Button {
                                selectedTrackerID = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }

                        TrackerInfoCard(
                            tracker: selectedTracker,
                            showLabel: false,
                            showHeading: false
                        )
                    }
                    .padding(16)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
                    .padding()
                }
            }
        }
        .toolbar {
            if let appEnvironment {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink("Trackers") {
                        TrackerListView(
                            appEnvironment: appEnvironment,
                            viewModel: appEnvironment.makeTrackerListViewModel()
                        )
                    }
                }
            }
        }
        .onAppear {
            pollingViewModel.updateTrackerIDs(trackers.map(\.id))
            pollingViewModel.onAppear()
            updateCameraPosition()
        }
        .onDisappear {
            pollingViewModel.onDisappear()
        }
        .onChange(of: scenePhase) { _, newValue in
            pollingViewModel.scenePhaseChanged(newValue)
        }
        .onChange(of: trackers.map(\.id)) { _, newValue in
            pollingViewModel.updateTrackerIDs(newValue)
        }
        .onChange(of: trackersWithCoordinates.map(\.id)) { _, _ in
            updateCameraPosition()
        }
    }

    private var trackersWithCoordinates: [TrackerEntity] {
        trackers.filter(\.hasValidLocation)
    }

    private func updateCameraPosition() {
        updateCameraToAllTrackers(animated: false)
    }

    private func updateCameraToAllTrackers(animated: Bool) {
        guard !trackersWithCoordinates.isEmpty else { return }

        let coordinates = trackersWithCoordinates.compactMap(\.coordinate)
        guard let first = coordinates.first else { return }

        let minLatitude = coordinates.map(\.latitude).min() ?? first.latitude
        let maxLatitude = coordinates.map(\.latitude).max() ?? first.latitude
        let minLongitude = coordinates.map(\.longitude).min() ?? first.longitude
        let maxLongitude = coordinates.map(\.longitude).max() ?? first.longitude

        let center = CLLocationCoordinate2D(
            latitude: (minLatitude + maxLatitude) / 2,
            longitude: (minLongitude + maxLongitude) / 2
        )

        let latitudeDelta = max((maxLatitude - minLatitude) * 1.5, 0.02)
        let longitudeDelta = max((maxLongitude - minLongitude) * 1.5, 0.02)

        let region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        )
        setCamera(region, animated: animated)
    }

    private var selectedTracker: TrackerEntity? {
        guard let selectedTrackerID else { return nil }
        return trackers.first { $0.objectID == selectedTrackerID }
    }

    private func markerRotation(for tracker: TrackerEntity) -> Double {
        guard tracker.hasValidLocation else { return 0 }
        return tracker.heading
    }

    private func focusOnTracker(_ tracker: TrackerEntity, zoomDelta: CLLocationDegrees) {
        guard let coordinate = tracker.coordinate else { return }

        selectedTrackerID = tracker.objectID
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: zoomDelta, longitudeDelta: zoomDelta)
        )
        setCamera(region, animated: true)
    }

    private func adjustZoom(scale: Double) {
        let baseRegion = visibleRegion ?? fallbackRegion()
        guard let baseRegion else { return }

        let latitudeDelta = min(max(baseRegion.span.latitudeDelta * scale, 0.002), 120)
        let longitudeDelta = min(max(baseRegion.span.longitudeDelta * scale, 0.002), 120)
        let region = MKCoordinateRegion(
            center: baseRegion.center,
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        )

        setCamera(region, animated: true)
    }

    private func fallbackRegion() -> MKCoordinateRegion? {
        guard let tracker = trackersWithCoordinates.first, let coordinate = tracker.coordinate else {
            return nil
        }

        return MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    }

    private func setCamera(_ region: MKCoordinateRegion, animated: Bool) {
        visibleRegion = region

        if animated {
            withAnimation(.easeInOut(duration: 0.8)) {
                cameraPosition = .region(region)
            }
        } else {
            cameraPosition = .region(region)
        }
    }

    @ViewBuilder
    private func mapZoomButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(width: 36, height: 36)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
