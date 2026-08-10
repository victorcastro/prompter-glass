import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case prompter
    case library
    case activity

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .prompter: "Prompter"
        case .library: "Library"
        case .activity: "My activity"
        }
    }

    var systemImage: String {
        switch self {
        case .prompter: "play.fill"
        case .library: "text.alignleft"
        case .activity: "clock"
        }
    }

    var mood: Theme.Mood {
        switch self {
        case .prompter: .forest
        case .library: .purple
        case .activity: .slate
        }
    }
}
