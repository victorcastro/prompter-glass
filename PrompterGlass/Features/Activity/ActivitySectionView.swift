import AppKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ActivitySectionView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \PromptSession.startedAt, order: .reverse)
    private var sessions: [PromptSession]

    @State private var isConfirmingClear = false

    var body: some View {
        let metrics = ActivityMetrics(sessions: sessions.map(\.metricsSession), now: Date())

        return ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                if metrics.isEmpty {
                    emptyState
                } else {
                    cards(metrics)
                    clearButton
                }
            }
            .padding(28)
        }
        .confirmationDialog(
            "Clear all activity data?",
            isPresented: $isConfirmingClear,
            titleVisibility: .visible
        ) {
            Button("Clear everything", role: .destructive, action: clearAll)
                .accessibilityIdentifier(Identifier.confirmClear)
            Button("Cancel", role: .cancel) { isConfirmingClear = false }
                .accessibilityIdentifier(Identifier.cancelClear)
        } message: {
            Text("Every recorded session will be permanently deleted.")
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("My activity")
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(Theme.Palette.textPrimary)
            Spacer()
            Text("Last 30 days")
                .font(.system(size: 12))
                .foregroundStyle(Theme.Palette.textTertiary)
        }
    }

    private func cards(_ metrics: ActivityMetrics) -> some View {
        HStack(alignment: .top, spacing: 16) {
            paceCard(metrics)
            timeOnAirCard(metrics)
            retakesCard(metrics)
        }
    }

    private func paceCard(_ metrics: ActivityMetrics) -> some View {
        statCard(title: "Delivery pace", identifier: Identifier.pace) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(metrics.averageWordsPerMinute.map(String.init) ?? "—")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(Theme.Palette.accentIris)
                Text("wpm average")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
            paceChart(metrics.paceBars)
        }
    }

    private func paceChart(_ bars: [ActivityMetrics.PaceBar]) -> some View {
        let peak = max(bars.map(\.wordsPerMinute).max() ?? 1, 1)
        return HStack(alignment: .bottom, spacing: 6) {
            ForEach(bars) { bar in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(bar.isRecent ? Theme.Palette.accentIris : Color.white.opacity(0.25))
                    .frame(width: 18, height: max(10, 64 * bar.wordsPerMinute / peak))
            }
        }
        .frame(height: 72, alignment: .bottom)
    }

    private func timeOnAirCard(_ metrics: ActivityMetrics) -> some View {
        statCard(title: "Time on air", identifier: Identifier.timeOnAir) {
            Text(ActivityMetrics.timeLabel(seconds: metrics.timeOnAirSeconds))
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(Theme.Palette.textPrimary)
            if let delta = metrics.deltaSeconds {
                Text("\(delta >= 0 ? "▲" : "▼") \(ActivityMetrics.timeLabel(seconds: abs(delta))) vs last month")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.Palette.accentIrisSoft)
            }
            VStack(spacing: 6) {
                ForEach(metrics.topScripts) { script in
                    HStack {
                        Text(script.title)
                            .lineLimit(1)
                        Spacer()
                        Text(ActivityMetrics.timeLabel(seconds: script.seconds))
                            .monospacedDigit()
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Palette.textSecondary)
                }
            }
            .padding(.top, 6)
        }
    }

    private func retakesCard(_ metrics: ActivityMetrics) -> some View {
        statCard(title: "Retakes avoided", identifier: Identifier.retakes) {
            Text(String(metrics.retakesAvoided))
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(Theme.Palette.textPrimary)
            Text("Sessions finished without stopping the scroll.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.Palette.textSecondary)
            Button("Export report", action: exportReport)
                .buttonStyle(.bordered)
                .tint(.white)
                .accessibilityIdentifier(Identifier.export)
                .padding(.top, 4)
        }
    }

    private func statCard(
        title: String,
        identifier: String,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Palette.textSecondary)
                content()
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
        }
        .accessibilityIdentifier(identifier)
    }

    private var emptyState: some View {
        GlassCard {
            VStack(spacing: 10) {
                IconChip(systemImage: "clock", style: .irisGradient, side: 40)
                Text("No activity yet")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.Palette.textPrimary)
                Text("Roll a script in the Prompter and your sessions will show up here.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Palette.textSecondary)
            }
            .padding(32)
            .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier(Identifier.emptyState)
    }

    private var clearButton: some View {
        Button("Clear activity data", role: .destructive) {
            isConfirmingClear = true
        }
        .buttonStyle(.plain)
        .font(.system(size: 11))
        .foregroundStyle(Theme.Palette.textTertiary)
        .accessibilityIdentifier(Identifier.clear)
    }

    private func exportReport() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "prompter-activity.csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let csv = ActivityCSV.render(sessions: sessions.map(\.metricsSession))
        try? csv.write(to: url, atomically: true, encoding: .utf8)
    }

    private func clearAll() {
        for session in sessions {
            modelContext.delete(session)
        }
        isConfirmingClear = false
    }
}

extension ActivitySectionView {
    enum Identifier {
        static let pace = "activity.pace"
        static let timeOnAir = "activity.timeOnAir"
        static let retakes = "activity.retakes"
        static let export = "activity.export"
        static let clear = "activity.clear"
        static let confirmClear = "activity.confirmClear"
        static let cancelClear = "activity.cancelClear"
        static let emptyState = "activity.emptyState"
    }
}
