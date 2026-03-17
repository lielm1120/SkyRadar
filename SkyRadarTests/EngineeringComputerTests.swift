import Testing
@testable import SkyRadar

@Suite("Engineering Computer Tests")
struct EngineeringComputerTests {

    // MARK: - Helpers

    private func makeAircraft(
        altitude: Double = 10_000,
        velocity: Double? = 250,
        verticalRate: Double? = 0,
        onGround: Bool = false
    ) -> Aircraft {
        Aircraft(
            id: "abc123",
            callsign: "TEST001",
            originCountry: "Test",
            timePosition: nil,
            lastContact: 0,
            longitude: 35.0,
            latitude: 32.0,
            baroAltitude: altitude,
            onGround: onGround,
            velocity: velocity,
            trueTrack: 90,
            verticalRate: verticalRate,
            geoAltitude: altitude,
            squawk: nil,
            positionSource: .adsb
        )
    }

    // MARK: - Mach Number Tests

    @Test("Mach number at sea level")
    func machAtSeaLevel() {
        let ac = makeAircraft(altitude: 0, velocity: 170) // ~330 kt
        let data = EngineeringComputer.compute(for: ac)
        // a(0) ≈ 340.3 m/s, so M ≈ 170/340.3 ≈ 0.50
        #expect(data.machNumber != nil)
        #expect(abs(data.machNumber! - 0.50) < 0.01)
    }

    @Test("Mach number at cruise altitude")
    func machAtCruise() {
        let ac = makeAircraft(altitude: 10_000, velocity: 240) // typical jet
        let data = EngineeringComputer.compute(for: ac)
        // a(10 km) ≈ 299.5 m/s, M ≈ 240/299.5 ≈ 0.80
        #expect(data.machNumber != nil)
        #expect(abs(data.machNumber! - 0.80) < 0.02)
    }

    @Test("Mach number nil when no velocity")
    func machNilNoVelocity() {
        let ac = makeAircraft(velocity: nil)
        let data = EngineeringComputer.compute(for: ac)
        #expect(data.machNumber == nil)
    }

    // MARK: - Dynamic Pressure Tests

    @Test("Dynamic pressure at sea level")
    func dynamicPressureSeaLevel() {
        let ac = makeAircraft(altitude: 0, velocity: 100) // 100 m/s
        let data = EngineeringComputer.compute(for: ac)
        // q = 0.5 * 1.225 * 100² = 6125 Pa
        #expect(data.dynamicPressure != nil)
        #expect(abs(data.dynamicPressure! - 6125) < 50)
    }

    @Test("Dynamic pressure decreases with altitude for same speed")
    func dynamicPressureDecreasesWithAltitude() {
        let low = EngineeringComputer.compute(for: makeAircraft(altitude: 1_000, velocity: 200))
        let high = EngineeringComputer.compute(for: makeAircraft(altitude: 10_000, velocity: 200))
        #expect(low.dynamicPressure! > high.dynamicPressure!)
    }

    // MARK: - Energy Altitude Tests

    @Test("Energy altitude exceeds geometric altitude")
    func energyAltitudeExceedsGeometric() {
        let ac = makeAircraft(altitude: 10_000, velocity: 250)
        let data = EngineeringComputer.compute(for: ac)
        #expect(data.energyAltitude! > 10_000)
        // V²/(2g) = 250²/(2*9.80665) ≈ 3186 m
        let expected = 10_000 + 250 * 250 / (2 * 9.80665)
        #expect(abs(data.energyAltitude! - expected) < 1)
    }

    // MARK: - Reynolds Number Tests

    @Test("Reynolds number is positive at cruise")
    func reynoldsPositive() {
        let ac = makeAircraft(altitude: 10_000, velocity: 240)
        let data = EngineeringComputer.compute(for: ac)
        #expect(data.reynoldsNumber! > 0)
        // Re should be in the millions for an airliner at cruise
        #expect(data.reynoldsNumber! > 1e6)
    }

    // MARK: - ISA Atmosphere Tests

    @Test("Atmosphere at sea level matches ISA")
    func atmosphereSeaLevel() {
        let ac = makeAircraft(altitude: 0, velocity: 100)
        let data = EngineeringComputer.compute(for: ac)
        #expect(abs(data.atmosphere.temperature - 288.15) < 0.1)
        #expect(abs(data.atmosphere.pressure - 101_325) < 1)
    }

    @Test("Atmosphere at tropopause")
    func atmosphereTropopause() {
        let ac = makeAircraft(altitude: 11_000, velocity: 250)
        let data = EngineeringComputer.compute(for: ac)
        // T ≈ 216.65 K at 11 km
        #expect(abs(data.atmosphere.temperature - 216.65) < 0.5)
    }

    // MARK: - Flight Phase Tests

    @Test("Flight phase detection")
    func flightPhaseDetection() {
        let climbing = makeAircraft(verticalRate: 5.0)
        #expect(climbing.flightPhase == .climbing)

        let descending = makeAircraft(verticalRate: -5.0)
        #expect(descending.flightPhase == .descending)

        let cruise = makeAircraft(verticalRate: 0.5)
        #expect(cruise.flightPhase == .cruise)

        let ground = makeAircraft(onGround: true)
        #expect(ground.flightPhase == .ground)
    }

    // MARK: - Formatting Tests

    @Test("Mach formatted string")
    func machFormatted() {
        let ac = makeAircraft(altitude: 10_000, velocity: 240)
        let data = EngineeringComputer.compute(for: ac)
        #expect(data.machFormatted.contains("."))
        #expect(data.machFormatted != "—")
    }

    @Test("No velocity shows dash")
    func noVelocityDash() {
        let ac = makeAircraft(velocity: nil)
        let data = EngineeringComputer.compute(for: ac)
        #expect(data.machFormatted == "—")
        #expect(data.dynamicPressureFormatted == "—")
        #expect(data.energyAltitudeFormatted == "—")
    }
}
