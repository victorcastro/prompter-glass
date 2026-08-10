import SwiftUI

struct OverlayView: View {
    let activeScript: ActiveScriptStore
    let playback: ScrollPlaybackController
    let voiceTracking: VoiceTrackingController
    let preferences: OverlayPreferencesStore
    let overlay: OverlayPresenter

    private static let cornerRadius: CGFloat = 18

    var body: some View {
        ZStack(alignment: .top) {
            Theme.Palette.overlayBackdrop
                .opacity(preferences.backgroundOpacity)

            content
                .padding(.top, 44)

            statusBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: OverlayView.cornerRadius, style: .continuous))
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

    private var statusBar: some View {
        HStack(spacing: 10) {
            PillBadge(
                text: playback.isPlaying ? "Rolling" : "Paused",
                leading: .dot,
                tint: playback.isPlaying ? Theme.Palette.accentIrisSoft : nil
            )
            if voiceTracking.isActive {
                PillBadge(
                    text: voiceTracking.state == .listening ? "Voice ready" : "Voice…",
                    leading: .icon("waveform"),
                    tint: Theme.Palette.accentAmber
                )
            }
            Text(metaLine)
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.55))
            Spacer()
            Image(systemName: "equal")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.45))
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
    }

    private var metaLine: String {
        var parts = ["\(Int(playback.speed)) pt/s"]
        if let remaining = remainingSeconds {
            parts.append("\(ScriptMetrics.formatted(seconds: remaining)) left")
        }
        if overlay.isClickThroughEnabled {
            parts.append("click-through")
        }
        return parts.joined(separator: " · ")
    }

    private var remainingSeconds: Int? {
        let engine = playback.engine
        guard engine.maxOffset > 0, playback.speed > 0 else { return nil }
        let remaining = (engine.maxOffset - engine.offset) / playback.speed
        guard remaining.isFinite, remaining >= 0 else { return nil }
        return Int(remaining.rounded())
    }

    private var script: some View {
        ScrollView(.vertical) {
            Text(attributedScript)
                .font(.system(size: preferences.fontSize, weight: .semibold, design: .rounded))
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
        .mask(depthFade)
    }

    private var depthFade: some View {
        LinearGradient(
            stops: [
                .init(color: .white, location: 0),
                .init(color: .white, location: 0.5),
                .init(color: .white.opacity(Theme.Palette.overlayUpcomingOpacity), location: 0.8),
                .init(color: .white.opacity(Theme.Palette.overlayUpcomingOpacity), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var attributedScript: AttributedString {
        let text = activeScript.text
        let baseColor = preferences.textColor.color
        let highlightLength = min(voiceTracking.highlightedUTF16Length, text.utf16.count)
        guard highlightLength > 0 else {
            var plain = AttributedString(text)
            plain.foregroundColor = baseColor
            return plain
        }
        let end = String.Index(utf16Offset: highlightLength, in: text)
        var spoken = AttributedString(String(text[..<end]))
        spoken.foregroundColor = Theme.Palette.overlaySpoken
        var upcoming = AttributedString(String(text[end...]))
        upcoming.foregroundColor = baseColor
        return spoken + upcoming
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
