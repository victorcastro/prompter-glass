import SwiftUI

struct ScriptEditorView: View {
    let script: Script
    let onCommit: () -> Void

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
        VStack(alignment: .leading, spacing: 0) {
            TextField("Title", text: $title)
                .textFieldStyle(.plain)
                .font(.title2.weight(.semibold))
                .focused($focusedField, equals: .title)
                .accessibilityIdentifier(Identifier.title)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Divider()

            TextEditor(text: $bodyText)
                .font(.system(size: 14, design: .monospaced))
                .scrollContentBackground(.hidden)
                .focused($focusedField, equals: .body)
                .accessibilityIdentifier(Identifier.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
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
