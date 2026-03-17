import SwiftUI
import MapKit

/// Full-screen map with aircraft annotations and interactive overlays.
struct RadarMapView: View {
    @Bindable var viewModel: RadarViewModel

    var body: some View {
        Map(position: $viewModel.mapCameraPosition) {
            // User location
            UserAnnotation()

            // Aircraft annotations
            ForEach(viewModel.filteredAircraft) { aircraft in
                Annotation(
                    aircraft.displayCallsign,
                    coordinate: aircraft.coordinate,
                    anchor: .center
                ) {
                    AircraftAnnotationView(
                        aircraft: aircraft,
                        isSelected: viewModel.selectedAircraft?.id == aircraft.id
                    )
                    .onTapGesture {
                        withAnimation(.spring(duration: 0.3)) {
                            viewModel.selectAircraft(aircraft)
                        }
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }
}

// MARK: - Aircraft Annotation

struct AircraftAnnotationView: View {
    let aircraft: Aircraft
    var isSelected: Bool = false

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                // Selection ring
                if isSelected {
                    Circle()
                        .stroke(Color.radarCyan, lineWidth: 2)
                        .frame(width: 36, height: 36)
                        .shadow(color: .radarCyan.opacity(0.5), radius: 6)
                }

                // Aircraft icon
                Image(systemName: aircraft.onGround ? "airplane.circle" : "airplane")
                    .font(.system(size: isSelected ? 18 : 14, weight: .bold))
                    .foregroundStyle(
                        isSelected ? .radarCyan : Color.altitudeColor(meters: aircraft.altitudeMeters)
                    )
                    .rotationEffect(.degrees(aircraft.headingDegrees - 90))
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
                    )
            }

            // Callsign label (only when selected or zoomed in)
            if isSelected {
                Text(aircraft.displayCallsign)
                    .font(.caption2.weight(.bold).monospacedDigit())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial, in: Capsule())
                    .foregroundStyle(.primary)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
