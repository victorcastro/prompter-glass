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
            ZStack(alignment: .topLeading) {
                scriptText(glowLayerText)
                    .shadow(
                        color: preferences.recognitionColor.color.opacity(0.6),
                        radius: 22
                    )
                scriptText(baseLayerText)
                    .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
            }
            .animation(.linear(duration: 0.16), value: voiceTracking.highlightedUTF16Length)
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

    private func scriptText(_ attributed: AttributedString) -> some View {
        Text(attributed)
            .font(.system(size: preferences.fontSize, weight: .semibold, design: .rounded))
            .lineSpacing(preferences.fontSize * 0.3)
            .multilineTextAlignment(.leading)
    }

    private var textStateBounds: (currentStart: String.Index, spokenEnd: String.Index)? {
        let text = activeScript.text
        let highlightLength = min(voiceTracking.highlightedUTF16Length, text.utf16.count)
        guard highlightLength > 0 else { return nil }
        let spokenEnd = String.Index(utf16Offset: highlightLength, in: text)
        let spoken = text[..<spokenEnd]
        let currentStart = spoken.lastIndex(where: \.isWhitespace)
            .map(text.index(after:)) ?? text.startIndex
        return (currentStart, spokenEnd)
    }

    private var baseLayerText: AttributedString {
        let text = activeScript.text
        guard let bounds = textStateBounds else {
            var plain = AttributedString(text)
            plain.foregroundColor = preferences.textColor.color
            return plain
        }
        var said = AttributedString(String(text[..<bounds.spokenEnd]))
        said.foregroundColor = preferences.recognitionColor.color
        var upcoming = AttributedString(String(text[bounds.spokenEnd...]))
        upcoming.foregroundColor = preferences.textColor.color
        return said + upcoming
    }

    private var glowLayerText: AttributedString {
        let text = activeScript.text
        guard let bounds = textStateBounds else {
            var hidden = AttributedString(text)
            hidden.foregroundColor = .clear
            return hidden
        }
        var before = AttributedString(String(text[..<bounds.currentStart]))
        before.foregroundColor = .clear
        var current = AttributedString(String(text[bounds.currentStart ..< bounds.spokenEnd]))
        current.foregroundColor = preferences.recognitionColor.color
        var after = AttributedString(String(text[bounds.spokenEnd...]))
        after.foregroundColor = .clear
        return before + current + after
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
