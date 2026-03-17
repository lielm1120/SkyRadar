import Foundation

/// Fetches live ADS-B aircraft data from the OpenSky Network REST API.
/// Free, no API key required. Rate-limited to ~10 requests/minute for anonymous users.
actor OpenSkyService {

    private let session: URLSession
    private let baseURL = "https://opensky-network.org/api/states/all"

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    /// Fetch aircraft within a bounding box
    func fetchAircraft(in region: MapBoundingBox) async throws -> [Aircraft] {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "lamin", value: String(region.lamin)),
            URLQueryItem(name: "lomin", value: String(region.lomin)),
            URLQueryItem(name: "lamax", value: String(region.lamax)),
            URLQueryItem(name: "lomax", value: String(region.lomax)),
        ]

        guard let url = components.url else {
            throw OpenSkyError.invalidResponse
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenSkyError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            let result = try OpenSkyDecoder.decode(from: data)
            return result.aircraft
        case 429:
            throw OpenSkyError.rateLimited
        default:
            throw OpenSkyError.httpError(httpResponse.statusCode)
        }
    }
}
