import Foundation
import CoreLocation

/// A single aircraft state from OpenSky ADS-B data, enriched with engineering computations.
struct Aircraft: Identifiable, Equatable {
    let id: String  // ICAO24 transponder address

    // ADS-B Data
    let callsign: String?
    let originCountry: String
    let timePosition: Int?
    let lastContact: Int
    let longitude: Double
    let latitude: Double
    let baroAltitude: Double?       // meters
    let onGround: Bool
    let velocity: Double?           // m/s ground speed
    let trueTrack: Double?          // degrees from north, clockwise
    let verticalRate: Double?       // m/s
    let geoAltitude: Double?        // meters (geometric / GPS altitude)
    let squawk: String?
    let positionSource: PositionSource

    // MARK: - Computed Properties

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var displayCallsign: String {
        callsign?.trimmingCharacters(in: .whitespaces).isEmpty == false
            ? callsign!.trimmingCharacters(in: .whitespaces)
            : id.uppercased()
    }

    var altitudeMeters: Double {
        baroAltitude ?? geoAltitude ?? 0
    }

    var altitudeFeet: Double {
        altitudeMeters * ISAConstants.feetPerMeter
    }

    var flightLevel: String {
        let fl = Int(round(altitudeFeet / 100))
        return "FL\(String(format: "%03d", fl))"
    }

    var speedKnots: Double? {
        velocity.map { $0 * ISAConstants.knotsPerMs }
    }

    var verticalRateFpm: Double? {
        verticalRate.map { $0 * 196.85 }  // m/s → ft/min
    }

    var flightPhase: FlightPhase {
        guard !onGround else { return .ground }
        guard let vr = verticalRate else { return .unknown }
        if vr > 2.0 { return .climbing }
        if vr < -2.0 { return .descending }
        return .cruise
    }

    /// Heading rotation for map annotation (degrees)
    var headingDegrees: Double {
        trueTrack ?? 0
    }

    static func == (lhs: Aircraft, rhs: Aircraft) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Flight Phase

enum FlightPhase: String, CaseIterable {
    case ground = "Ground"
    case climbing = "Climbing"
    case cruise = "Cruise"
    case descending = "Descending"
    case unknown = "Unknown"

    var symbolName: String {
        switch self {
        case .ground:     return "airplane.circle"
        case .climbing:   return "airplane.departure"
        case .cruise:     return "airplane"
        case .descending: return "airplane.arrival"
        case .unknown:    return "questionmark.circle"
        }
    }

    var color: String {
        switch self {
        case .ground:     return "phaseGround"
        case .climbing:   return "phaseClimb"
        case .cruise:     return "phaseCruise"
        case .descending: return "phaseDescent"
        case .unknown:    return "phaseUnknown"
        }
    }
}

// MARK: - Position Source

enum PositionSource: Int, Sendable {
    case adsb = 0
    case asterix = 1
    case mlat = 2
    case flarm = 3

    var label: String {
        switch self {
        case .adsb:   return "ADS-B"
        case .asterix: return "ASTERIX"
        case .mlat:   return "MLAT"
        case .flarm:  return "FLARM"
        }
    }
}

// MARK: - OpenSky API Response Decoding

struct OpenSkyResponse: Sendable {
    let time: Int
    let aircraft: [Aircraft]
}

/// Custom decoder for OpenSky heterogeneous JSON arrays
enum OpenSkyDecoder {
    static func decode(from data: Data) throws -> OpenSkyResponse {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw OpenSkyError.invalidResponse
        }

        let time = json["time"] as? Int ?? 0
        guard let states = json["states"] as? [[Any]] else {
            // No aircraft in the area — valid response
            return OpenSkyResponse(time: time, aircraft: [])
        }

        let aircraft = states.compactMap { state -> Aircraft? in
            guard state.count >= 17 else { return nil }

            let icao24 = state[0] as? String ?? ""
            guard !icao24.isEmpty else { return nil }

            let lon = state[5] as? Double
            let lat = state[6] as? Double
            guard let longitude = lon, let latitude = lat else { return nil }

            return Aircraft(
                id: icao24,
                callsign: state[1] as? String,
                originCountry: state[2] as? String ?? "Unknown",
                timePosition: state[3] as? Int,
                lastContact: state[4] as? Int ?? 0,
                longitude: longitude,
                latitude: latitude,
                baroAltitude: state[7] as? Double,
                onGround: state[8] as? Bool ?? false,
                velocity: state[9] as? Double,
                trueTrack: state[10] as? Double,
                verticalRate: state[11] as? Double,
                geoAltitude: state[13] as? Double,
                squawk: state[14] as? String,
                positionSource: PositionSource(rawValue: state[16] as? Int ?? 0) ?? .adsb
            )
        }

        return OpenSkyResponse(time: time, aircraft: aircraft)
    }
}

enum OpenSkyError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case rateLimited
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from OpenSky"
        case .httpError(let code): return "HTTP error \(code)"
        case .rateLimited: return "Rate limited — try again in a moment"
        case .networkUnavailable: return "Network unavailable"
        }
    }
}
