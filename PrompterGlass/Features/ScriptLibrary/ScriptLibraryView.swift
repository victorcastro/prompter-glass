import SwiftUI

struct ScriptLibraryView: View {
    let scripts: [Script]
    @Binding var selection: Script.ID?
    @Binding var editingScriptID: Script.ID?
    let onCreate: () -> Void
    let onDelete: (Script) -> Void

    @Environment(AppEnvironment.self) private var environment

    @State private var scriptPendingDeletion: Script?

    var body: some View {
        Group {
            if let editingScript {
                editor(for: editingScript)
            } else if scripts.isEmpty {
                emptyState
            } else {
                grid
            }
        }
        .confirmationDialog(
            "Delete this script?",
            isPresented: deletionBinding,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let script = scriptPendingDeletion {
                    onDelete(script)
                }
                scriptPendingDeletion = nil
            }
            .accessibilityIdentifier(Identifier.confirmDelete)

            Button("Cancel", role: .cancel) {
                scriptPendingDeletion = nil
            }
            .accessibilityIdentifier(Identifier.cancelDelete)
        } message: {
            Text("“\(scriptPendingDeletion?.title ?? "")” will be permanently deleted.")
        }
    }

    private var grid: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 240, maximum: 340), spacing: 16)],
                    alignment: .leading,
                    spacing: 16
                ) {
                    ForEach(scripts) { script in
                        ScriptCardView(
                            script: script,
                            isActive: script.id == selection,
                            onOpen: { open(script) },
                            onDelete: { scriptPendingDeletion = script }
                        )
                    }
                }
                .accessibilityIdentifier(Identifier.list)
            }
            .padding(28)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Library")
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(Theme.Palette.textPrimary)
            Spacer()
            Button(action: onCreate) {
                Text("+ New script")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.Palette.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(Theme.Glass.stroke, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(Identifier.create)
            .help("Create a new script")
        }
    }

    private func editor(for script: Script) -> some View {
        ScriptEditorView(
            script: script,
            onCommit: environment.refreshPlaybackAvailability,
            onBack: { editingScriptID = nil },
            onDelete: { scriptPendingDeletion = script }
        )
        .id(script.id)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            IconChip(systemImage: "text.badge.plus", style: .irisGradient, side: 44)
            Text("No scripts yet")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.Palette.textPrimary)
            Text("Write your first script and float it over any app.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.Palette.textSecondary)
            Button("Create your first script", action: onCreate)
                .buttonStyle(.borderedProminent)
                .tint(Theme.Palette.accentIris)
                .accessibilityIdentifier(Identifier.createFirst)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var editingScript: Script? {
        guard let editingScriptID else { return nil }
        return scripts.first { $0.id == editingScriptID }
    }

    private func open(_ script: Script) {
        selection = script.id
        editingScriptID = script.id
    }

    private var deletionBinding: Binding<Bool> {
        Binding(
            get: { scriptPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    scriptPendingDeletion = nil
                }
            }
        )
    }
}

extension ScriptLibraryView {
    enum Identifier {
        static let list = "library.list"
        static let create = "library.create"
        static let delete = "library.delete"
        static let createFirst = "library.createFirst"
        static let confirmDelete = "library.confirmDelete"
        static let cancelDelete = "library.cancelDelete"
        static let rowTitle = "library.rowTitle"
        static let rowDate = "library.rowDate"
        static let back = "library.back"
    }
}
