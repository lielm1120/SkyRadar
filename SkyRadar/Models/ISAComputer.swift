import Foundation

/// Core ISA computation engine — ported from AeroAtmos
/// Implements the ICAO Standard Atmosphere from 0 to 51 km geopotential altitude.
enum ISAComputer {

    static func geometricToGeopotential(_ hGeometric: Double) -> Double {
        (ISAConstants.rEarth * hGeometric) / (ISAConstants.rEarth + hGeometric)
    }

    /// Compute atmosphere state at a given geopotential altitude
    static func compute(altitude: Double, isaDeviation: Double = 0) -> AtmosphereState {
        let h = min(max(altitude, 0), ISAConstants.maxAltitude)
        let layers = ISAConstants.layers

        var layerIndex = 0
        for i in 1..<layers.count {
            if h >= layers[i].hBase {
                layerIndex = i
            } else {
                break
            }
        }

        var T = layers[0].tBase
        var P = ISAConstants.P0

        for i in 0...layerIndex {
            let hBase = layers[i].hBase
            let tBase = layers[i].tBase
            let lapse = layers[i].lapse
            let hTop = (i < layerIndex) ? layers[i + 1].hBase : h

            T = tBase
            let deltaH = hTop - hBase

            if abs(lapse) < 1e-10 {
                P *= exp(-ISAConstants.g0 * deltaH / (ISAConstants.R * tBase))
            } else {
                let tTop = tBase + lapse * deltaH
                let exponent = -ISAConstants.g0 / (lapse * ISAConstants.R)
                P *= pow(tTop / tBase, exponent)
                T = tTop
            }
        }

        let T_actual = T + isaDeviation
        let rho = P / (ISAConstants.R * T_actual)
        let a = sqrt(ISAConstants.gamma * ISAConstants.R * T_actual)
        let mu = ISAConstants.muRef * pow(T_actual, 1.5) / (T_actual + ISAConstants.sutherlandS)
        let nu = rho > 0 ? mu / rho : 0

        return AtmosphereState(
            altitude: h,
            temperature: T_actual,
            pressure: P,
            density: rho,
            speedOfSound: a,
            dynamicViscosity: mu,
            kinematicViscosity: nu
        )
    }

    /// Given measured pressure (Pa), find the ISA altitude that produces it.
    static func pressureAltitude(pressure: Double) -> Double {
        let stateMax = compute(altitude: ISAConstants.maxAltitude)
        if pressure <= stateMax.pressure { return ISAConstants.maxAltitude }
        if pressure >= ISAConstants.P0 { return 0 }

        var lo = 0.0
        var hi = ISAConstants.maxAltitude
        for _ in 0..<60 {
            let mid = (lo + hi) / 2
            let pMid = compute(altitude: mid).pressure
            if pMid > pressure { lo = mid } else { hi = mid }
            if hi - lo < 0.01 { break }
        }
        return (lo + hi) / 2
    }
}
