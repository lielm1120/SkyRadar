import Foundation

/// Complete atmospheric state at a given altitude
struct AtmosphereState: Sendable {
    let altitude: Double          // Geopotential altitude (m)
    let temperature: Double       // K
    let pressure: Double          // Pa
    let density: Double           // kg/m³
    let speedOfSound: Double      // m/s
    let dynamicViscosity: Double  // Pa·s
    let kinematicViscosity: Double // m²/s

    // Derived
    var temperatureC: Double { temperature - 273.15 }
    var pressureHPa: Double { pressure * ISAConstants.hPaPerPa }
    var altitudeFt: Double { altitude * ISAConstants.feetPerMeter }
    var densityRatio: Double { density / ISAConstants.rho0 }

    var layerName: String {
        switch altitude {
        case ..<11_000: return "Troposphere"
        case ..<20_000: return "Tropopause"
        case ..<32_000: return "Lower Stratosphere"
        case ..<47_000: return "Upper Stratosphere"
        default: return "Stratopause"
        }
    }
}
