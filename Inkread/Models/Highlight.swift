import SwiftUI
import SwiftData

@Model
final class Highlight {
    var id: UUID
    var bookId: UUID
    var startOffset: Int
    var endOffset: Int
    var colorName: String
    var note: String
    var snippet: String
    var createdAt: Date

    init(bookId: UUID, startOffset: Int, endOffset: Int, color: HighlightColor, snippet: String) {
        self.id          = UUID()
        self.bookId      = bookId
        self.startOffset = startOffset
        self.endOffset   = endOffset
        self.colorName   = color.rawValue
        self.note        = ""
        self.snippet     = snippet
        self.createdAt   = Date()
    }

    var color: HighlightColor {
        HighlightColor(rawValue: colorName) ?? .yellow
    }
}

enum HighlightColor: String, CaseIterable, Identifiable, Codable {
    case yellow, green, blue, pink

    var id: String { rawValue }

    var uiColor: UIColor {
        switch self {
        case .yellow: return UIColor.systemYellow.withAlphaComponent(0.45)
        case .green:  return UIColor.systemGreen.withAlphaComponent(0.40)
        case .blue:   return UIColor.systemBlue.withAlphaComponent(0.35)
        case .pink:   return UIColor.systemPink.withAlphaComponent(0.40)
        }
    }

    var swiftUIColor: Color {
        switch self {
        case .yellow: return .yellow.opacity(0.55)
        case .green:  return .green.opacity(0.45)
        case .blue:   return .blue.opacity(0.40)
        case .pink:   return .pink.opacity(0.45)
        }
    }
}

// Lightweight Sendable representation passed to UI layer
struct HighlightRange: Sendable {
    let startOffset: Int
    let endOffset: Int
    let color: HighlightColor
}
