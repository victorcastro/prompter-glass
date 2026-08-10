import SwiftUI

enum Theme {
    enum Palette {
        static let accentIris = Color(hex: 0x7C6CF0)
        static let accentIrisSoft = Color(hex: 0x9D8FF5)
        static let accentAmber = Color(hex: 0xF5C842)
        static let orbTop = Color(hex: 0xC8D4EE)
        static let orbBottom = Color(hex: 0x8B7FD6)
        static let sidebarScrim = Color.black.opacity(0.28)
        static let textPrimary = Color(hex: 0xF2F0FA)
        static let textSecondary = Color.white.opacity(0.62)
        static let textTertiary = Color.white.opacity(0.40)
        static let overlayBackdrop = Color(hex: 0x6B6B6B)
    }

    enum Glass {
        static let fill = Color.white.opacity(0.07)
        static let fillHighlighted = Color.white.opacity(0.13)
        static let stroke = Color.white.opacity(0.10)
        static let cornerRadius: CGFloat = 16
    }

    struct MoodHalo: Equatable {
        let width: CGFloat
        let height: CGFloat
        let centerX: CGFloat
        let centerY: CGFloat
        let opacity: Double
    }

    enum Mood: Equatable {
        case purple
        case forest
        case slate

        var baseStops: [Gradient.Stop] {
            switch self {
            case .purple:
                [
                    .init(color: Color(hex: 0x221A4D), location: 0),
                    .init(color: Color(hex: 0x2C1F63), location: 0.36),
                    .init(color: Color(hex: 0x181341), location: 0.74),
                    .init(color: Color(hex: 0x0B0920), location: 1)
                ]
            case .forest:
                [
                    .init(color: Color(hex: 0x0B2F2A), location: 0),
                    .init(color: Color(hex: 0x0A3B34), location: 0.34),
                    .init(color: Color(hex: 0x07231F), location: 0.72),
                    .init(color: Color(hex: 0x050F0E), location: 1)
                ]
            case .slate:
                [
                    .init(color: Color(hex: 0x1E2735), location: 0),
                    .init(color: Color(hex: 0x253243), location: 0.35),
                    .init(color: Color(hex: 0x141B26), location: 0.73),
                    .init(color: Color(hex: 0x0A0E14), location: 1)
                ]
            }
        }

        var glow: Color {
            switch self {
            case .purple: Color(hex: 0x9B85EE)
            case .forest: Color(hex: 0x8FD3BC)
            case .slate: Color(hex: 0x8FB0D6)
            }
        }

        var halos: [MoodHalo] {
            switch self {
            case .purple:
                [
                    MoodHalo(width: 0.95, height: 0.80, centerX: 0.52, centerY: 0.26, opacity: 0.22),
                    MoodHalo(width: 0.45, height: 0.45, centerX: 0.88, centerY: 0.92, opacity: 0.09)
                ]
            case .forest:
                [
                    MoodHalo(width: 0.95, height: 0.80, centerX: 0.55, centerY: 0.30, opacity: 0.20),
                    MoodHalo(width: 0.45, height: 0.45, centerX: 0.88, centerY: 0.92, opacity: 0.08)
                ]
            case .slate:
                [
                    MoodHalo(width: 0.95, height: 0.80, centerX: 0.52, centerY: 0.26, opacity: 0.18),
                    MoodHalo(width: 0.45, height: 0.45, centerX: 0.88, centerY: 0.92, opacity: 0.08)
                ]
            }
        }
    }
}
