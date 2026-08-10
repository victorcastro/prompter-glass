enum AccessibilityIdentifier {
    enum Sidebar {
        static let prompter = "sidebar.prompter"
        static let library = "sidebar.library"
        static let activity = "sidebar.activity"
    }

    enum Activity {
        static let pace = "activity.pace"
        static let timeOnAir = "activity.timeOnAir"
        static let retakes = "activity.retakes"
        static let export = "activity.export"
        static let clear = "activity.clear"
        static let confirmClear = "activity.confirmClear"
        static let cancelClear = "activity.cancelClear"
        static let emptyState = "activity.emptyState"
    }

    enum Library {
        static let list = "library.list"
        static let create = "library.create"
        static let createFirst = "library.createFirst"
        static let delete = "library.delete"
        static let confirmDelete = "library.confirmDelete"
        static let cancelDelete = "library.cancelDelete"
        static let rowTitle = "library.rowTitle"
        static let rowDate = "library.rowDate"
        static let back = "library.back"
    }

    enum Editor {
        static let title = "editor.title"
        static let body = "editor.body"
    }

    enum Controls {
        static let play = "controls.play"
        static let pause = "controls.pause"
        static let stop = "controls.stop"
        static let overlayToggle = "controls.overlayToggle"
        static let clickThroughToggle = "controls.clickThroughToggle"
        static let voiceToggle = "controls.voiceToggle"
        static let voicePreparing = "controls.voicePreparing"
        static let voiceDenied = "controls.voiceDenied"
        static let voiceUnavailable = "controls.voiceUnavailable"
        static let speed = "controls.speed"
        static let fontSize = "controls.fontSize"
        static let opacity = "controls.opacity"
        static let textColor = "controls.textColor"
        static let overlayWidth = "controls.overlayWidth"
        static let overlayHeight = "controls.overlayHeight"
    }

    enum Overlay {
        static let root = "overlay.root"
    }
}
