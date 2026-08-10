import SwiftUI

struct OverlayView: View {
    let activeScript: ActiveScriptStore
    let playback: ScrollPlaybackController
    let preferences: OverlayPreferencesStore

    var body: some View {
        ZStack(alignment: .top) {
            Color.black
                .opacity(preferences.backgroundOpacity)
                .ignoresSafeArea()

            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier(OverlayView.accessibilityIdentifier)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
            playback.engine.updateViewportHeight(Double(height))
        }
    }

    @ViewBuilder
    private var content: some View {
        if activeScript.hasRenderableText {
            script
        } else {
            emptyState
        }
    }

    private var script: some View {
        ScrollView(.vertical) {
            Text(activeScript.text)
                .font(.system(size: preferences.fontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(preferences.textColor.color)
                .lineSpacing(preferences.fontSize * 0.3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                    playback.engine.updateContentHeight(Double(height))
                }
                .offset(y: -playback.engine.offset)
        }
        .scrollDisabled(true)
        .scrollIndicators(.hidden)
    }

    private var emptyState: some View {
        Text("No script selected")
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundStyle(preferences.textColor.color.opacity(0.6))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension OverlayView {
    static let accessibilityIdentifier = "overlay.root"
}
