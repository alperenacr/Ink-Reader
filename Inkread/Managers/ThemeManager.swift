import SwiftUI

@Observable
@MainActor
final class ThemeManager {
    var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "inkread.theme")
        }
    }

    init() {
        if let saved = UserDefaults.standard.string(forKey: "inkread.theme"),
           let theme = AppTheme(rawValue: saved) {
            currentTheme = theme
        } else {
            currentTheme = .eink
        }
    }
}
