@preconcurrency import AVFoundation
import Speech

@MainActor
final class VoiceTranscriptionSession {
    struct Update {
        let text: String
        let isFinal: Bool
    }

    enum SessionError: Error {
        case localeNotSupported
        case audioFormatUnavailable
    }

    private let audioEngine = AVAudioEngine()
    private var analyzer: SpeechAnalyzer?
    private var inputBuilder: AsyncStream<AnalyzerInput>.Continuation?
    private var resultsTask: Task<Void, Never>?

    static func resolveSupportedLocale() async -> Locale? {
        let supported = await SpeechTranscriber.supportedLocales
        let current = Locale.current
        NSLog(
            "PrompterGlass: current locale %@, supported: %@",
            current.identifier(.bcp47),
            supported.map { $0.identifier(.bcp47) }.joined(separator: ", ")
        )
        if let exact = supported.first(where: { $0.identifier(.bcp47) == current.identifier(.bcp47) }) {
            NSLog("PrompterGlass: using exact locale match %@", exact.identifier(.bcp47))
            return exact
        }
        let sameLanguage = supported.filter { $0.language.languageCode == current.language.languageCode }
        let preferred = Locale.preferredLanguages.map { Locale(identifier: $0).identifier(.bcp47) }
        let fallback = sameLanguage.first { preferred.contains($0.identifier(.bcp47)) }
            ?? sameLanguage.first { $0.region?.identifier == "US" }
            ?? sameLanguage.first
        NSLog(
            "PrompterGlass: language fallback -> %@",
            fallback.map { $0.identifier(.bcp47) } ?? "none"
        )
        return fallback
    }

    func start(onUpdate: @escaping @MainActor (Update) -> Void) async throws {
        guard let locale = await VoiceTranscriptionSession.resolveSupportedLocale() else {
            throw SessionError.localeNotSupported
        }

        let transcriber = SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [.volatileResults],
            attributeOptions: []
        )
        if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            NSLog("PrompterGlass: downloading on-device speech model…")
            try await request.downloadAndInstall()
            NSLog("PrompterGlass: speech model installed")
        } else {
            NSLog("PrompterGlass: speech model already installed")
        }

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        self.analyzer = analyzer
        guard let analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(
            compatibleWith: [transcriber]
        ) else {
            NSLog("PrompterGlass: no compatible analyzer audio format")
            throw SessionError.audioFormatUnavailable
        }
        NSLog("PrompterGlass: analyzer format %@", analyzerFormat.description)

        let (inputSequence, builder) = AsyncStream<AnalyzerInput>.makeStream()
        inputBuilder = builder

        resultsTask = Task {
            do {
                for try await result in transcriber.results {
                    let text = String(result.text.characters)
                    NSLog("PrompterGlass: transcript (%@) \"%@\"", result.isFinal ? "final" : "volatile", text)
                    onUpdate(Update(text: text, isFinal: result.isFinal))
                }
            } catch {
                NSLog("PrompterGlass: transcription stream ended (%@)", String(describing: error))
            }
        }

        try installTap(feeding: builder, format: analyzerFormat)
        try await analyzer.start(inputSequence: inputSequence)
        audioEngine.prepare()
        try audioEngine.start()
        NSLog("PrompterGlass: audio engine running, listening")
    }

    func stop() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        inputBuilder?.finish()
        inputBuilder = nil
        resultsTask?.cancel()
        resultsTask = nil
        let analyzer = analyzer
        self.analyzer = nil
        Task {
            try? await analyzer?.finalizeAndFinishThroughEndOfInput()
        }
    }

    private func installTap(
        feeding builder: AsyncStream<AnalyzerInput>.Continuation,
        format analyzerFormat: AVAudioFormat
    ) throws {
        let inputFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        let converter = AVAudioConverter(from: inputFormat, to: analyzerFormat)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { buffer, _ in
            guard let converted = VoiceTranscriptionSession.convert(
                buffer,
                using: converter,
                to: analyzerFormat
            ) else { return }
            builder.yield(AnalyzerInput(buffer: converted))
        }
    }

    private nonisolated static func convert(
        _ buffer: AVAudioPCMBuffer,
        using converter: AVAudioConverter?,
        to format: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        guard let converter else { return buffer }
        let ratio = format.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount((Double(buffer.frameLength) * ratio).rounded(.up)) + 16
        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else { return nil }
        var conversionError: NSError?
        var consumed = false
        converter.convert(to: output, error: &conversionError) { _, status in
            if consumed {
                status.pointee = .noDataNow
                return nil
            }
            consumed = true
            status.pointee = .haveData
            return buffer
        }
        return conversionError == nil ? output : nil
    }
}
