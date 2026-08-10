import SwiftUI

struct RollOrb: View {
    let title: String
    var isEnabled = true
    var accessibilityIdentifier: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.Palette.orbTop, Theme.Palette.orbBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.55), .clear],
                            center: UnitPoint(x: 0.5, y: 0.18),
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                Circle()
                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x2A2447))
            }
            .frame(width: 92, height: 92)
            .shadow(color: Theme.Palette.accentIris.opacity(0.55), radius: 28, y: 6)
            .scaleEffect(isPressed ? 0.96 : 1)
            .opacity(isEnabled ? 1 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityIdentifier(accessibilityIdentifier)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .animation(.easeOut(duration: 0.12), value: isPressed)
    }
}
