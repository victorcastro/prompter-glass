import SwiftData
import SwiftUI

@main
struct PrompterGlassApp: App {
    private static let uiTestArgument = "-ui-testing"
    private static let uiTestResetArgument = "-ui-testing-reset"

    private let modelContainer: ModelContainer
    @State private var environment: AppEnvironment

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let isUITesting = arguments.contains(PrompterGlassApp.uiTestArgument)
        let shouldReset = arguments.contains(PrompterGlassApp.uiTestResetArgument)
        modelContainer = PrompterGlassApp.makeModelContainer(inMemory: isUITesting)
        let defaults = PrompterGlassApp.makeDefaults(isUITesting: isUITesting, reset: shouldReset)
        _environment = State(
            initialValue: AppEnvironment(preferences: OverlayPreferencesStore(defaults: defaults))
        )
    }

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environment(environment)
                .frame(minWidth: 720, minHeight: 520)
        }
        .modelContainer(modelContainer)
        .commands {
            CommandGroup(after: .toolbar) {
                Button("Show Overlay") {
                    environment.toggleOverlayVisibility()
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            }
        }
    }

    private static func makeModelContainer(inMemory: Bool) -> ModelContainer {
        let schema = Schema([Script.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    private static func makeDefaults(isUITesting: Bool, reset: Bool) -> UserDefaults {
        guard isUITesting else { return .standard }
        let suite = "dev.victorcastro.PrompterGlass.uitests"
        if reset {
            UserDefaults.standard.removePersistentDomain(forName: suite)
        }
        return UserDefaults(suiteName: suite) ?? .standard
    }
}
