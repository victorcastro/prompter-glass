import SwiftUI

struct ScriptLibraryView: View {
    let scripts: [Script]
    @Binding var selection: Script.ID?
    let onCreate: () -> Void
    let onDelete: (Script) -> Void

    @State private var scriptPendingDeletion: Script?

    var body: some View {
        Group {
            if scripts.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .toolbar {
            ToolbarItem {
                Button(action: onCreate) {
                    Label("New Script", systemImage: "plus")
                }
                .accessibilityIdentifier(Identifier.create)
                .help("Create a new script")
            }
            ToolbarItem {
                Button(role: .destructive) {
                    scriptPendingDeletion = selectedScript
                } label: {
                    Label("Delete Script", systemImage: "trash")
                }
                .accessibilityIdentifier(Identifier.delete)
                .help("Delete the selected script")
                .disabled(selectedScript == nil)
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

    private var list: some View {
        List(selection: $selection) {
            ForEach(scripts) { script in
                row(for: script)
                    .tag(script.id)
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            scriptPendingDeletion = script
                        }
                    }
            }
        }
        .accessibilityIdentifier(Identifier.list)
    }

    private func row(for script: Script) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(script.title)
                .font(.body)
                .lineLimit(1)
                .accessibilityIdentifier(Identifier.row(script.title))
            Text(script.updatedAt, format: .relative(presentation: .named))
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier(Identifier.rowDate(script.title))
        }
        .padding(.vertical, 2)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No scripts yet", systemImage: "text.badge.plus")
        } description: {
            Text("Write your first script and float it over any app.")
        } actions: {
            Button("Create your first script", action: onCreate)
                .accessibilityIdentifier(Identifier.createFirst)
        }
    }

    private var selectedScript: Script? {
        guard let selection else { return nil }
        return scripts.first { $0.id == selection }
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

        static func row(_ title: String) -> String {
            "library.row.\(title)"
        }

        static func rowDate(_ title: String) -> String {
            "library.rowDate.\(title)"
        }
    }
}
