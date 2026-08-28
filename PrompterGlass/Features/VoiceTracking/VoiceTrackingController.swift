import Foundation
import Observation

@MainActor
protocol VoiceTranscribing: AnyObject {
    func start(
        deviceUID: String?,
        onPhase: @escaping @MainActor (VoiceTranscriptionSession.Phase) -> Void,
        onUpdate: @escaping @MainActor (VoiceTranscriptionSession.Update) -> Void
    ) async throws
    func stop()
}

extension VoiceTranscriptionSession: VoiceTranscribing {}

struct MicrophonePermissionClient {
    var status: () -> MicrophonePermission.Status
    var request: () async -> Bool

    static let live = MicrophonePermissionClient(
        status: { MicrophonePermission.status },
        request: { await MicrophonePermission.request() }
    )
}

@MainActor
@Observable
final class VoiceTrackingController {
    enum State: Equatable {
        case idle
        case noScript
        case requestingPermission
        case downloadingModel(language: String)
        case preparing
        case listening
        case denied
        case unavailable(Reason)
    }

    /// Why voice tracking could not start. Kept separate from the state so every failure can carry
    /// its own message instead of being reported as a language problem.
    enum Reason: Equatable {
        case languageNotSupported
        case modelUnavailable
        case audioInputFailed
        case unknown

        init(_ error: Error) {
            switch error as? VoiceTranscriptionSession.SessionError {
            case .localeNotSupported:
                self = .languageNotSupported
            case .modelUnavailable:
                self = .modelUnavailable
            case .audioFormatUnavailable, .audioEngineFailed:
                self = .audioInputFailed
            case nil:
                self = .unknown
            }
        }
    }

    static let defaultActivationTimeout = Duration.seconds(120)

    private(set) var state: State = .idle
    private(set) var highlightedUTF16Length = 0
    private(set) var confirmedWordCount = 0

    @ObservationIgnored
    var onWordCountChanged: ((Int) -> Void)?

    private(set) var microphoneUID: String?

    @ObservationIgnored
    private var scriptText = ""

    @ObservationIgnored
    private var aligner = ScriptAligner(tokens: [])

    @ObservationIgnored
    private var volatileWordCount = 0

    @ObservationIgnored
    private var session: VoiceTranscribing?

    @ObservationIgnored
    private var startTask: Task<Void, Never>?

    @ObservationIgnored
    private let playback: ScrollPlaybackController

    @ObservationIgnored
    private let permission: MicrophonePermissionClient

    @ObservationIgnored
    private let makeSession: @MainActor () -> VoiceTranscribing

    @ObservationIgnored
    private let activationTimeout: Duration

    @ObservationIgnored
    private var watchdog: Task<Void, Never>?

    @ObservationIgnored
    private var activationID = 0

    init(
        playback: ScrollPlaybackController,
        permission: MicrophonePermissionClient,
        makeSession: @escaping @MainActor () -> VoiceTranscribing,
        activationTimeout: Duration = VoiceTrackingController.defaultActivationTimeout
    ) {
        self.playback = playback
        self.permission = permission
        self.makeSession = makeSession
        self.activationTimeout = activationTimeout
    }

    var isActive: Bool {
        switch state {
        case .requestingPermission, .downloadingModel, .preparing, .listening:
            true
        case .idle, .noScript, .denied, .unavailable:
            false
        }
    }

    var canRetry: Bool {
        switch state {
        case .unavailable:
            true
        case .idle, .noScript, .requestingPermission, .downloadingModel, .preparing, .listening, .denied:
            false
        }
    }

    func setScript(_ text: String) {
        guard text != scriptText else { return }
        scriptText = text
        if state == .noScript, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            state = .idle
        }
        aligner = ScriptAligner(tokens: ScriptTokenizer.tokenize(text))
        volatileWordCount = 0
        highlightedUTF16Length = 0
        confirmedWordCount = 0
        if isActive {
            stopListening()
        }
    }

    func setMicrophone(uid: String?) {
        guard uid != microphoneUID else { return }
        microphoneUID = uid
        if isActive {
            stopListening()
            setEnabled(true)
        }
    }

    func stopAndReset() {
        setEnabled(false)
        aligner.reset()
        volatileWordCount = 0
        highlightedUTF16Length = 0
        confirmedWordCount = 0
    }

    func setEnabled(_ enabled: Bool) {
        if enabled {
            guard !isActive else { return }
            guard !scriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                state = .noScript
                return
            }
            startTask = Task { await begin() }
        } else {
            cancelWatchdog()
            startTask?.cancel()
            startTask = nil
            stopListening()
        }
    }

    func retry() {
        guard canRetry else { return }
        state = .idle
        setEnabled(true)
    }

    func waitUntilSettled() async {
        await startTask?.value
    }

    private func begin() async {
        switch permission.status() {
        case .denied:
            state = .denied
            return
        case .undetermined:
            state = .requestingPermission
            guard await permission.request() else {
                state = .denied
                return
            }
        case .granted:
            break
        }

        state = .preparing
        let attempt = startWatchdog()
        let session = makeSession()
        do {
            try await session.start(
                deviceUID: microphoneUID,
                onPhase: { [weak self] phase in self?.handle(phase, attempt: attempt) },
                onUpdate: { [weak self] update in self?.handle(update) }
            )
            guard attempt == activationID else {
                session.stop()
                return
            }
            cancelWatchdog()
            self.session = session
            playback.startVoiceFollowing()
            state = .listening
        } catch {
            session.stop()
            guard attempt == activationID else { return }
            cancelWatchdog()
            state = .unavailable(Reason(error))
        }
    }

    /// Activation waits on the system installing a speech model, which has no guaranteed duration.
    /// The watchdog turns that open-ended wait into a stated failure the user can retry.
    private func startWatchdog() -> Int {
        activationID += 1
        let attempt = activationID
        let timeout = activationTimeout
        watchdog?.cancel()
        watchdog = Task { [weak self] in
            try? await Task.sleep(for: timeout)
            guard !Task.isCancelled else { return }
            self?.activationTimedOut(attempt: attempt)
        }
        return attempt
    }

    private func cancelWatchdog() {
        watchdog?.cancel()
        watchdog = nil
    }

    private func activationTimedOut(attempt: Int) {
        guard attempt == activationID, isActive else { return }
        activationID += 1
        watchdog = nil
        startTask?.cancel()
        session?.stop()
        session = nil
        state = .unavailable(.modelUnavailable)
    }

    private func handle(_ phase: VoiceTranscriptionSession.Phase, attempt: Int) {
        guard attempt == activationID else { return }
        switch phase {
        case let .installingModel(language):
            state = .downloadingModel(language: language)
        case .starting:
            state = .preparing
        }
    }

    private func stopListening() {
        session?.stop()
        session = nil
        if state == .listening {
            playback.stopVoiceFollowing()
        }
        state = .idle
    }

    private func handle(_ update: VoiceTranscriptionSession.Update) {
        let words = update.text.split(whereSeparator: \.isWhitespace).map(String.init)
        let stableCount = update.isFinal ? words.count : max(words.count - 1, 0)
        if stableCount > volatileWordCount {
            aligner.ingest(Array(words[volatileWordCount ..< stableCount]))
            playback.updateVoiceProgress(aligner.progress)
            confirmedWordCount = aligner.confirmedCount
            onWordCountChanged?(confirmedWordCount)
        }
        volatileWordCount = update.isFinal ? 0 : stableCount

        var end = aligner.confirmedEndIndex
        let inProgress = update.isFinal || words.count == stableCount ? nil : words.last
        if let inProgress, let speculative = aligner.speculativeEndIndex(ifNextWordIs: inProgress) {
            end = speculative
        }
        highlightedUTF16Length = end.map {
            scriptText.utf16.distance(from: scriptText.startIndex, to: $0)
        } ?? 0
    }
}
