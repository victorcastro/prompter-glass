import SwiftUI

struct IconChip: View {
    enum Style {
        case irisGradient
        case tinted(Color)
        case neutral
    }

    let systemImage: String
    var style: Style = .neutral
    var side: CGFloat = 28

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: side * 0.42, weight: .semibold))
            .foregroundStyle(foreground)
            .frame(width: side, height: side)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: side * 0.3, style: .continuous))
    }

    private var foreground: Color {
        switch style {
        case .irisGradient: .white
        case let .tinted(color): color
        case .neutral: Theme.Palette.textPrimary
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .irisGradient:
            LinearGradient(
                colors: [Theme.Palette.accentIrisSoft, Theme.Palette.accentIris],
                startPoint: .top,
                endPoint: .bottom
            )
        case let .tinted(color):
            color.opacity(0.22)
        case .neutral:
            Color.white.opacity(0.14)
        }
    }
}
