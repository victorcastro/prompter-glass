import SwiftUI

struct SidebarView: View {
    @Environment(AppEnvironment.self) private var environment

    @Binding var section: AppSection

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(AppSection.allCases) { item in
                sectionButton(for: item)
            }
            Spacer()
            overlayCard
        }
        .padding(.horizontal, 12)
        .padding(.top, 48)
        .padding(.bottom, 12)
        .frame(width: 232)
        .frame(maxHeight: .infinity)
        .background(Theme.Palette.sidebarBase.opacity(0.92))
    }

    private func sectionButton(for item: AppSection) -> some View {
        let isActive = item == section
        return Button {
            section = item
        } label: {
            HStack(spacing: 10) {
                IconChip(
                    systemImage: item.systemImage,
                    style: isActive ? .irisGradient : .neutral,
                    side: 26
                )
                Text(item.title)
                    .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(isActive ? Theme.Palette.textPrimary : Theme.Palette.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(isActive ? Color.white.opacity(0.10) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("sidebar.\(item.rawValue)")
    }

    private var overlayCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Overlay visible")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.Palette.textPrimary)
                Text("Floats over every app · ⇧⌘O")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Palette.textTertiary)
                Toggle("Overlay", isOn: overlayVisibility)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
                    .tint(Theme.Palette.accentIris)
                    .accessibilityIdentifier(ControlIdentifier.overlayToggle)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var overlayVisibility: Binding<Bool> {
        Binding(
            get: { environment.overlay.isVisible },
            set: { environment.setOverlayVisible($0) }
        )
    }
}
