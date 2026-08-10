import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case prompter
    case library

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .prompter: "Prompter"
        case .library: "Library"
        }
    }

    var systemImage: String {
        switch self {
        case .prompter: "play.fill"
        case .library: "text.alignleft"
        }
    }

    var mood: Theme.Mood {
        switch self {
        case .prompter: .forest
        case .library: .purple
        }
    }
}
