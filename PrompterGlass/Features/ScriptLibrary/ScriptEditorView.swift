import SwiftUI

struct ScriptEditorView: View {
    let script: Script
    let onCommit: () -> Void
    var onBack: (() -> Void)?
    var onDelete: (() -> Void)?

    @State private var title: String = ""
    @State private var bodyText: String = ""
    @State private var saveTask: Task<Void, Never>?

    @FocusState private var focusedField: Field?

    private static let autosaveDelay = Duration.milliseconds(400)

    enum Field {
        case title
        case body
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            toolbar

            GlassCard {
                VStack(alignment: .leading, spacing: 0) {
                    TextField("Title", text: $title)
                        .textFieldStyle(.plain)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.Palette.textPrimary)
                        .focused($focusedField, equals: .title)
                        .accessibilityIdentifier(Identifier.title)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 12)

                    Rectangle()
                        .fill(Theme.Glass.stroke)
                        .frame(height: 1)

                    TextEditor(text: $bodyText)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(Theme.Palette.textPrimary)
                        .scrollContentBackground(.hidden)
                        .focused($focusedField, equals: .body)
                        .accessibilityIdentifier(Identifier.body)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task {
            title = script.title
            bodyText = script.body
            if script.title == Script.defaultTitle, script.body.isEmpty {
                focusedField = .title
            }
        }
        .onChange(of: title) { _, _ in scheduleSave() }
        .onChange(of: bodyText) { _, _ in scheduleSave() }
        .onDisappear {
            saveTask?.cancel()
            commit()
        }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            if let onBack {
                Button {
                    commit()
                    onBack()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .bold))
                        Text("Library")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Theme.Palette.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(ScriptLibraryView.Identifier.back)
            }
            Spacer()
            if let onDelete {
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Palette.textSecondary)
                        .padding(8)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(ScriptLibraryView.Identifier.delete)
                .help("Delete this script")
            }
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: ScriptEditorView.autosaveDelay)
            guard !Task.isCancelled else { return }
            commit()
        }
    }

    private func commit() {
        guard script.canReceiveEdits else { return }
        script.apply(title: title, body: bodyText)
        onCommit()
    }
}

extension ScriptEditorView {
    enum Identifier {
        static let title = "editor.title"
        static let body = "editor.body"
    }
}
