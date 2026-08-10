import SwiftData
import SwiftUI

struct MainWindowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppEnvironment.self) private var environment

    @Query(sort: \Script.updatedAt, order: .reverse)
    private var scripts: [Script]

    @AppStorage("main.section")
    private var storedSection = AppSection.prompter.rawValue

    @State private var selectedScriptID: Script.ID?
    @State private var editingScriptID: Script.ID?

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(section: sectionBinding)
            sectionContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(MoodBackground(mood: section.mood))
        .preferredColorScheme(.dark)
        .task { restoreSelection() }
        .onChange(of: selectedScriptID) { _, _ in environment.selectScript(selectedScript) }
        .onChange(of: scripts) { _, _ in reconcileSelection() }
    }

    private var section: AppSection {
        AppSection(rawValue: storedSection) ?? .prompter
    }

    private var sectionBinding: Binding<AppSection> {
        Binding(
            get: { section },
            set: { storedSection = $0.rawValue }
        )
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch section {
        case .prompter:
            PrompterSectionView(onOpenLibrary: { storedSection = AppSection.library.rawValue })
        case .library:
            ScriptLibraryView(
                scripts: scripts,
                selection: $selectedScriptID,
                editingScriptID: $editingScriptID,
                onCreate: createScript,
                onDelete: delete
            )
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
        if let editingScriptID, !scripts.contains(where: { $0.id == editingScriptID }) {
            self.editingScriptID = nil
        }
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
        editingScriptID = script.id
    }

    private func delete(_ script: Script) {
        let wasActive = environment.activeScript.script?.id == script.id
        if selectedScriptID == script.id {
            selectedScriptID = nil
        }
        if editingScriptID == script.id {
            editingScriptID = nil
        }
        modelContext.delete(script)
        if wasActive {
            environment.clearActiveScript()
        }
    }
}

#Preview {
    let preferences = OverlayPreferencesStore(defaults: UserDefaults(suiteName: "preview") ?? .standard)
    return MainWindowView()
        .environment(AppEnvironment(preferences: preferences))
        .modelContainer(for: Script.self, inMemory: true)
}
