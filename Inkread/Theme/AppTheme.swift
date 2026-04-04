import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case eink  = "E-Ink"
    case sepia = "Sepia"
    case white = "White"
    case dark  = "Dark"

    var id: String { rawValue }

    var backgroundColor: Color {
        switch self {
        case .eink:  return Color(red: 0.93, green: 0.93, blue: 0.91)
        case .sepia: return Color(red: 0.96, green: 0.92, blue: 0.83)
        case .white: return Color(white: 1.0)
        case .dark:  return Color(red: 0.09, green: 0.09, blue: 0.09)
        }
    }

    var textColor: Color {
        switch self {
        case .eink:  return Color(red: 0.10, green: 0.10, blue: 0.10)
        case .sepia: return Color(red: 0.22, green: 0.15, blue: 0.05)
        case .white: return Color(red: 0.08, green: 0.08, blue: 0.08)
        case .dark:  return Color(red: 0.88, green: 0.88, blue: 0.86)
        }
    }

    var secondaryTextColor: Color {
        switch self {
        case .eink:  return Color(red: 0.45, green: 0.45, blue: 0.43)
        case .sepia: return Color(red: 0.50, green: 0.40, blue: 0.25)
        case .white: return Color(red: 0.45, green: 0.45, blue: 0.45)
        case .dark:  return Color(red: 0.55, green: 0.55, blue: 0.53)
        }
    }

    var cardColor: Color {
        switch self {
        case .eink:  return Color(red: 0.97, green: 0.97, blue: 0.95)
        case .sepia: return Color(red: 0.98, green: 0.95, blue: 0.88)
        case .white: return Color(red: 0.96, green: 0.96, blue: 0.96)
        case .dark:  return Color(red: 0.15, green: 0.15, blue: 0.15)
        }
    }

    var dividerColor: Color {
        switch self {
        case .eink:  return Color(red: 0.80, green: 0.80, blue: 0.78)
        case .sepia: return Color(red: 0.82, green: 0.76, blue: 0.65)
        case .white: return Color(red: 0.85, green: 0.85, blue: 0.85)
        case .dark:  return Color(red: 0.25, green: 0.25, blue: 0.25)
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .dark: return .dark
        default:    return .light
        }
    }

    var iconName: String {
        switch self {
        case .eink:  return "rays"
        case .sepia: return "cup.and.saucer.fill"
        case .white: return "circle.fill"
        case .dark:  return "moon.fill"
        }
    }
}
