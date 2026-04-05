import UIKit

@MainActor
enum HapticManager {
    static func pageTurn() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    static func bookmarkToggle() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func highlight() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
