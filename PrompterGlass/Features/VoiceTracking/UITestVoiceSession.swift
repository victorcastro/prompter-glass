#if DEBUG
    import Foundation

    /// Debug-only stand-in that fails the way a missing speech model does, so the UI tests can reach
    /// the unavailable state without a microphone. Not compiled into release builds.
    @MainActor
    final class UITestVoiceSession: VoiceTranscribing {
        static let failureArgument = "-ui-testing-voice-failure"

        nonisolated static var isRequested: Bool {
            ProcessInfo.processInfo.arguments.contains(failureArgument)
        }

        func start(
            deviceUID _: String?,
            onPhase _: @escaping @MainActor (VoiceTranscriptionSession.Phase) -> Void,
            onUpdate _: @escaping @MainActor (VoiceTranscriptionSession.Update) -> Void
        ) async throws {
            throw VoiceTranscriptionSession.SessionError.modelUnavailable
        }

        func stop() {}
    }
#endif
