import SwiftUI

struct ReaderOverlayView: View {
    let book: Book
    let currentPage: Int
    let totalPages: Int
    let onDismiss: () -> Void
    let onToggleMode: () -> Void
    let onOpenSettings: () -> Void

    @Environment(ThemeManager.self) private var theme

    var body: some View {
        VStack {
            topBar
            Spacer()
            bottomBar
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button(action: onDismiss) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Library")
                        .font(.system(size: 16))
                }
                .foregroundStyle(theme.currentTheme.textColor)
            }

            Spacer()

            Text(book.title)
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundStyle(theme.currentTheme.textColor)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: 180)

            Spacer()

            Button(action: onOpenSettings) {
                Image(systemName: "textformat")
                    .font(.system(size: 16))
                    .foregroundStyle(theme.currentTheme.textColor)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            theme.currentTheme.backgroundColor
                .opacity(0.95)
                .ignoresSafeArea(edges: .top)
        )
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.currentTheme.dividerColor)
                .frame(height: 0.5)
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            // Page info
            if totalPages > 0 {
                Text("\(currentPage + 1) / \(totalPages)")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(theme.currentTheme.secondaryTextColor)
            }

            Spacer()

            // Progress
            if totalPages > 0 {
                Text("\(Int(Double(currentPage) / Double(totalPages) * 100))%")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.currentTheme.secondaryTextColor)
            }

            Spacer()

            // Mode toggle
            Button(action: onToggleMode) {
                Image(systemName: book.readingMode == .page ? "scroll" : "book.pages")
                    .font(.system(size: 16))
                    .foregroundStyle(theme.currentTheme.textColor)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            theme.currentTheme.backgroundColor
                .opacity(0.95)
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(theme.currentTheme.dividerColor)
                .frame(height: 0.5)
        }
    }
}
