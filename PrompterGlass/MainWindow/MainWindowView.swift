import SwiftData
import SwiftUI

struct MainWindowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppEnvironment.self) private var environment

    @Query(sort: \Script.updatedAt, order: .reverse)
    private var scripts: [Script]

    @State private var selectedScriptID: Script.ID?

    var body: some View {
        NavigationSplitView {
            ScriptLibraryView(
                scripts: scripts,
                selection: $selectedScriptID,
                onCreate: createScript,
                onDelete: delete
            )
            .navigationSplitViewColumnWidth(min: 220, ideal: 260)
        } detail: {
            detail
        }
        .task { restoreSelection() }
        .onChange(of: selectedScriptID) { _, _ in environment.selectScript(selectedScript) }
        .onChange(of: scripts) { _, _ in reconcileSelection() }
    }

    private var detail: some View {
        VStack(spacing: 0) {
            if let script = selectedScript {
                ScriptEditorView(script: script, onCommit: environment.refreshPlaybackAvailability)
                    .id(script.id)
            } else {
                ContentUnavailableView(
                    "No script selected",
                    systemImage: "text.alignleft",
                    description: Text("Pick a script from the library, or create one.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Divider()

            ControlPanelView()
        }
    }

    private var selectedScript: Script? {
        guard let selectedScriptID else { return nil }
        return scripts.first { $0.id == selectedScriptID }
    }

    private func restoreSelection() {
        selectedScriptID = environment.activeScript.restorableIdentifier(among: scripts)
        environment.selectScript(selectedScript)
    }

    private func reconcileSelection() {
        if let selectedScriptID, !scripts.contains(where: { $0.id == selectedScriptID }) {
            self.selectedScriptID = nil
            environment.clearActiveScript()
            return
        }
        environment.selectScript(selectedScript)
    }

    private func createScript() {
        let script = Script()
        modelContext.insert(script)
        selectedScriptID = script.id
    }

    private func delete(_ script: Script) {
        let wasActive = environment.activeScript.script?.id == script.id
        if selectedScriptID == script.id { selectedScriptID = nil }
        modelContext.delete(script)
        if wasActive { environment.clearActiveScript() }
    }
}

#Preview {
    let preferences = OverlayPreferencesStore(defaults: UserDefaults(suiteName: "preview") ?? .standard)
    return MainWindowView()
        .environment(AppEnvironment(preferences: preferences))
        .modelContainer(for: Script.self, inMemory: true)
}
