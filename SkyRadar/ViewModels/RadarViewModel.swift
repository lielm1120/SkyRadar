import SwiftUI
import MapKit

/// Main view model for the radar screen.
/// Manages aircraft data, polling, filtering, and map state.
@MainActor @Observable
final class RadarViewModel {

    // MARK: - Published State

    var aircraft: [Aircraft] = []
    var selectedAircraft: Aircraft?
    var selectedRegion: MapBoundingBox = AppConstants.defaultRegion

    var isLoading = false
    var isPolling = false
    var lastUpdateTime: Date?
    var error: String?

    // Filters
    var showGroundAircraft = false
    var minimumAltitudeFt: Double = 0
    var sortOrder: SortOrder = .altitude

    // Map
    var mapCameraPosition: MapCameraPosition = .automatic
    var showDetailSheet = false

    // MARK: - Private

    private let openSkyService = OpenSkyService()
    let locationService = LocationService()
    nonisolated(unsafe) private var pollingTask: Task<Void, Never>?

    // MARK: - Computed

    var filteredAircraft: [Aircraft] {
        var result = aircraft

        if !showGroundAircraft {
            result = result.filter { !$0.onGround }
        }

        if minimumAltitudeFt > 0 {
            result = result.filter { $0.altitudeFeet >= minimumAltitudeFt }
        }

        switch sortOrder {
        case .altitude:
            result.sort { $0.altitudeMeters > $1.altitudeMeters }
        case .speed:
            result.sort { ($0.velocity ?? 0) > ($1.velocity ?? 0) }
        case .callsign:
            result.sort { $0.displayCallsign < $1.displayCallsign }
        case .distance:
            result.sort { distanceToUser($0) ?? .infinity < distanceToUser($1) ?? .infinity }
        }

        return result
    }

    var airborneCount: Int {
        aircraft.filter { !$0.onGround }.count
    }

    var groundCount: Int {
        aircraft.filter { $0.onGround }.count
    }

    var averageAltitudeFt: Double? {
        let airborne = aircraft.filter { !$0.onGround && $0.baroAltitude != nil }
        guard !airborne.isEmpty else { return nil }
        return airborne.map(\.altitudeFeet).reduce(0, +) / Double(airborne.count)
    }

    // MARK: - Actions

    func startPolling() {
        guard !isPolling else { return }
        isPolling = true
        locationService.requestPermission()

        pollingTask = Task {
            while !Task.isCancelled {
                await fetchAircraft()
                try? await Task.sleep(for: .seconds(AppConstants.pollingInterval))
            }
        }
    }

    func stopPolling() {
        isPolling = false
        pollingTask?.cancel()
        pollingTask = nil
    }

    func fetchAircraft() async {
        isLoading = true
        error = nil

        do {
            let fetched = try await openSkyService.fetchAircraft(in: selectedRegion)
            aircraft = fetched
            lastUpdateTime = Date()

            // Update selected aircraft if still present
            if let selected = selectedAircraft {
                selectedAircraft = fetched.first { $0.id == selected.id }
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func selectAircraft(_ ac: Aircraft) {
        selectedAircraft = ac
        showDetailSheet = true

        mapCameraPosition = .camera(
            MapCamera(
                centerCoordinate: ac.coordinate,
                distance: 200_000,
                heading: 0,
                pitch: 0
            )
        )
    }

    func changeRegion(_ region: MapBoundingBox) {
        selectedRegion = region
        aircraft = []
        selectedAircraft = nil

        mapCameraPosition = .camera(
            MapCamera(
                centerCoordinate: CLLocationCoordinate2D(
                    latitude: region.centerLatitude,
                    longitude: region.centerLongitude
                ),
                distance: max(region.latSpan, region.lonSpan) * 111_000 * 2.5
            )
        )

        Task {
            await fetchAircraft()
        }
    }

    func centerOnRegion() {
        let region = selectedRegion
        mapCameraPosition = .camera(
            MapCamera(
                centerCoordinate: CLLocationCoordinate2D(
                    latitude: region.centerLatitude,
                    longitude: region.centerLongitude
                ),
                distance: max(region.latSpan, region.lonSpan) * 111_000 * 2.5
            )
        )
    }

    func engineeringData(for aircraft: Aircraft) -> EngineeringData {
        EngineeringComputer.compute(for: aircraft)
    }

    func distanceToUser(_ aircraft: Aircraft) -> Double? {
        locationService.distance(to: aircraft.coordinate)
    }

    func timeSinceUpdate() -> String {
        guard let last = lastUpdateTime else { return "Never" }
        let seconds = Int(-last.timeIntervalSinceNow)
        if seconds < 5 { return "Just now" }
        if seconds < 60 { return "\(seconds)s ago" }
        return "\(seconds / 60)m ago"
    }

    deinit {
        pollingTask?.cancel()
    }
}

// MARK: - Sort Order

enum SortOrder: String, CaseIterable, Identifiable {
    case altitude = "Altitude"
    case speed = "Speed"
    case callsign = "Callsign"
    case distance = "Distance"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .altitude: return "arrow.up.and.down"
        case .speed:    return "gauge.with.dots.needle.33percent"
        case .callsign: return "textformat.abc"
        case .distance: return "location"
        }
    }
}
