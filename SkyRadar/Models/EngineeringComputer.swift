import Foundation

/// Engineering flight data computed from ADS-B state + ISA atmosphere
struct EngineeringData: Sendable {
    // Atmosphere at aircraft altitude
    let atmosphere: AtmosphereState

    // Computed engineering values
    let machNumber: Double?             // V / a(h)
    let dynamicPressure: Double?        // q = ½ρV² (Pa)
    let dynamicPressureKPa: Double?     // q in kPa
    let energyAltitude: Double?         // h + V²/(2g) (m)
    let energyAltitudeFt: Double?       // energy altitude in feet
    let reynoldsNumber: Double?         // ρVc/μ
    let trueAirspeed: Double?           // ≈ ground speed (simplified, no wind data)
    let trueAirspeedKnots: Double?

    // Formatted strings for display
    var machFormatted: String {
        guard let m = machNumber else { return "—" }
        return String(format: "%.3f", m)
    }

    var dynamicPressureFormatted: String {
        guard let q = dynamicPressure else { return "—" }
        if q > 1000 {
            return String(format: "%.1f kPa", q / 1000)
        }
        return String(format: "%.0f Pa", q)
    }

    var energyAltitudeFormatted: String {
        guard let he = energyAltitudeFt else { return "—" }
        return String(format: "%.0f ft", he)
    }

    var reynoldsFormatted: String {
        guard let re = reynoldsNumber else { return "—" }
        if re >= 1e6 {
            return String(format: "%.1f M", re / 1e6)
        }
        return String(format: "%.0f k", re / 1e3)
    }
}

/// Computes engineering flight data for an aircraft using ISA atmosphere model
enum EngineeringComputer {

    /// Compute engineering data for an aircraft
    static func compute(for aircraft: Aircraft) -> EngineeringData {
        let altMeters = aircraft.altitudeMeters
        let geopotentialAlt = ISAComputer.geometricToGeopotential(altMeters)
        let atm = ISAComputer.compute(altitude: geopotentialAlt)

        let velocity = aircraft.velocity  // ground speed in m/s (approximation for TAS)

        // Mach number: M = V / a(h)
        let mach: Double? = velocity.map { $0 / atm.speedOfSound }

        // Dynamic pressure: q = ½ρV²
        let q: Double? = velocity.map { 0.5 * atm.density * $0 * $0 }

        // Energy altitude: H_e = h + V²/(2g)
        let he: Double? = velocity.map { altMeters + ($0 * $0) / (2 * ISAConstants.g0) }

        // Reynolds number: Re = ρVc/μ (using reference chord)
        let re: Double? = velocity.map {
            atm.density * $0 * AppConstants.referenceChord / atm.dynamicViscosity
        }

        return EngineeringData(
            atmosphere: atm,
            machNumber: mach,
            dynamicPressure: q,
            dynamicPressureKPa: q.map { $0 / 1000 },
            energyAltitude: he,
            energyAltitudeFt: he.map { $0 * ISAConstants.feetPerMeter },
            reynoldsNumber: re,
            trueAirspeed: velocity,
            trueAirspeedKnots: velocity.map { $0 * ISAConstants.knotsPerMs }
        )
    }
}
