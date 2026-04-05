import SwiftUI
import SwiftData

@main
struct InkreadApp: App {
    @State private var themeManager   = ThemeManager()
    @State private var settingsManager = SettingsManager()
    @State private var spotlightBookId: UUID?

    var body: some Scene {
        WindowGroup {
            LibraryView(spotlightBookId: $spotlightBookId)
                .environment(themeManager)
                .environment(settingsManager)
        }
        .modelContainer(for: [Book.self, Highlight.self, Bookmark.self, PageAnnotation.self])
        .handlesExternalEvents(matching: Set(["*"]))
    }
}
