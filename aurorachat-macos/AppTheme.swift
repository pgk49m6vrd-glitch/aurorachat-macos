import SwiftUI

// MARK: - Theme Enum
// TODO: add yosemite / leopard themes later?

enum AppTheme: String, CaseIterable, Identifiable {
    case liquidGlass = "liquidGlass"
    case sonoma = "sonoma"
    case aqua = "aqua"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .liquidGlass: return "Liquid Glass"
        case .sonoma: return "Sonoma Glass"
        case .aqua: return "Aqua"
        }
    }

    var subtitle: String {
        switch self {
        case .liquidGlass: return "macOS 26 Tahoe"
        case .sonoma: return "macOS 15 Sonoma"
        case .aqua: return "Classic Mac OS X"
        }
    }

    var icon: String {
        switch self {
        case .liquidGlass: return "drop.fill"
        case .sonoma: return "sparkles"
        case .aqua: return "bubbles.and.sparkles.fill"
        }
    }

    var minimumOS: String {
        switch self {
        case .liquidGlass: return "macOS 26+"
        case .sonoma: return "macOS 15+"
        case .aqua: return "macOS 13+"
        }
    }

    var isAvailable: Bool {
        switch self {
        case .liquidGlass:
            if #available(macOS 26, *) { return true }
            return false
        case .sonoma:
            if #available(macOS 15, *) { return true }
            return false
        case .aqua:
            return true
        }
    }

    static var bestAvailable: AppTheme {
        if AppTheme.liquidGlass.isAvailable { return .liquidGlass }
        if AppTheme.sonoma.isAvailable { return .sonoma }
        return .aqua
    }

    var colors: ThemeColors {
        switch self {
        case .liquidGlass: return .liquidGlass
        case .sonoma: return .sonoma
        case .aqua: return .aqua
        }
    }
}

// theme color definitions

struct ThemeColors {
    let accent: Color
    let accentGradient: [Color]
    let sidebarBg: Color
    let inputBg: Color
    let cardBg: Color
    let buttonStyle: ButtonStyleType
    let cornerRadius: CGFloat

    enum ButtonStyleType {
        case modern
        case aquaGel
    }

    // purple-ish for the glass look

    static let liquidGlass = ThemeColors(
        accent: Color(red: 0.55, green: 0.3, blue: 0.95),
        accentGradient: [
            Color(red: 0.45, green: 0.25, blue: 0.95),
            Color(red: 0.65, green: 0.3, blue: 0.85)
        ],
        sidebarBg: Color.clear,
        inputBg: Color.clear,
        cardBg: Color.clear,
        buttonStyle: .modern,
        cornerRadius: 22
    )

    // MARK: - Sonoma

    static let sonoma = ThemeColors(
        accent: Color(red: 0.5, green: 0.3, blue: 0.9),
        accentGradient: [
            Color(red: 0.4, green: 0.3, blue: 0.9),
            Color(red: 0.6, green: 0.2, blue: 0.8)
        ],
        sidebarBg: Color(nsColor: .controlBackgroundColor),
        inputBg: Color(nsColor: .textBackgroundColor),
        cardBg: Color(nsColor: .controlBackgroundColor),
        buttonStyle: .modern,
        cornerRadius: 10
    )

    // MARK: - Aqua

    static let aqua = ThemeColors(
        accent: Color(red: 0.2, green: 0.45, blue: 0.9),
        accentGradient: [
            Color(red: 0.3, green: 0.55, blue: 1.0),
            Color(red: 0.15, green: 0.35, blue: 0.85)
        ],
        sidebarBg: Color(red: 0.85, green: 0.88, blue: 0.93),
        inputBg: Color.white,
        cardBg: Color.white,
        buttonStyle: .aquaGel,
        cornerRadius: 6
    )
}

// the old school aqua gel button

struct AquaButtonStyle: ButtonStyle {
    var isPrimary: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: isPrimary
                                ? [Color(red: 0.45, green: 0.65, blue: 1.0),
                                   Color(red: 0.2, green: 0.4, blue: 0.9),
                                   Color(red: 0.15, green: 0.35, blue: 0.85)]
                                : [Color.white, Color(red: 0.9, green: 0.9, blue: 0.92)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
            )
            .foregroundStyle(isPrimary ? .white : .primary)
            .fontWeight(.medium)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
}

// classic pinstripes lol

struct AquaPinstripeBackground: View {
    var body: some View {
        Canvas { context, size in
            let stripeWidth: CGFloat = 2
            var x: CGFloat = 0
            while x < size.width {
                let rect = CGRect(x: x, y: 0, width: 1, height: size.height)
                context.fill(Path(rect), with: .color(.black.opacity(0.018)))
                x += stripeWidth
            }
        }
        .background(Color(red: 0.92, green: 0.94, blue: 0.97))
    }
}
