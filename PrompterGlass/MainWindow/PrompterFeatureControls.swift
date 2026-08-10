import SwiftUI

struct FeatureRow: View {
    let icon: String
    let tint: Color
    let name: String
    let detail: String
    let toggle: Binding<Bool>
    let identifier: String
    let disabled: Bool

    var body: some View {
        HStack(spacing: 14) {
            IconChip(systemImage: icon, style: .tinted(tint), side: 32)
            Text(name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.Palette.textPrimary)
            Text(detail)
                .font(.system(size: 13))
                .foregroundStyle(Theme.Palette.textTertiary)
            Toggle(name, isOn: toggle)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
                .tint(Theme.Palette.accentIris)
                .accessibilityIdentifier(identifier)
                .disabled(disabled)
                .padding(.leading, 4)
        }
    }
}

struct PrompterSettingsPopover: View {
    let microphones: [AudioInputDevice]

    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        @Bindable var overlay = environment.overlay

        return Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                Text("Microphone")
                microphonePicker
            }
            GridRow {
                Text("Overlay size")
                sizeFields(overlay: $overlay)
            }
            GridRow {
                Text("Text color")
                ColorPicker("Text color", selection: textColor, supportsOpacity: false)
                    .labelsHidden()
                    .accessibilityIdentifier(ControlIdentifier.textColor)
            }
            GridRow {
                Text("Recognition color")
                ColorPicker("Recognition color", selection: recognitionColor, supportsOpacity: false)
                    .labelsHidden()
                    .accessibilityIdentifier("controls.recognitionColor")
            }
        }
        .font(.callout)
        .padding(16)
        .frame(minWidth: 300)
    }

    private func sizeFields(overlay: Bindable<OverlayPresenter>) -> some View {
        HStack(spacing: 6) {
            TextField("Width", value: overlay.width, format: .number.precision(.fractionLength(0)))
                .accessibilityIdentifier(ControlIdentifier.overlayWidth)
                .frame(width: 64)
            Text("×")
            TextField("Height", value: overlay.height, format: .number.precision(.fractionLength(0)))
                .accessibilityIdentifier(ControlIdentifier.overlayHeight)
                .frame(width: 64)
            Text("pt")
        }
        .textFieldStyle(.roundedBorder)
        .multilineTextAlignment(.trailing)
        .monospacedDigit()
    }

    private var microphonePicker: some View {
        Picker("Microphone", selection: microphoneSelection) {
            Text("System Default").tag(String?.none)
            ForEach(microphones) { device in
                Text(device.name).tag(String?.some(device.uid))
            }
        }
        .labelsHidden()
        .frame(maxWidth: 240)
        .accessibilityIdentifier(ControlIdentifier.microphonePicker)
        .help("Microphone used for voice tracking")
    }

    private var microphoneSelection: Binding<String?> {
        Binding(
            get: { environment.voiceTracking.microphoneUID },
            set: { environment.selectMicrophone(uid: $0) }
        )
    }

    private var textColor: Binding<Color> {
        Binding(
            get: { environment.preferences.textColor.color },
            set: { environment.preferences.textColor = RGBAColor($0) }
        )
    }

    private var recognitionColor: Binding<Color> {
        Binding(
            get: { environment.preferences.recognitionColor.color },
            set: { environment.preferences.recognitionColor = RGBAColor($0) }
        )
    }
}
