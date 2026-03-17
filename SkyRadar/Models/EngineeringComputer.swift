import Foundation

// MARK: - Engineering Data

/// Complete engineering flight data computed from ADS-B state + ISA atmosphere.
/// Every value an aerospace engineer would want to know about an aircraft in flight.
struct EngineeringData: Sendable {

    // Atmosphere at aircraft altitude
    let atmosphere: AtmosphereState

    // MARK: - Airspeed Conversions (the 4 airspeeds)

    /// True Airspeed — approximated from ground speed (no wind data available)
    let tas: Double?                    // m/s
    let tasKnots: Double?

    /// Equivalent Airspeed — TAS corrected for density: EAS = TAS × √σ
    let eas: Double?                    // m/s
    let easKnots: Double?

    /// Calibrated Airspeed — ≈ EAS for subsonic flight (compressibility correction small)
    let cas: Double?                    // m/s
    let casKnots: Double?

    /// Mach number — V / a(h)
    let machNumber: Double?

    // MARK: - Aerodynamic Data

    /// Dynamic pressure — q = ½ρV² (Pa) — the single most important quantity in aero
    let dynamicPressure: Double?
    let dynamicPressureKPa: Double?

    /// Reynolds number — Re = ρVc/μ (using reference chord)
    let reynoldsNumber: Double?

    /// Estimated lift coefficient in cruise — CL = W/(qS), assumes L=W steady flight
    let estimatedCL: Double?

    /// Estimated wing loading — W/S (N/m²), using typical airliner weight
    let wingLoading: Double?

    // MARK: - Energy & Performance

    /// Energy altitude — h + V²/(2g) — total specific energy as equivalent altitude
    let energyAltitude: Double?         // m
    let energyAltitudeFt: Double?

    /// Specific kinetic energy — V²/(2g) — the "speed stored as altitude"
    let specificKineticEnergy: Double?   // m

    /// Flight path angle — γ = arctan(Vv/Vh) — angle of climb/descent
    let flightPathAngle: Double?        // degrees

    // MARK: - Thermal / Compressibility

    /// Stagnation (total) temperature — T₀ = T(1 + (γ-1)/2 · M²)
    /// The temperature the aircraft nose/leading edge experiences due to adiabatic compression
    let stagnationTemperature: Double?   // K
    let stagnationTemperatureC: Double?  // °C

    /// Temperature rise due to ram compression — ΔT = T₀ - T
    let ramTemperatureRise: Double?      // K

    /// Total (stagnation) pressure for isentropic flow
    /// P₀ = P(1 + (γ-1)/2 · M²)^(γ/(γ-1))
    let totalPressure: Double?           // Pa
    let totalPressureHPa: Double?

    /// Impact pressure — qc = P₀ - P — what a pitot tube measures
    let impactPressure: Double?          // Pa
    let impactPressureHPa: Double?

    // MARK: - Altitude References

    /// Pressure altitude — ISA altitude for the actual pressure at aircraft
    let pressureAltitude: Double?        // m
    let pressureAltitudeFt: Double?

    /// Density altitude — ISA altitude for the actual density at aircraft
    let densityAltitude: Double?         // m
    let densityAltitudeFt: Double?

    /// Density ratio σ = ρ/ρ₀
    let densityRatio: Double

    // MARK: - Formatted Strings

    var machFormatted: String {
        guard let m = machNumber else { return "—" }
        return String(format: "%.3f", m)
    }

    var dynamicPressureFormatted: String {
        guard let q = dynamicPressure else { return "—" }
        if q > 1000 { return String(format: "%.2f kPa", q / 1000) }
        return String(format: "%.0f Pa", q)
    }

    var energyAltitudeFormattedFt: String {
        guard let he = energyAltitudeFt else { return "—" }
        return String(format: "%.0f", he)
    }

    var reynoldsFormatted: String {
        guard let re = reynoldsNumber else { return "—" }
        if re >= 1e6 { return String(format: "%.1fM", re / 1e6) }
        return String(format: "%.0fk", re / 1e3)
    }

    var flightPathAngleFormatted: String {
        guard let g = flightPathAngle else { return "—" }
        return String(format: "%+.1f", g)
    }

    var stagnationTempFormatted: String {
        guard let t = stagnationTemperatureC else { return "—" }
        return String(format: "%.1f", t)
    }

    var ramRiseFormatted: String {
        guard let dt = ramTemperatureRise else { return "—" }
        return String(format: "+%.1f", dt)
    }
}

// MARK: - Typical Aircraft Parameters (for estimates)

private enum TypicalAirliner {
    static let wingArea: Double = 124.6     // m² (Boeing 737-800)
    static let weight: Double = 65_000 * 9.80665  // N (typical cruise weight ~65 tonnes)
    static let referenceChord: Double = 4.0 // m (mean aerodynamic chord)
}

// MARK: - Engineering Computer

/// Computes comprehensive engineering flight data for an aircraft
/// using the ISA atmosphere model and ADS-B state vectors.
enum EngineeringComputer {

    static func compute(for aircraft: Aircraft) -> EngineeringData {
        let altMeters = aircraft.altitudeMeters
        let geopotentialAlt = ISAComputer.geometricToGeopotential(altMeters)
        let atm = ISAComputer.compute(altitude: geopotentialAlt)

        let V = aircraft.velocity  // ground speed m/s ≈ TAS (no wind data)
        let gamma = ISAConstants.gamma
        let g0 = ISAConstants.g0

        // === Density ratio ===
        let sigma = atm.density / ISAConstants.rho0

        // === Mach number ===
        let mach: Double? = V.map { $0 / atm.speedOfSound }

        // === Airspeed conversions ===
        let eas: Double? = V.map { $0 * sqrt(sigma) }       // EAS = TAS × √σ
        let cas: Double? = eas  // CAS ≈ EAS for subsonic (small compressibility correction)

        // === Dynamic pressure ===
        let q: Double? = V.map { 0.5 * atm.density * $0 * $0 }

        // === Reynolds number ===
        let re: Double? = V.map {
            atm.density * $0 * TypicalAirliner.referenceChord / atm.dynamicViscosity
        }

        // === Estimated CL (assumes steady cruise L = W) ===
        let estCL: Double? = q.flatMap { qVal in
            guard qVal > 0, !aircraft.onGround else { return nil }
            return TypicalAirliner.weight / (qVal * TypicalAirliner.wingArea)
        }

        // === Wing loading ===
        let wl = TypicalAirliner.weight / TypicalAirliner.wingArea

        // === Energy altitude ===
        let he: Double? = V.map { altMeters + ($0 * $0) / (2 * g0) }
        let ske: Double? = V.map { ($0 * $0) / (2 * g0) }

        // === Flight path angle ===
        let fpa: Double?
        if let vr = aircraft.verticalRate, let gs = V, gs > 1 {
            fpa = atan(vr / gs) * 180.0 / .pi  // degrees
        } else {
            fpa = nil
        }

        // === Stagnation (total) temperature ===
        // T₀ = T × (1 + (γ-1)/2 × M²)
        let T0: Double? = mach.map { m in
            atm.temperature * (1 + (gamma - 1) / 2 * m * m)
        }
        let ramRise: Double? = T0.map { $0 - atm.temperature }

        // === Total (stagnation) pressure ===
        // P₀ = P × (1 + (γ-1)/2 × M²)^(γ/(γ-1))
        let P0: Double? = mach.map { m in
            let factor = 1 + (gamma - 1) / 2 * m * m
            return atm.pressure * pow(factor, gamma / (gamma - 1))
        }

        // === Impact pressure qc = P₀ - P ===
        let qc: Double? = P0.map { $0 - atm.pressure }

        // === Pressure altitude ===
        let pa = atm.pressure
        let pressAlt = ISAComputer.pressureAltitude(pressure: pa)

        // === Density altitude (find ISA altitude with same density) ===
        let densAlt = densityAltitudeFromDensity(atm.density)

        return EngineeringData(
            atmosphere: atm,
            tas: V,
            tasKnots: V.map { $0 * ISAConstants.knotsPerMs },
            eas: eas,
            easKnots: eas.map { $0 * ISAConstants.knotsPerMs },
            cas: cas,
            casKnots: cas.map { $0 * ISAConstants.knotsPerMs },
            machNumber: mach,
            dynamicPressure: q,
            dynamicPressureKPa: q.map { $0 / 1000 },
            reynoldsNumber: re,
            estimatedCL: estCL,
            wingLoading: wl,
            energyAltitude: he,
            energyAltitudeFt: he.map { $0 * ISAConstants.feetPerMeter },
            specificKineticEnergy: ske,
            flightPathAngle: fpa,
            stagnationTemperature: T0,
            stagnationTemperatureC: T0.map { $0 - 273.15 },
            ramTemperatureRise: ramRise,
            totalPressure: P0,
            totalPressureHPa: P0.map { $0 * ISAConstants.hPaPerPa },
            impactPressure: qc,
            impactPressureHPa: qc.map { $0 * ISAConstants.hPaPerPa },
            pressureAltitude: pressAlt,
            pressureAltitudeFt: pressAlt * ISAConstants.feetPerMeter,
            densityAltitude: densAlt,
            densityAltitudeFt: densAlt * ISAConstants.feetPerMeter,
            densityRatio: sigma
        )
    }

    /// Find ISA altitude with matching density (bisection)
    private static func densityAltitudeFromDensity(_ targetDensity: Double) -> Double {
        if targetDensity >= ISAConstants.rho0 { return 0 }
        var lo = 0.0
        var hi = ISAConstants.maxAltitude
        for _ in 0..<60 {
            let mid = (lo + hi) / 2
            let rhoMid = ISAComputer.compute(altitude: mid).density
            if rhoMid > targetDensity { lo = mid } else { hi = mid }
            if hi - lo < 0.01 { break }
        }
        return (lo + hi) / 2
    }
}
