import Foundation

// MARK: - ISA Physical Constants

enum ISAConstants {
    // Sea Level Reference Values
    static let T0: Double = 288.15        // K
    static let P0: Double = 101_325.0     // Pa
    static let rho0: Double = 1.225       // kg/m³

    // Physical Constants
    static let g0: Double = 9.80665       // m/s²
    static let R: Double = 287.05287      // J/(kg·K)
    static let gamma: Double = 1.4        // ratio of specific heats
    static let rEarth: Double = 6_356_766 // m

    // Sutherland's Law
    static let muRef: Double = 1.458e-6   // kg/(m·s·K^0.5)
    static let sutherlandS: Double = 110.4 // K

    // Atmosphere Layers: (base altitude m, base temperature K, lapse rate K/m)
    static let layers: [(hBase: Double, tBase: Double, lapse: Double)] = [
        (0,      288.15, -0.0065),
        (11_000, 216.65,  0.0),
        (20_000, 216.65,  0.001),
        (32_000, 228.65,  0.0028),
        (47_000, 270.65,  0.0),
        (51_000, 270.65, -0.0028),
    ]

    static let maxAltitude: Double = 51_000

    // Conversion Factors
    static let feetPerMeter: Double = 3.28084
    static let meterPerFoot: Double = 0.3048
    static let hPaPerPa: Double = 0.01
    static let inHgPerPa: Double = 0.000295300
    static let mphPerMs: Double = 2.23694
    static let knotsPerMs: Double = 1.94384
}

// MARK: - App Constants

enum AppConstants {
    /// Default polling interval in seconds
    static let pollingInterval: TimeInterval = 10

    /// Reference chord for Reynolds number (typical airliner MAC ≈ 4 m)
    static let referenceChord: Double = 4.0

    /// Default bounding box: Israel
    static let defaultRegion = MapBoundingBox(
        name: "Israel",
        lamin: 29.0, lomin: 34.0,
        lamax: 34.0, lomax: 36.0
    )

    /// Predefined regions
    static let regions: [MapBoundingBox] = [
        MapBoundingBox(name: "Israel", lamin: 29.0, lomin: 34.0, lamax: 34.0, lomax: 36.0),
        MapBoundingBox(name: "Central Europe", lamin: 45.0, lomin: 5.0, lamax: 55.0, lomax: 20.0),
        MapBoundingBox(name: "US East Coast", lamin: 35.0, lomin: -80.0, lamax: 45.0, lomax: -70.0),
        MapBoundingBox(name: "UK & Ireland", lamin: 50.0, lomin: -11.0, lamax: 59.0, lomax: 2.0),
    ]
}

struct MapBoundingBox: Identifiable, Equatable, Hashable {
    var id: String { name }
    let name: String
    let lamin: Double
    let lomin: Double
    let lamax: Double
    let lomax: Double

    var centerLatitude: Double { (lamin + lamax) / 2 }
    var centerLongitude: Double { (lomin + lomax) / 2 }
    var latSpan: Double { lamax - lamin }
    var lonSpan: Double { lomax - lomin }
}
