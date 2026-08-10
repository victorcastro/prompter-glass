import SwiftUI

struct PrompterSectionView: View {
    let onOpenLibrary: () -> Void

    @Environment(AppEnvironment.self) private var environment

    @State private var microphones: [AudioInputDevice] = []
    @State private var isShowingSettings = false

    var body: some View {
        VStack(spacing: 0) {
            if let script = environment.activeScript.script {
                hero(for: script)
            } else {
                emptyState
            }
            featureRows
                .padding(.top, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 16)
            controlsBar
            transport
                .padding(.top, 18)
                .padding(.bottom, 20)
        }
        .padding(.horizontal, 32)
        .padding(.top, 40)
        .task { microphones = AudioInputDevices.available() }
    }

    private func hero(for script: Script) -> some View {
        HStack(alignment: .center, spacing: 36) {
            heroPanelGraphic
            VStack(alignment: .leading, spacing: 14) {
                Text(script.title)
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(Theme.Palette.textPrimary)
                    .lineLimit(2)
                Text(heroSubtitle(for: script))
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func heroSubtitle(for script: Script) -> String {
        let words = ScriptMetrics.wordCount(of: script.body)
        let onAir = ScriptMetrics.onAirLabel(wordCount: words)
        return "\(words) words · about \(onAir) on air. "
            + "The glass panel sits under your webcam so your eyes stay in frame."
    }

    private var heroPanelGraphic: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(0 ..< 3, id: \.self) { line in
                    Capsule()
                        .fill(Color.white.opacity(0.55 - Double(line) * 0.12))
                        .frame(width: 120 - CGFloat(line) * 28, height: 9)
                }
            }
            .padding(28)
            .frame(width: 220, height: 150, alignment: .leading)
        }
        .rotation3DEffect(.degrees(8), axis: (x: 0.4, y: -1, z: 0.1))
        .shadow(color: .black.opacity(0.35), radius: 24, y: 14)
    }

    private var featureRows: some View {
        VStack(alignment: .leading, spacing: 12) {
            FeatureRow(
                icon: "waveform",
                tint: Theme.Palette.accentAmber,
                name: "Voice tracking",
                detail: voiceDetail,
                toggle: voiceTrackingEnabled,
                identifier: ControlIdentifier.voiceToggle,
                disabled: !environment.playback.hasContent
            )
            voiceStatus
            FeatureRow(
                icon: "cursorarrow.rays",
                tint: Theme.Palette.accentIris,
                name: "Click-through",
                detail: environment.overlay.isClickThroughEnabled ? "cursor passes through" : "off",
                toggle: clickThroughEnabled,
                identifier: ControlIdentifier.clickThroughToggle,
                disabled: false
            )
        }
    }

    private var voiceDetail: String {
        environment.voiceTracking.isActive ? "highlights what you have said" : "off"
    }

    @ViewBuilder
    private var voiceStatus: some View {
        switch environment.voiceTracking.state {
        case .idle, .listening:
            EmptyView()
        case .requestingPermission, .preparing:
            ProgressView()
                .controlSize(.small)
                .accessibilityIdentifier(ControlIdentifier.voicePreparing)
        case .denied:
            Button("Mic access denied — open Settings") {
                MicrophonePermission.openSystemSettings()
            }
            .buttonStyle(.link)
            .font(.caption)
            .accessibilityIdentifier(ControlIdentifier.voiceDenied)
        case .unavailable:
            Text("Voice tracking unavailable for this language")
                .font(.caption)
                .foregroundStyle(Theme.Palette.textTertiary)
                .accessibilityIdentifier(ControlIdentifier.voiceUnavailable)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            heroPanelGraphic
            Text("No script selected")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(Theme.Palette.textPrimary)
            Button("Pick one from the Library", action: onOpenLibrary)
                .buttonStyle(.borderedProminent)
                .tint(Theme.Palette.accentIris)
        }
        .frame(maxWidth: .infinity)
    }

    private var controlsBar: some View {
        @Bindable var preferences = environment.preferences
        @Bindable var playbackControls = environment.playback

        return GlassCard {
            HStack(spacing: 24) {
                sliderColumn(
                    label: "Speed",
                    value: "\(Int(environment.playback.speed)) pt/s",
                    binding: $playbackControls.speed,
                    range: OverlayPreferencesStore.Limits.scrollSpeed,
                    identifier: ControlIdentifier.speed
                )
                sliderColumn(
                    label: "Text size",
                    value: "\(Int(environment.preferences.fontSize)) pt",
                    binding: $preferences.fontSize,
                    range: OverlayPreferencesStore.Limits.fontSize,
                    identifier: ControlIdentifier.fontSize
                )
                sliderColumn(
                    label: "Backdrop",
                    value: "\(Int(environment.preferences.backgroundOpacity * 100))%",
                    binding: $preferences.backgroundOpacity,
                    range: OverlayPreferencesStore.Limits.backgroundOpacity,
                    identifier: ControlIdentifier.opacity
                )
                settingsButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
    }

    private func sliderColumn(
        label: String,
        value: String,
        binding: Binding<Double>,
        range: ClosedRange<Double>,
        identifier: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Palette.textSecondary)
                Spacer()
                Text(value)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.Palette.textPrimary)
                    .monospacedDigit()
            }
            Slider(value: binding, in: range)
                .controlSize(.small)
                .tint(Theme.Palette.accentIris)
                .accessibilityIdentifier(identifier)
        }
        .frame(maxWidth: .infinity)
    }

    private var settingsButton: some View {
        Button {
            isShowingSettings.toggle()
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.Palette.textSecondary)
                .padding(8)
                .background(Color.white.opacity(0.08))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("controls.settings")
        .popover(isPresented: $isShowingSettings, arrowEdge: .top) {
            PrompterSettingsPopover(microphones: microphones)
                .environment(environment)
        }
    }

    private var transport: some View {
        let playback = environment.playback
        return ZStack {
            RollOrb(
                title: playback.isPlaying ? "Pause" : "Roll",
                isEnabled: playback.hasContent,
                accessibilityIdentifier: playback.isPlaying ? ControlIdentifier.pause : ControlIdentifier.play
            ) {
                playback.toggle()
            }
            HStack {
                Spacer()
                stopButton
            }
            .frame(maxWidth: 320)
        }
    }

    private var stopButton: some View {
        let canStop = environment.playback.canStop || environment.voiceTracking.isActive
        return Button {
            environment.stopPlayback()
        } label: {
            PillBadge(text: "Stop", leading: .icon("stop.fill"))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(ControlIdentifier.stop)
        .disabled(!canStop)
        .opacity(canStop ? 1 : 0.4)
    }

    private var voiceTrackingEnabled: Binding<Bool> {
        Binding(
            get: { environment.voiceTracking.isActive },
            set: { environment.voiceTracking.setEnabled($0) }
        )
    }

    private var clickThroughEnabled: Binding<Bool> {
        Binding(
            get: { environment.overlay.isClickThroughEnabled },
            set: { environment.overlay.isClickThroughEnabled = $0 }
        )
    }
}
