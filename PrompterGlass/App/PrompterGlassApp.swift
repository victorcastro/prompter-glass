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
        modelContainer = ModelContainerFactory.make(inMemory: isUITesting)
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

    private static func makeDefaults(isUITesting: Bool, reset: Bool) -> UserDefaults {
        guard isUITesting else { return .standard }
        let suite = "dev.victorcastro.PrompterGlass.uitests"
        if reset {
            UserDefaults.standard.removePersistentDomain(forName: suite)
        }
        return UserDefaults(suiteName: suite) ?? .standard
    }
}
