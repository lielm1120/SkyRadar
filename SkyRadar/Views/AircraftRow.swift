import SwiftUI

/// Compact row for the aircraft list in the bottom sheet.
struct AircraftRow: View {
    let aircraft: Aircraft
    let engineeringData: EngineeringData
    var distance: Double?

    var body: some View {
        HStack(spacing: 12) {
            // Aircraft icon with heading
            ZStack {
                Circle()
                    .fill(Color.altitudeColor(meters: aircraft.altitudeMeters).opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: "airplane")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.altitudeColor(meters: aircraft.altitudeMeters))
                    .rotationEffect(.degrees(aircraft.headingDegrees - 90))
            }

            // Callsign + country
            VStack(alignment: .leading, spacing: 3) {
                Text(aircraft.displayCallsign)
                    .font(.subheadline.weight(.semibold).monospacedDigit())

                HStack(spacing: 6) {
                    Text(aircraft.originCountry)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    PhaseBadge(phase: aircraft.flightPhase)
                }
            }

            Spacer()

            // Key data
            VStack(alignment: .trailing, spacing: 3) {
                // Altitude
                HStack(spacing: 3) {
                    verticalRateIcon
                    Text(String(format: "%.0f", aircraft.altitudeFeet))
                        .font(.subheadline.monospacedDigit().weight(.medium))
                    Text("ft")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // Speed + Mach
                HStack(spacing: 8) {
                    if let knots = aircraft.speedKnots {
                        HStack(spacing: 2) {
                            Text(String(format: "%.0f", knots))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                            Text("kt")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    if let mach = engineeringData.machNumber, mach > 0.01 {
                        Text("M\(String(format: "%.2f", mach))")
                            .font(.caption.monospacedDigit().weight(.medium))
                            .foregroundStyle(Color.radarCyan)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var verticalRateIcon: some View {
        if let vr = aircraft.verticalRate {
            if vr > 2 {
                Image(systemName: "arrow.up")
                    .font(.caption2)
                    .foregroundStyle(Color.phaseClimb)
            } else if vr < -2 {
                Image(systemName: "arrow.down")
                    .font(.caption2)
                    .foregroundStyle(Color.phaseDescent)
            }
        }
    }
}
