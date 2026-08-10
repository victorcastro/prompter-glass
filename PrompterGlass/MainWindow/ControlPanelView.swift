import SwiftUI

struct ControlPanelView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                transportControls
                Spacer()
                windowToggles
            }

            settings
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.bar)
    }

    private var playback: ScrollPlaybackController {
        environment.playback
    }

    private var transportControls: some View {
        HStack(spacing: 8) {
            Button {
                playback.start()
            } label: {
                Label("Play", systemImage: "play.fill")
            }
            .accessibilityIdentifier(Identifier.play)
            .disabled(!playback.hasContent || playback.isPlaying)

            Button {
                playback.pause()
            } label: {
                Label("Pause", systemImage: "pause.fill")
            }
            .accessibilityIdentifier(Identifier.pause)
            .disabled(!playback.isPlaying)

            Button {
                playback.stop()
            } label: {
                Label("Stop", systemImage: "stop.fill")
            }
            .accessibilityIdentifier(Identifier.stop)
            .disabled(!playback.canStop)
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.bordered)
    }

    private var windowToggles: some View {
        @Bindable var overlay = environment.overlay

        return HStack(spacing: 12) {
            voiceControls

            Toggle("Overlay", isOn: overlayVisibility)
                .accessibilityIdentifier(Identifier.overlayToggle)

            Toggle("Click-through", isOn: $overlay.isClickThroughEnabled)
                .accessibilityIdentifier(Identifier.clickThroughToggle)
                .help("Let clicks pass through the overlay to the app underneath")
        }
        .toggleStyle(.switch)
        .controlSize(.small)
    }

    private var voiceControls: some View {
        HStack(spacing: 6) {
            Toggle("Voice", isOn: voiceTrackingEnabled)
                .accessibilityIdentifier(Identifier.voiceToggle)
                .disabled(!playback.hasContent)
                .help("Follow your voice through the script and highlight what you have read")

            voiceStatus
        }
    }

    @ViewBuilder
    private var voiceStatus: some View {
        switch environment.voiceTracking.state {
        case .idle, .listening:
            EmptyView()
        case .requestingPermission, .preparing:
            ProgressView()
                .controlSize(.small)
                .accessibilityIdentifier(Identifier.voicePreparing)
        case .denied:
            Button("Mic access denied — open Settings") {
                MicrophonePermission.openSystemSettings()
            }
            .buttonStyle(.link)
            .font(.caption)
            .accessibilityIdentifier(Identifier.voiceDenied)
        case .unavailable:
            Text("Voice tracking unavailable for this language")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier(Identifier.voiceUnavailable)
        }
    }

    private var settings: some View {
        @Bindable var preferences = environment.preferences
        @Bindable var playbackControls = environment.playback
        @Bindable var overlay = environment.overlay

        return Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {
            GridRow {
                Text("Speed")
                Slider(value: $playbackControls.speed, in: OverlayPreferencesStore.Limits.scrollSpeed)
                    .accessibilityIdentifier(Identifier.speedSlider)
                Text("\(Int(playback.speed)) pt/s")
                    .monospacedDigit()
            }
            GridRow {
                Text("Font size")
                Slider(value: $preferences.fontSize, in: OverlayPreferencesStore.Limits.fontSize)
                    .accessibilityIdentifier(Identifier.fontSizeSlider)
                Text("\(Int(environment.preferences.fontSize)) pt")
                    .monospacedDigit()
            }
            GridRow {
                Text("Background")
                Slider(value: $preferences.backgroundOpacity, in: OverlayPreferencesStore.Limits.backgroundOpacity)
                    .accessibilityIdentifier(Identifier.opacitySlider)
                Text("\(Int(environment.preferences.backgroundOpacity * 100))%")
                    .monospacedDigit()
            }
            GridRow {
                Text("Overlay size")
                sizeFields(overlay: $overlay)
                    .gridCellAnchor(.leading)
                Color.clear.frame(width: 1, height: 1)
            }
            GridRow {
                Text("Text color")
                ColorPicker("Text color", selection: textColor, supportsOpacity: false)
                    .labelsHidden()
                    .accessibilityIdentifier(Identifier.textColorPicker)
                    .gridCellAnchor(.leading)
                Color.clear.frame(width: 1, height: 1)
            }
        }
        .font(.callout)
        .foregroundStyle(.secondary)
    }

    private func sizeFields(overlay: Bindable<OverlayPresenter>) -> some View {
        HStack(spacing: 6) {
            TextField("Width", value: overlay.width, format: .number.precision(.fractionLength(0)))
                .accessibilityIdentifier(Identifier.overlayWidth)
                .frame(width: 64)
            Text("×")
            TextField("Height", value: overlay.height, format: .number.precision(.fractionLength(0)))
                .accessibilityIdentifier(Identifier.overlayHeight)
                .frame(width: 64)
            Text("pt")
        }
        .textFieldStyle(.roundedBorder)
        .multilineTextAlignment(.trailing)
        .monospacedDigit()
    }

    private var voiceTrackingEnabled: Binding<Bool> {
        Binding(
            get: { environment.voiceTracking.isActive },
            set: { environment.voiceTracking.setEnabled($0) }
        )
    }

    private var overlayVisibility: Binding<Bool> {
        Binding(
            get: { environment.overlay.isVisible },
            set: { environment.setOverlayVisible($0) }
        )
    }

    private var textColor: Binding<Color> {
        Binding(
            get: { environment.preferences.textColor.color },
            set: { environment.preferences.textColor = RGBAColor($0) }
        )
    }
}

extension ControlPanelView {
    enum Identifier {
        static let play = "controls.play"
        static let pause = "controls.pause"
        static let stop = "controls.stop"
        static let overlayToggle = "controls.overlayToggle"
        static let clickThroughToggle = "controls.clickThroughToggle"
        static let voiceToggle = "controls.voiceToggle"
        static let voicePreparing = "controls.voicePreparing"
        static let voiceDenied = "controls.voiceDenied"
        static let voiceUnavailable = "controls.voiceUnavailable"
        static let speedSlider = "controls.speed"
        static let fontSizeSlider = "controls.fontSize"
        static let opacitySlider = "controls.opacity"
        static let textColorPicker = "controls.textColor"
        static let overlayWidth = "controls.overlayWidth"
        static let overlayHeight = "controls.overlayHeight"
    }
}
