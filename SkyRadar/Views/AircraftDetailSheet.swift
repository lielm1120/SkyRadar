import SwiftUI

/// Comprehensive aerospace engineering detail view for a selected aircraft.
struct AircraftDetailSheet: View {
    let aircraft: Aircraft
    let engineeringData: EngineeringData
    var distance: Double?

    @Environment(\.dismiss) private var dismiss

    private let twoCol = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    heroSection
                    airspeedSection
                    aerodynamicsSection
                    energySection
                    thermalSection
                    atmosphereSection
                    altitudeReferencesSection
                    positionSection
                    adsbSection
                }
                .padding()
                .padding(.bottom, 30)
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

    // MARK: - 1. Hero Section

    private var heroSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.altitudeColor(meters: aircraft.altitudeMeters).gradient)
                        .frame(width: 60, height: 60)

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

            // Quick stats strip
            HStack(spacing: 0) {
                heroStat(
                    icon: "arrow.up.and.down",
                    value: String(format: "%.0f", aircraft.altitudeFeet),
                    unit: "ft",
                    sub: aircraft.flightLevel
                )
                heroDivider
                heroStat(
                    icon: "speedometer",
                    value: engineeringData.machFormatted,
                    unit: "Mach",
                    sub: engineeringData.tasKnots.map { String(format: "%.0f kt", $0) } ?? ""
                )
                heroDivider
                heroStat(
                    icon: "thermometer.medium",
                    value: String(format: "%.0f", engineeringData.atmosphere.temperatureC),
                    unit: "°C",
                    sub: engineeringData.atmosphere.layerName
                )
                heroDivider
                heroStat(
                    icon: "location",
                    value: distance.map { String(format: "%.0f", $0) } ?? "—",
                    unit: "km",
                    sub: "Distance"
                )
            }
            .glassCard(padding: 10)
        }
    }

    private func heroStat(icon: String, value: String, unit: String, sub: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(Color.radarCyan)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.subheadline.monospacedDigit().weight(.bold))
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if !sub.isEmpty {
                Text(sub)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var heroDivider: some View {
        Divider().frame(height: 36)
    }

    // MARK: - 2. Airspeed Panel

    private var airspeedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                icon: "gauge.with.dots.needle.67percent",
                title: "Airspeed Conversions",
                color: .speedAmber
            )

            // The 4 airspeeds
            VStack(spacing: 0) {
                airspeedRow(
                    label: "TAS",
                    full: "True Airspeed",
                    value: engineeringData.tasKnots.map { String(format: "%.0f", $0) } ?? "—",
                    unit: "kt",
                    detail: engineeringData.tas.map { String(format: "%.1f m/s", $0) },
                    note: "≈ Ground speed (no wind data)",
                    color: .speedAmber,
                    isFirst: true
                )
                Divider().padding(.leading, 50)

                airspeedRow(
                    label: "EAS",
                    full: "Equivalent Airspeed",
                    value: engineeringData.easKnots.map { String(format: "%.0f", $0) } ?? "—",
                    unit: "kt",
                    detail: engineeringData.eas.map { String(format: "%.1f m/s", $0) },
                    note: "EAS = TAS × √σ  (σ = \(String(format: "%.3f", engineeringData.densityRatio)))",
                    color: .machOrange,
                    isFirst: false
                )
                Divider().padding(.leading, 50)

                airspeedRow(
                    label: "CAS",
                    full: "Calibrated Airspeed",
                    value: engineeringData.casKnots.map { String(format: "%.0f", $0) } ?? "—",
                    unit: "kt",
                    detail: nil,
                    note: "≈ EAS for subsonic (small compressibility correction)",
                    color: .radarCyan,
                    isFirst: false
                )
                Divider().padding(.leading, 50)

                airspeedRow(
                    label: "Mach",
                    full: "Mach Number",
                    value: engineeringData.machFormatted,
                    unit: "",
                    detail: engineeringData.atmosphere.speedOfSound > 0
                        ? String(format: "a = %.1f m/s at %@", engineeringData.atmosphere.speedOfSound, aircraft.flightLevel)
                        : nil,
                    note: "M = V / a(h)",
                    color: .machOrange,
                    isFirst: false
                )
            }
            .glassCard(padding: 0)
        }
    }

    private func airspeedRow(
        label: String, full: String, value: String, unit: String,
        detail: String?, note: String, color: Color, isFirst: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(color)
                .frame(width: 40, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(full)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(note)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                if let detail {
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - 3. Aerodynamic Forces

    private var aerodynamicsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                icon: "wind",
                title: "Aerodynamic Data",
                color: .pressurePurple
            )

            LazyVGrid(columns: twoCol, spacing: 10) {
                EngineeringCard(
                    icon: "arrow.down.to.line.compact",
                    title: "Dynamic Pressure",
                    value: engineeringData.dynamicPressureFormatted,
                    subtitle: "q = ½ρV²",
                    color: .pressurePurple
                )

                EngineeringCard(
                    icon: "water.waves",
                    title: "Reynolds Number",
                    value: engineeringData.reynoldsFormatted,
                    subtitle: "Re = ρVc/μ  (c = 4 m)",
                    color: .reynoldsRose
                )

                EngineeringCard(
                    icon: "airplane",
                    title: "Est. CL (cruise)",
                    value: engineeringData.estimatedCL.map { String(format: "%.3f", $0) } ?? "—",
                    subtitle: "CL = W/(qS)  assumes L=W",
                    color: .altitudeGreen
                )

                EngineeringCard(
                    icon: "scalemass",
                    title: "Wing Loading",
                    value: engineeringData.wingLoading.map { String(format: "%.0f", $0) } ?? "—",
                    unit: "N/m²",
                    subtitle: "W/S (typical 737-800)",
                    color: .radarBlue
                )
            }

            // Flow regime note
            if let re = engineeringData.reynoldsNumber {
                HStack(spacing: 6) {
                    Image(systemName: re > 5e5 ? "wind" : "water.waves")
                        .font(.caption2)
                        .foregroundStyle(Color.radarCyan)
                    Text(re > 5e5
                         ? "Re > 500k → Turbulent boundary layer expected over most of the wing"
                         : "Re < 500k → Laminar flow possible over forward portion of wing"
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - 4. Energy & Performance

    private var energySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                icon: "bolt.fill",
                title: "Energy & Performance",
                color: .energyTeal
            )

            LazyVGrid(columns: twoCol, spacing: 10) {
                EngineeringCard(
                    icon: "bolt",
                    title: "Energy Altitude",
                    value: engineeringData.energyAltitudeFormattedFt,
                    unit: "ft",
                    subtitle: "Hₑ = h + V²/(2g)",
                    color: .energyTeal
                )

                EngineeringCard(
                    icon: "speedometer",
                    title: "Kinetic Energy Alt",
                    value: engineeringData.specificKineticEnergy.map {
                        String(format: "%.0f", $0 * ISAConstants.feetPerMeter)
                    } ?? "—",
                    unit: "ft",
                    subtitle: "V²/(2g) — speed as altitude",
                    color: .speedAmber
                )

                EngineeringCard(
                    icon: "arrow.up.right",
                    title: "Flight Path Angle",
                    value: engineeringData.flightPathAngleFormatted,
                    unit: "°",
                    subtitle: "γ = arctan(Vᵥ/Vₕ)",
                    color: flightPathColor
                )

                EngineeringCard(
                    icon: "arrow.up.and.down",
                    title: "Vertical Speed",
                    value: aircraft.verticalRateFpm.map { String(format: "%+.0f", $0) } ?? "—",
                    unit: "ft/min",
                    subtitle: aircraft.verticalRate.map { String(format: "%.1f m/s", $0) },
                    color: verticalRateColor
                )
            }

            // Energy interpretation
            if let he = engineeringData.energyAltitudeFt,
               let ske = engineeringData.specificKineticEnergy {
                let pct = (ske / (ske + aircraft.altitudeMeters)) * 100
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.caption2)
                        .foregroundStyle(Color.energyTeal)
                    Text("Total energy = \(String(format: "%.0f", he)) ft  (\(String(format: "%.0f", pct))% kinetic, \(String(format: "%.0f", 100 - pct))% potential)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private var flightPathColor: Color {
        guard let fpa = engineeringData.flightPathAngle else { return .primary }
        if fpa > 0.5 { return .phaseClimb }
        if fpa < -0.5 { return .phaseDescent }
        return .phaseCruise
    }

    private var verticalRateColor: Color {
        guard let vr = aircraft.verticalRate else { return .primary }
        if vr > 2 { return .phaseClimb }
        if vr < -2 { return .phaseDescent }
        return .primary
    }

    // MARK: - 5. Thermal / Compressibility

    private var thermalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                icon: "flame",
                title: "Thermal & Compressibility",
                color: .orange
            )

            LazyVGrid(columns: twoCol, spacing: 10) {
                EngineeringCard(
                    icon: "thermometer.sun",
                    title: "Stagnation Temp",
                    value: engineeringData.stagnationTempFormatted,
                    unit: "°C",
                    subtitle: "T₀ = T(1 + (γ-1)/2·M²)",
                    color: .orange
                )

                EngineeringCard(
                    icon: "thermometer.high",
                    title: "Ram Temp Rise",
                    value: engineeringData.ramRiseFormatted,
                    unit: "K",
                    subtitle: "ΔT = T₀ − Tₛ (adiabatic)",
                    color: .red
                )

                EngineeringCard(
                    icon: "barometer",
                    title: "Total Pressure",
                    value: engineeringData.totalPressureHPa.map { String(format: "%.1f", $0) } ?? "—",
                    unit: "hPa",
                    subtitle: "P₀ = P(1+(γ-1)/2·M²)^(γ/(γ-1))",
                    color: .radarBlue
                )

                EngineeringCard(
                    icon: "arrow.right.to.line",
                    title: "Impact Pressure",
                    value: engineeringData.impactPressureHPa.map { String(format: "%.1f", $0) } ?? "—",
                    unit: "hPa",
                    subtitle: "qc = P₀ − P (pitot tube reads this)",
                    color: .pressurePurple
                )
            }

            // Thermal insight
            if let rise = engineeringData.ramTemperatureRise, rise > 1 {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.caption2)
                        .foregroundStyle(Color.orange)
                    Text("The nose/leading edge heats \(String(format: "%.0f", rise))K above ambient due to adiabatic compression at M\(engineeringData.machFormatted)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - 6. ISA Atmosphere

    private var atmosphereSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                icon: "cloud.sun",
                title: "ISA Atmosphere at \(aircraft.flightLevel)",
                color: .teal
            )

            let atm = engineeringData.atmosphere

            LazyVGrid(columns: twoCol, spacing: 10) {
                EngineeringCard(
                    icon: "thermometer.medium",
                    title: "Static Temperature",
                    value: String(format: "%.1f", atm.temperatureC),
                    unit: "°C",
                    subtitle: String(format: "%.2f K  (T/T₀ = %.3f)", atm.temperature, atm.temperature / ISAConstants.T0),
                    color: .orange
                )

                EngineeringCard(
                    icon: "barometer",
                    title: "Static Pressure",
                    value: String(format: "%.1f", atm.pressureHPa),
                    unit: "hPa",
                    subtitle: String(format: "P/P₀ = %.4f", atm.pressure / ISAConstants.P0),
                    color: .radarBlue
                )

                EngineeringCard(
                    icon: "aqi.medium",
                    title: "Air Density",
                    value: String(format: "%.4f", atm.density),
                    unit: "kg/m³",
                    subtitle: String(format: "σ = ρ/ρ₀ = %.4f", atm.densityRatio),
                    color: .teal
                )

                EngineeringCard(
                    icon: "speaker.wave.3",
                    title: "Speed of Sound",
                    value: String(format: "%.1f", atm.speedOfSound),
                    unit: "m/s",
                    subtitle: String(format: "%.1f kt  |  a = √(γRT)", atm.speedOfSound * ISAConstants.knotsPerMs),
                    color: .purple
                )

                EngineeringCard(
                    icon: "drop",
                    title: "Dynamic Viscosity",
                    value: String(format: "%.2e", atm.dynamicViscosity),
                    unit: "Pa·s",
                    subtitle: "Sutherland's law",
                    color: .indigo
                )

                EngineeringCard(
                    icon: "circle.dotted",
                    title: "Kinematic Viscosity",
                    value: String(format: "%.2e", atm.kinematicViscosity),
                    unit: "m²/s",
                    subtitle: "ν = μ/ρ",
                    color: .indigo
                )
            }
        }
    }

    // MARK: - 7. Altitude References

    private var altitudeReferencesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                icon: "ruler",
                title: "Altitude References",
                color: .altitudeGreen
            )

            VStack(spacing: 0) {
                altRow(
                    label: "Barometric Altitude",
                    meters: aircraft.baroAltitude,
                    feet: aircraft.baroAltitude.map { $0 * ISAConstants.feetPerMeter },
                    note: "From ADS-B transponder (QNH corrected)"
                )
                Divider().padding(.leading, 14)

                altRow(
                    label: "Geometric (GPS) Alt",
                    meters: aircraft.geoAltitude,
                    feet: aircraft.geoAltitude.map { $0 * ISAConstants.feetPerMeter },
                    note: "True height above WGS-84 ellipsoid"
                )
                Divider().padding(.leading, 14)

                altRow(
                    label: "Pressure Altitude",
                    meters: engineeringData.pressureAltitude,
                    feet: engineeringData.pressureAltitudeFt,
                    note: "ISA altitude for this pressure (QNE, 1013.25 hPa)"
                )
                Divider().padding(.leading, 14)

                altRow(
                    label: "Density Altitude",
                    meters: engineeringData.densityAltitude,
                    feet: engineeringData.densityAltitudeFt,
                    note: "ISA altitude for this air density (aircraft performance ref)"
                )
                Divider().padding(.leading, 14)

                altRow(
                    label: "Energy Altitude",
                    meters: engineeringData.energyAltitude,
                    feet: engineeringData.energyAltitudeFt,
                    note: "Total mechanical energy as equivalent altitude"
                )
            }
            .glassCard(padding: 0)
        }
    }

    private func altRow(label: String, meters: Double?, feet: Double?, note: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer()
                if let ft = feet {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.0f", ft))
                            .font(.subheadline.monospacedDigit().weight(.semibold))
                        Text("ft")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("—")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            HStack {
                Text(note)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                if let m = meters {
                    Text(String(format: "%.0f m", m))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - 8. Position & Navigation

    private var positionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                icon: "map",
                title: "Position & Navigation",
                color: .radarCyan
            )

            LazyVGrid(columns: twoCol, spacing: 10) {
                EngineeringCard(
                    icon: "mappin",
                    title: "Latitude",
                    value: String(format: "%.4f°", abs(aircraft.latitude)),
                    unit: aircraft.latitude >= 0 ? "N" : "S",
                    color: Color.radarCyan
                )

                EngineeringCard(
                    icon: "mappin",
                    title: "Longitude",
                    value: String(format: "%.4f°", abs(aircraft.longitude)),
                    unit: aircraft.longitude >= 0 ? "E" : "W",
                    color: Color.radarCyan
                )

                EngineeringCard(
                    icon: "safari",
                    title: "True Track",
                    value: aircraft.trueTrack.map { String(format: "%.0f", $0) } ?? "—",
                    unit: "°",
                    subtitle: aircraft.trueTrack.map { headingName($0) },
                    color: Color.radarBlue
                )

                EngineeringCard(
                    icon: "arrow.up.and.down",
                    title: "Ground Speed",
                    value: engineeringData.tasKnots.map { String(format: "%.0f", $0) } ?? "—",
                    unit: "kt",
                    subtitle: engineeringData.tas.map { String(format: "%.1f m/s", $0) },
                    color: .speedAmber
                )
            }
        }
    }

    private func headingName(_ degrees: Double) -> String {
        let dirs = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                     "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let idx = Int(round(degrees / 22.5)) % 16
        return dirs[idx]
    }

    // MARK: - 9. ADS-B Raw Data

    private var adsbSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(
                icon: "antenna.radiowaves.left.and.right",
                title: "ADS-B Transponder",
                color: .phaseGround
            )

            VStack(spacing: 0) {
                rawRow("ICAO24 Address", aircraft.id.uppercased())
                Divider().padding(.leading, 14)
                rawRow("Position Source", aircraft.positionSource.label)
                if let squawk = aircraft.squawk {
                    Divider().padding(.leading, 14)
                    rawRow("Squawk Code", squawk)
                    if squawk == "7700" || squawk == "7600" || squawk == "7500" {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(squawkMeaning(squawk))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.red)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                    }
                }
                Divider().padding(.leading, 14)
                rawRow("On Ground", aircraft.onGround ? "Yes" : "No")
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

    private func squawkMeaning(_ code: String) -> String {
        switch code {
        case "7700": return "EMERGENCY"
        case "7600": return "COMMUNICATION FAILURE"
        case "7500": return "HIJACK"
        default: return ""
        }
    }

    // MARK: - Section Header

    private func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
            Text(title)
                .font(.headline)
        }
    }
}
