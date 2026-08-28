import SwiftUI

/// The line under the voice tracking row. Activation can fail for several reasons the user can act
/// on, so every state that is not listening says which one it is and what to do about it.
struct VoiceStatusView: View {
    let state: VoiceTrackingController.State
    let onOpenLibrary: () -> Void
    let onRetry: () -> Void

    var body: some View {
        content
            .padding(.leading, 46)
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .idle, .listening:
            EmptyView()
        case .noScript:
            message(
                "Pick a script first",
                identifier: ControlIdentifier.voiceNoScript,
                actionTitle: "Open library",
                actionIdentifier: ControlIdentifier.voiceNoScriptOpen,
                action: onOpenLibrary
            )
        case .requestingPermission, .preparing:
            progress("Starting voice tracking…", identifier: ControlIdentifier.voicePreparing)
        case let .downloadingModel(language):
            progress(
                "Downloading the \(language) speech model…",
                identifier: ControlIdentifier.voiceDownloadingModel
            )
        case .denied:
            Button("Mic access denied — open Settings") {
                MicrophonePermission.openSystemSettings()
            }
            .buttonStyle(.link)
            .font(.caption)
            .accessibilityIdentifier(ControlIdentifier.voiceDenied)
        case let .unavailable(reason):
            message(
                VoiceStatusView.text(for: reason),
                identifier: ControlIdentifier.voiceUnavailable,
                actionTitle: "Retry",
                actionIdentifier: ControlIdentifier.voiceRetry,
                action: onRetry
            )
        }
    }

    private func progress(_ label: String, identifier: String) -> some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            caption(label)
        }
        .accessibilityIdentifier(identifier)
    }

    private func message(
        _ label: String,
        identifier: String,
        actionTitle: String,
        actionIdentifier: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 8) {
            caption(label)
                .accessibilityIdentifier(identifier)
            Button(actionTitle, action: action)
                .buttonStyle(.link)
                .font(.caption)
                .accessibilityIdentifier(actionIdentifier)
        }
    }

    private func caption(_ label: String) -> some View {
        Text(label)
            .font(.caption)
            .foregroundStyle(Theme.Palette.textTertiary)
    }

    static func text(for reason: VoiceTrackingController.Reason) -> String {
        switch reason {
        case .languageNotSupported:
            "Voice tracking unavailable for this language"
        case .modelUnavailable:
            "The speech model could not be downloaded"
        case .audioInputFailed:
            "The microphone could not be started"
        case .unknown:
            "Voice tracking could not start"
        }
    }
}
