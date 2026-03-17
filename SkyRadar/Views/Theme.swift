import SwiftUI

// MARK: - Color Palette

extension Color {
    // Primary accent — aviation cyan
    static let radarCyan = Color(hex: 0x00B4D8)
    static let radarBlue = Color(hex: 0x0077B6)
    static let radarNavy = Color(hex: 0x023E8A)
    static let radarDark = Color(hex: 0x0A1628)

    // Data colors
    static let altitudeGreen = Color(hex: 0x2DC653)
    static let speedAmber = Color(hex: 0xFFB703)
    static let machOrange = Color(hex: 0xFB8500)
    static let pressurePurple = Color(hex: 0x8338EC)
    static let energyTeal = Color(hex: 0x06D6A0)
    static let reynoldsRose = Color(hex: 0xEF476F)

    // Flight phase colors
    static let phaseGround = Color(hex: 0x8D99AE)
    static let phaseClimb = Color(hex: 0x2DC653)
    static let phaseCruise = Color(hex: 0x00B4D8)
    static let phaseDescent = Color(hex: 0xFFB703)
    static let phaseUnknown = Color(hex: 0x8D99AE)

    // Altitude band colors
    static func altitudeColor(meters: Double) -> Color {
        switch meters {
        case ..<1_000:  return .altitudeGreen
        case ..<5_000:  return .altitudeGreen.opacity(0.8)
        case ..<8_000:  return .speedAmber
        case ..<11_000: return .machOrange
        default:        return .reynoldsRose
        }
    }

    static func flightPhaseColor(_ phase: FlightPhase) -> Color {
        switch phase {
        case .ground:     return .phaseGround
        case .climbing:   return .phaseClimb
        case .cruise:     return .phaseCruise
        case .descending: return .phaseDescent
        case .unknown:    return .phaseUnknown
        }
    }

    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

// MARK: - Card Styles

struct GlassCard: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 0.5)
            )
    }
}

struct DataCard: ViewModifier {
    let accentColor: Color

    func body(content: Content) -> some View {
        content
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(accentColor.gradient)
                            .frame(width: 4)
                            .padding(.vertical, 6)
                    }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 0.5)
            )
    }
}

extension View {
    func glassCard(padding: CGFloat = 16) -> some View {
        modifier(GlassCard(padding: padding))
    }

    func dataCard(accent: Color) -> some View {
        modifier(DataCard(accentColor: accent))
    }
}

// MARK: - Data Display Components

struct DataValue: View {
    let label: String
    let value: String
    let unit: String
    var color: Color = .primary
    var monospacedValue: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(monospacedValue ? .title3.monospacedDigit().bold() : .title3.bold())
                    .foregroundStyle(color)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct EngineeringCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let subtitle: String?
    let color: Color

    init(
        icon: String,
        title: String,
        value: String,
        unit: String = "",
        subtitle: String? = nil,
        color: Color
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.unit = unit
        self.subtitle = subtitle
        self.color = color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                    .frame(width: 20, height: 20)
                    .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 5))

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.title3.monospacedDigit().bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dataCard(accent: color)
    }
}

// MARK: - Status Badge

struct PhaseBadge: View {
    let phase: FlightPhase

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: phase.symbolName)
                .font(.caption2)
            Text(phase.rawValue)
                .font(.caption2.weight(.medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.flightPhaseColor(phase).opacity(0.2), in: Capsule())
        .foregroundStyle(Color.flightPhaseColor(phase))
    }
}

// MARK: - Pulsing Dot

struct PulsingDot: View {
    let color: Color
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(color, lineWidth: 1)
                    .scaleEffect(isPulsing ? 2.5 : 1)
                    .opacity(isPulsing ? 0 : 0.6)
            )
            .onAppear {
                withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    isPulsing = true
                }
            }
    }
}
