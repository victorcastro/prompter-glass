import SwiftUI

struct ScriptCardView: View {
    let script: Script
    let isActive: Bool
    let onOpen: () -> Void
    let onDelete: () -> Void

    var body: some View {
        GlassCard(isHighlighted: isActive) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    IconChip(systemImage: "doc.text", style: .irisGradient)
                    Spacer()
                    Text(script.updatedAt, format: .relative(presentation: .named))
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.Palette.textTertiary)
                        .accessibilityIdentifier(ScriptLibraryView.Identifier.rowDate)
                }
                Text(script.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.Palette.textPrimary)
                    .lineLimit(1)
                    .accessibilityIdentifier(ScriptLibraryView.Identifier.rowTitle)
                Text(script.body)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Palette.textSecondary)
                    .lineLimit(2, reservesSpace: true)
                Spacer(minLength: 4)
                Text(ScriptMetrics.cardSummary(wordCount: ScriptMetrics.wordCount(of: script.body)))
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Palette.textTertiary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(RoundedRectangle(cornerRadius: Theme.Glass.cornerRadius, style: .continuous))
        .onTapGesture(perform: onOpen)
        .contextMenu {
            Button("Delete", role: .destructive, action: onDelete)
        }
    }
}
