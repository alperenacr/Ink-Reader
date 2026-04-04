import SwiftUI
import SwiftData

@main
struct InkreadApp: App {
    @State private var themeManager = ThemeManager()
    @State private var settingsManager = SettingsManager()

    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environment(themeManager)
                .environment(settingsManager)
        }
        .modelContainer(for: Book.self)
    }
}
