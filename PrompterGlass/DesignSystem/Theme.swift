import SwiftUI

enum Theme {
    enum Palette {
        static let accentIris = Color(hex: 0x7C6CF0)
        static let accentIrisSoft = Color(hex: 0x9D8FF5)
        static let accentAmber = Color(hex: 0xF5C842)
        static let orbTop = Color(hex: 0xC8D4EE)
        static let orbBottom = Color(hex: 0x8B7FD6)
        static let sidebarBase = Color(hex: 0x191428)
        static let textPrimary = Color(hex: 0xF2F0FA)
        static let textSecondary = Color.white.opacity(0.62)
        static let textTertiary = Color.white.opacity(0.40)
        static let overlaySpoken = Color(hex: 0xF0C93F)
        static let overlayCurrent = Color(hex: 0xE9F2EC)
        static let overlayUpcomingOpacity = 0.38
        static let overlayBackdrop = Color(hex: 0x6B6B6B)
    }

    enum Glass {
        static let fill = Color.white.opacity(0.07)
        static let fillHighlighted = Color.white.opacity(0.13)
        static let stroke = Color.white.opacity(0.12)
        static let cornerRadius: CGFloat = 16
    }

    enum Mood {
        case purple
        case forest
        case slate

        var high: Color {
            switch self {
            case .purple: Color(hex: 0x3D3168)
            case .forest: Color(hex: 0x2E4237)
            case .slate: Color(hex: 0x2E3742)
            }
        }

        var low: Color {
            switch self {
            case .purple: Color(hex: 0x231C3D)
            case .forest: Color(hex: 0x1C2823)
            case .slate: Color(hex: 0x1B2129)
            }
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
