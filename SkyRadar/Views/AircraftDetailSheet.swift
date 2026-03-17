import SwiftUI

/// Full engineering detail view for a selected aircraft.
struct AircraftDetailSheet: View {
    let aircraft: Aircraft
    let engineeringData: EngineeringData
    var distance: Double?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroSection
                    positionSection
                    engineeringSection
                    atmosphereSection
                    rawDataSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(aircraft.displayCallsign)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 12) {
            // Large callsign
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.altitudeColor(meters: aircraft.altitudeMeters).gradient)
                        .frame(width: 56, height: 56)

                    Image(systemName: "airplane")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(aircraft.headingDegrees - 90))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(aircraft.displayCallsign)
                        .font(.title2.weight(.bold).monospacedDigit())

                    HStack(spacing: 8) {
                        Label(aircraft.originCountry, systemImage: "globe")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        PhaseBadge(phase: aircraft.flightPhase)
                    }
                }

                Spacer()
            }

            // Quick stats bar
            HStack(spacing: 0) {
                quickStat(
                    icon: "arrow.up.and.down",
                    value: String(format: "%.0f ft", aircraft.altitudeFeet),
                    label: aircraft.flightLevel
                )

                Divider().frame(height: 30)

                quickStat(
                    icon: "gauge.with.dots.needle.67percent",
                    value: aircraft.speedKnots.map { String(format: "%.0f kt", $0) } ?? "—",
                    label: engineeringData.machFormatted != "—" ? "M\(engineeringData.machFormatted)" : ""
                )

                Divider().frame(height: 30)

                quickStat(
                    icon: "location",
                    value: distance.map { String(format: "%.0f km", $0) } ?? "—",
                    label: "Distance"
                )
            }
            .glassCard(padding: 12)
        }
    }

    private func quickStat(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.radarCyan)
            Text(value)
                .font(.subheadline.monospacedDigit().weight(.semibold))
            if !label.isEmpty {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Position Section

    private var positionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "map", title: "Position")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                DataValue(
                    label: "Latitude",
                    value: String(format: "%.4f°", aircraft.latitude),
                    unit: aircraft.latitude >= 0 ? "N" : "S"
                )

                DataValue(
                    label: "Longitude",
                    value: String(format: "%.4f°", aircraft.longitude),
                    unit: aircraft.longitude >= 0 ? "E" : "W"
                )

                DataValue(
                    label: "True Track",
                    value: aircraft.trueTrack.map { String(format: "%.0f", $0) } ?? "—",
                    unit: "°"
                )

                DataValue(
                    label: "Vertical Rate",
                    value: aircraft.verticalRateFpm.map { String(format: "%+.0f", $0) } ?? "—",
                    unit: "ft/min",
                    color: verticalRateColor
                )
            }
            .glassCard()
        }
    }

    private var verticalRateColor: Color {
        guard let vr = aircraft.verticalRate else { return .primary }
        if vr > 2 { return .phaseClimb }
        if vr < -2 { return .phaseDescent }
        return .primary
    }

    // MARK: - Engineering Section

    private var engineeringSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "function", title: "Engineering Data")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                EngineeringCard(
                    icon: "speedometer",
                    title: "Mach Number",
                    value: engineeringData.machFormatted,
                    subtitle: "V / a(h)",
                    color: .machOrange
                )

                EngineeringCard(
                    icon: "arrow.down.to.line.compact",
                    title: "Dynamic Pressure",
                    value: engineeringData.dynamicPressureFormatted,
                    subtitle: "q = ½ρV²",
                    color: .pressurePurple
                )

                EngineeringCard(
                    icon: "bolt",
                    title: "Energy Altitude",
                    value: engineeringData.energyAltitudeFormatted,
                    subtitle: "h + V²/(2g)",
                    color: .energyTeal
                )

                EngineeringCard(
                    icon: "water.waves",
                    title: "Reynolds Number",
                    value: engineeringData.reynoldsFormatted,
                    unit: "",
                    subtitle: "Re = ρVc/μ (c=4m)",
                    color: .reynoldsRose
                )

                EngineeringCard(
                    icon: "gauge.with.dots.needle.33percent",
                    title: "Ground Speed",
                    value: engineeringData.trueAirspeedKnots.map { String(format: "%.0f", $0) } ?? "—",
                    unit: "kt",
                    subtitle: engineeringData.trueAirspeed.map { String(format: "%.1f m/s", $0) },
                    color: .speedAmber
                )

                EngineeringCard(
                    icon: "arrow.up.and.down",
                    title: "Baro Altitude",
                    value: String(format: "%.0f", aircraft.altitudeFeet),
                    unit: "ft",
                    subtitle: String(format: "%.0f m", aircraft.altitudeMeters),
                    color: .altitudeGreen
                )
            }
        }
    }

    // MARK: - Atmosphere Section

    private var atmosphereSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "cloud", title: "ISA Atmosphere at \(aircraft.flightLevel)")

            let atm = engineeringData.atmosphere

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                EngineeringCard(
                    icon: "thermometer.medium",
                    title: "Temperature",
                    value: String(format: "%.1f", atm.temperatureC),
                    unit: "°C",
                    subtitle: String(format: "%.1f K", atm.temperature),
                    color: .orange
                )

                EngineeringCard(
                    icon: "barometer",
                    title: "Pressure",
                    value: String(format: "%.1f", atm.pressureHPa),
                    unit: "hPa",
                    subtitle: String(format: "%.0f Pa", atm.pressure),
                    color: .radarBlue
                )

                EngineeringCard(
                    icon: "aqi.medium",
                    title: "Density",
                    value: String(format: "%.4f", atm.density),
                    unit: "kg/m³",
                    subtitle: String(format: "σ = %.3f", atm.densityRatio),
                    color: .teal
                )

                EngineeringCard(
                    icon: "speaker.wave.3",
                    title: "Speed of Sound",
                    value: String(format: "%.1f", atm.speedOfSound),
                    unit: "m/s",
                    subtitle: atm.layerName,
                    color: .purple
                )
            }
        }
    }

    // MARK: - Raw Data

    private var rawDataSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "antenna.radiowaves.left.and.right", title: "ADS-B Data")

            VStack(spacing: 0) {
                rawRow("ICAO24", aircraft.id)
                Divider()
                rawRow("Source", aircraft.positionSource.label)
                if let squawk = aircraft.squawk {
                    Divider()
                    rawRow("Squawk", squawk)
                }
                if let geoAlt = aircraft.geoAltitude {
                    Divider()
                    rawRow("Geo Altitude", String(format: "%.0f m (%.0f ft)", geoAlt, geoAlt * ISAConstants.feetPerMeter))
                }
            }
            .glassCard(padding: 0)
        }
    }

    private func rawRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.monospacedDigit())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Helpers

    private func sectionHeader(icon: String, title: String) -> some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .foregroundStyle(.primary)
    }
}
