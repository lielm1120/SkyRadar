import Testing
import Foundation
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

    // MARK: - Mach Number

    @Test("Mach number at sea level")
    func machAtSeaLevel() {
        let ac = makeAircraft(altitude: 0, velocity: 170)
        let data = EngineeringComputer.compute(for: ac)
        #expect(data.machNumber != nil)
        #expect(abs(data.machNumber! - 0.50) < 0.01)
    }

    @Test("Mach number at cruise altitude")
    func machAtCruise() {
        let ac = makeAircraft(altitude: 10_000, velocity: 240)
        let data = EngineeringComputer.compute(for: ac)
        #expect(data.machNumber != nil)
        #expect(abs(data.machNumber! - 0.80) < 0.02)
    }

    @Test("Mach number nil when no velocity")
    func machNilNoVelocity() {
        let ac = makeAircraft(velocity: nil)
        let data = EngineeringComputer.compute(for: ac)
        #expect(data.machNumber == nil)
    }

    // MARK: - Dynamic Pressure

    @Test("Dynamic pressure at sea level")
    func dynamicPressureSeaLevel() {
        let ac = makeAircraft(altitude: 0, velocity: 100)
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

    // MARK: - Energy Altitude

    @Test("Energy altitude exceeds geometric altitude")
    func energyAltitudeExceedsGeometric() {
        let ac = makeAircraft(altitude: 10_000, velocity: 250)
        let data = EngineeringComputer.compute(for: ac)
        #expect(data.energyAltitude! > 10_000)
        let expected = 10_000 + 250 * 250 / (2 * 9.80665)
        #expect(abs(data.energyAltitude! - expected) < 1)
    }

    // MARK: - Reynolds Number

    @Test("Reynolds number is positive and in millions at cruise")
    func reynoldsPositive() {
        let ac = makeAircraft(altitude: 10_000, velocity: 240)
        let data = EngineeringComputer.compute(for: ac)
        #expect(data.reynoldsNumber! > 1e6)
    }

    // MARK: - Airspeed Conversions

    @Test("EAS is less than TAS at altitude")
    func easLessThanTas() {
        let ac = makeAircraft(altitude: 10_000, velocity: 250)
        let data = EngineeringComputer.compute(for: ac)
        #expect(data.eas! < data.tas!)
    }

    @Test("EAS equals TAS at sea level")
    func easEqualsTasAtSeaLevel() {
        let ac = makeAircraft(altitude: 0, velocity: 200)
        let data = EngineeringComputer.compute(for: ac)
        #expect(abs(data.eas! - data.tas!) < 0.1)
    }

    @Test("EAS = TAS × √σ")
    func easFormula() {
        let ac = makeAircraft(altitude: 10_000, velocity: 250)
        let data = EngineeringComputer.compute(for: ac)
        let expected = data.tas! * sqrt(data.densityRatio)
        #expect(abs(data.eas! - expected) < 0.01)
    }

    // MARK: - Stagnation Temperature

    @Test("Stagnation temperature exceeds static temperature")
    func stagnationTempHigher() {
        let ac = makeAircraft(altitude: 10_000, velocity: 250)
        let data = EngineeringComputer.compute(for: ac)
        #expect(data.stagnationTemperature! > data.atmosphere.temperature)
    }

    @Test("Stagnation temperature formula T₀ = T(1 + (γ-1)/2·M²)")
    func stagnationTempFormula() {
        let ac = makeAircraft(altitude: 10_000, velocity: 240)
        let data = EngineeringComputer.compute(for: ac)
        let m = data.machNumber!
        let expected = data.atmosphere.temperature * (1 + 0.2 * m * m)
        #expect(abs(data.stagnationTemperature! - expected) < 0.01)
    }

    @Test("Ram temperature rise is positive at speed")
    func ramRisePositive() {
        let ac = makeAircraft(altitude: 10_000, velocity: 240)
        let data = EngineeringComputer.compute(for: ac)
        #expect(data.ramTemperatureRise! > 0)
    }

    // MARK: - Total Pressure

    @Test("Total pressure exceeds static pressure")
    func totalPressureHigher() {
        let ac = makeAircraft(altitude: 10_000, velocity: 250)
        let data = EngineeringComputer.compute(for: ac)
        #expect(data.totalPressure! > data.atmosphere.pressure)
    }

    @Test("Impact pressure equals total minus static")
    func impactPressure() {
        let ac = makeAircraft(altitude: 10_000, velocity: 250)
        let data = EngineeringComputer.compute(for: ac)
        let expected = data.totalPressure! - data.atmosphere.pressure
        #expect(abs(data.impactPressure! - expected) < 0.01)
    }

    // MARK: - Flight Path Angle

    @Test("Flight path angle positive when climbing")
    func flightPathAngleClimbing() {
        let ac = makeAircraft(altitude: 5_000, velocity: 200, verticalRate: 10.0)
        let data = EngineeringComputer.compute(for: ac)
        #expect(data.flightPathAngle! > 0)
    }

    @Test("Flight path angle negative when descending")
    func flightPathAngleDescending() {
        let ac = makeAircraft(altitude: 5_000, velocity: 200, verticalRate: -10.0)
        let data = EngineeringComputer.compute(for: ac)
        #expect(data.flightPathAngle! < 0)
    }

    @Test("Flight path angle near zero in cruise")
    func flightPathAngleCruise() {
        let ac = makeAircraft(altitude: 10_000, velocity: 250, verticalRate: 0)
        let data = EngineeringComputer.compute(for: ac)
        #expect(abs(data.flightPathAngle!) < 0.1)
    }

    // MARK: - Altitude References

    @Test("Density altitude defined")
    func densityAltitudeDefined() {
        let ac = makeAircraft(altitude: 10_000, velocity: 250)
        let data = EngineeringComputer.compute(for: ac)
        #expect(data.densityAltitude! > 0)
    }

    @Test("Density ratio σ between 0 and 1 at altitude")
    func densityRatioRange() {
        let ac = makeAircraft(altitude: 10_000, velocity: 250)
        let data = EngineeringComputer.compute(for: ac)
        #expect(data.densityRatio > 0)
        #expect(data.densityRatio < 1)
    }

    // MARK: - ISA Atmosphere

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
        #expect(abs(data.atmosphere.temperature - 216.65) < 0.5)
    }

    // MARK: - Flight Phase

    @Test("Flight phase detection")
    func flightPhaseDetection() {
        #expect(makeAircraft(verticalRate: 5.0).flightPhase == .climbing)
        #expect(makeAircraft(verticalRate: -5.0).flightPhase == .descending)
        #expect(makeAircraft(verticalRate: 0.5).flightPhase == .cruise)
        #expect(makeAircraft(onGround: true).flightPhase == .ground)
    }

    // MARK: - No Velocity

    @Test("No velocity shows dash for all computed values")
    func noVelocityDash() {
        let ac = makeAircraft(velocity: nil)
        let data = EngineeringComputer.compute(for: ac)
        #expect(data.machFormatted == "—")
        #expect(data.dynamicPressureFormatted == "—")
        #expect(data.energyAltitudeFormattedFt == "—")
        #expect(data.eas == nil)
        #expect(data.stagnationTemperature == nil)
        #expect(data.totalPressure == nil)
    }
}
