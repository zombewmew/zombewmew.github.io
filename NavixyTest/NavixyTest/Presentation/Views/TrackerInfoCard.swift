import SwiftUI

struct TrackerInfoCard: View {
    let tracker: TrackerEntity
    var showCoordinates: Bool = true
    var showLabel: Bool = true
    var showHeading: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showLabel {
                trackerField(title: "Label", value: tracker.label)
            }
            trackerField(title: "Model", value: tracker.model ?? "Unknown")
            trackerField(title: "Device ID", value: tracker.deviceID ?? "Unknown")

            if showCoordinates {
                trackerField(title: "Latitude", value: formattedCoordinate(latitude))
                trackerField(title: "Longitude", value: formattedCoordinate(longitude))
                if showHeading {
                    trackerField(title: "Heading", value: formattedHeading)
                }
            }
        }
    }

    @ViewBuilder
    private func trackerField(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.body)
                .foregroundStyle(.primary)
        }
    }

    private var latitude: Double? {
        tracker.hasValidLocation ? tracker.latitude : nil
    }

    private var longitude: Double? {
        tracker.hasValidLocation ? tracker.longitude : nil
    }

    private var formattedHeading: String {
        guard tracker.hasValidLocation else { return "No data" }
        return "\(Int(tracker.heading.rounded()))°"
    }

    private func formattedCoordinate(_ value: Double?) -> String {
        guard let value else { return "No data" }
        return String(format: "%.6f", value)
    }
}
