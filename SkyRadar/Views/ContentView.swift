import SwiftUI

/// Main container: full-screen map with a persistent bottom sheet for aircraft list and controls.
struct ContentView: View {
    @State var viewModel: RadarViewModel

    @State private var sheetDetent: PresentationDetent = .fraction(0.30)

    var body: some View {
        ZStack {
            // Full-screen map
            RadarMapView(viewModel: viewModel)
                .ignoresSafeArea()

            // Top overlay bar
            VStack {
                topBar
                Spacer()
            }
        }
        .sheet(isPresented: .constant(true)) {
            aircraftListSheet
                .presentationDetents(
                    [.fraction(0.10), .fraction(0.30), .fraction(0.65), .large],
                    selection: $sheetDetent
                )
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.65)))
                .presentationCornerRadius(20)
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $viewModel.showDetailSheet) {
            if let aircraft = viewModel.selectedAircraft {
                AircraftDetailSheet(
                    aircraft: aircraft,
                    engineeringData: viewModel.engineeringData(for: aircraft),
                    distance: viewModel.distanceToUser(aircraft)
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(20)
            }
        }
        .onAppear {
            viewModel.startPolling()
        }
        .onDisappear {
            viewModel.stopPolling()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            // Status indicator
            HStack(spacing: 6) {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                } else if viewModel.isPolling {
                    PulsingDot(color: .altitudeGreen)
                }

                Text(viewModel.timeSinceUpdate())
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Region picker
            Menu {
                ForEach(AppConstants.regions) { region in
                    Button {
                        viewModel.changeRegion(region)
                    } label: {
                        HStack {
                            Text(region.name)
                            if region == viewModel.selectedRegion {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "globe")
                    Text(viewModel.selectedRegion.name)
                        .font(.subheadline.weight(.medium))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
            }
            .foregroundStyle(.primary)

            // Center button
            Button {
                withAnimation {
                    viewModel.centerOnRegion()
                }
            } label: {
                Image(systemName: "location.viewfinder")
                    .font(.subheadline.weight(.medium))
                    .padding(8)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .foregroundStyle(.primary)
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }

    // MARK: - Aircraft List Sheet

    private var aircraftListSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Stats header
                statsHeader

                Divider()

                // Sort & filter bar
                controlsBar

                // Aircraft list
                if viewModel.filteredAircraft.isEmpty {
                    emptyState
                } else {
                    aircraftList
                }
            }
            .navigationTitle("SkyRadar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.fetchAircraft() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        HStack(spacing: 16) {
            statPill(
                icon: "airplane",
                value: "\(viewModel.airborneCount)",
                label: "Airborne",
                color: Color.radarCyan
            )

            if viewModel.showGroundAircraft {
                statPill(
                    icon: "airplane.circle",
                    value: "\(viewModel.groundCount)",
                    label: "Ground",
                    color: Color.phaseGround
                )
            }

            if let avgAlt = viewModel.averageAltitudeFt {
                statPill(
                    icon: "arrow.up.and.down",
                    value: String(format: "%.0f", avgAlt),
                    label: "Avg Alt (ft)",
                    color: .altitudeGreen
                )
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func statPill(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.subheadline.monospacedDigit().weight(.bold))
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Controls Bar

    private var controlsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Sort picker
                Menu {
                    ForEach(SortOrder.allCases) { order in
                        Button {
                            viewModel.sortOrder = order
                        } label: {
                            Label(order.rawValue, systemImage: order.symbol)
                            if order == viewModel.sortOrder {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.sortOrder.symbol)
                        Text(viewModel.sortOrder.rawValue)
                    }
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.radarCyan.opacity(0.12), in: Capsule())
                    .foregroundStyle(Color.radarCyan)
                }

                // Ground filter toggle
                Button {
                    withAnimation { viewModel.showGroundAircraft.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.showGroundAircraft ? "checkmark.circle.fill" : "circle")
                        Text("Ground")
                    }
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        viewModel.showGroundAircraft
                            ? Color.phaseGround.opacity(0.15)
                            : Color(.tertiarySystemFill),
                        in: Capsule()
                    )
                    .foregroundStyle(viewModel.showGroundAircraft ? Color.phaseGround : Color.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Aircraft List

    private var aircraftList: some View {
        List {
            ForEach(viewModel.filteredAircraft) { aircraft in
                AircraftRow(
                    aircraft: aircraft,
                    engineeringData: viewModel.engineeringData(for: aircraft),
                    distance: viewModel.distanceToUser(aircraft)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(duration: 0.3)) {
                        viewModel.selectAircraft(aircraft)
                    }
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }

            if let error = viewModel.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "airplane.circle")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)

            if viewModel.isLoading {
                Text("Scanning for aircraft...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ProgressView()
            } else if viewModel.error != nil {
                Text("Unable to fetch aircraft data")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Retry") {
                    Task { await viewModel.fetchAircraft() }
                }
                .buttonStyle(.bordered)
            } else {
                Text("No aircraft in range")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Try selecting a different region")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
