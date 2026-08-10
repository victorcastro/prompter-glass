import SwiftUI

struct ScriptCardView: View {
    let script: Script
    let isActive: Bool
    let onSelect: () -> Void
    let onOpen: () -> Void
    let onDelete: () -> Void

    var body: some View {
        GlassCard(isHighlighted: isActive) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    selector
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

    private var selector: some View {
        Button(action: onSelect) {
            ZStack {
                if isActive {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.Palette.accentIrisSoft, Theme.Palette.accentIris],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Circle()
                        .strokeBorder(Color.white.opacity(0.35), lineWidth: 1.5)
                        .background(Circle().fill(Color.white.opacity(0.06)))
                }
            }
            .frame(width: 26, height: 26)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(ScriptLibraryView.Identifier.select)
        .help(isActive ? "Active script" : "Send this script to the prompter")
    }
}
