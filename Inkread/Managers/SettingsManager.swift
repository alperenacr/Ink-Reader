import SwiftUI

enum ReadingFont: String, CaseIterable, Identifiable {
    case serif    = "Serif"
    case sansSerif = "Sans-Serif"

    var id: String { rawValue }

    func font(size: CGFloat) -> Font {
        switch self {
        case .serif:     return .system(size: size, design: .serif)
        case .sansSerif: return .system(size: size, design: .default)
        }
    }
}

enum LineSpacing: String, CaseIterable, Identifiable {
    case compact  = "Compact"
    case normal   = "Normal"
    case relaxed  = "Relaxed"
    case spacious = "Spacious"

    var id: String { rawValue }

    var value: CGFloat {
        switch self {
        case .compact:  return 2
        case .normal:   return 6
        case .relaxed:  return 12
        case .spacious: return 18
        }
    }
}

@Observable
@MainActor
final class SettingsManager {
    var fontSize: CGFloat {
        didSet { UserDefaults.standard.set(Double(fontSize), forKey: "inkread.fontSize") }
    }

    var readingFont: ReadingFont {
        didSet { UserDefaults.standard.set(readingFont.rawValue, forKey: "inkread.font") }
    }

    var lineSpacing: LineSpacing {
        didSet { UserDefaults.standard.set(lineSpacing.rawValue, forKey: "inkread.lineSpacing") }
    }

    init() {
        let savedSize = UserDefaults.standard.double(forKey: "inkread.fontSize")
        fontSize = savedSize > 0 ? CGFloat(savedSize) : 18

        if let raw = UserDefaults.standard.string(forKey: "inkread.font"),
           let font = ReadingFont(rawValue: raw) {
            readingFont = font
        } else {
            readingFont = .serif
        }

        if let raw = UserDefaults.standard.string(forKey: "inkread.lineSpacing"),
           let spacing = LineSpacing(rawValue: raw) {
            lineSpacing = spacing
        } else {
            lineSpacing = .normal
        }
    }
}
