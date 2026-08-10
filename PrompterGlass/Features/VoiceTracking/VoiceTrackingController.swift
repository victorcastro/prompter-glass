import Foundation
import Observation

@MainActor
protocol VoiceTranscribing: AnyObject {
    func start(
        deviceUID: String?,
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
        case requestingPermission
        case preparing
        case listening
        case denied
        case unavailable
    }

    private(set) var state: State = .idle
    private(set) var highlightedUTF16Length = 0

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

    init(
        playback: ScrollPlaybackController,
        permission: MicrophonePermissionClient,
        makeSession: @escaping @MainActor () -> VoiceTranscribing
    ) {
        self.playback = playback
        self.permission = permission
        self.makeSession = makeSession
    }

    var isActive: Bool {
        switch state {
        case .requestingPermission, .preparing, .listening:
            true
        case .idle, .denied, .unavailable:
            false
        }
    }

    func setScript(_ text: String) {
        guard text != scriptText else { return }
        scriptText = text
        aligner = ScriptAligner(tokens: ScriptTokenizer.tokenize(text))
        volatileWordCount = 0
        highlightedUTF16Length = 0
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
    }

    func setEnabled(_ enabled: Bool) {
        if enabled {
            guard !isActive else { return }
            startTask = Task { await begin() }
        } else {
            startTask?.cancel()
            startTask = nil
            stopListening()
        }
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
        let session = makeSession()
        do {
            try await session.start(deviceUID: microphoneUID) { [weak self] update in
                self?.handle(update)
            }
            self.session = session
            playback.startVoiceFollowing()
            state = .listening
        } catch {
            session.stop()
            state = .unavailable
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
