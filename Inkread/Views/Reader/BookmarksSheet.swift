import SwiftUI
import SwiftData

struct BookmarksSheet: View {
    let bookId: UUID
    let onSelect: (Int) -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var theme
    @Query private var allBookmarks: [Bookmark]

    private var bookmarks: [Bookmark] {
        allBookmarks
            .filter { $0.bookId == bookId }
            .sorted { $0.pageIndex < $1.pageIndex }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.currentTheme.backgroundColor.ignoresSafeArea()

                if bookmarks.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 44, weight: .thin))
                            .foregroundStyle(theme.currentTheme.secondaryTextColor.opacity(0.4))
                        Text("No bookmarks yet")
                            .font(.system(size: 16, design: .serif))
                            .foregroundStyle(theme.currentTheme.secondaryTextColor)
                    }
                } else {
                    List {
                        ForEach(bookmarks) { bookmark in
                            Button {
                                onSelect(bookmark.pageIndex)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Page \(bookmark.pageIndex + 1)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(theme.currentTheme.secondaryTextColor)

                                    Text(bookmark.snippet)
                                        .font(.system(size: 14, design: .serif))
                                        .foregroundStyle(theme.currentTheme.textColor)
                                        .lineLimit(2)
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(theme.currentTheme.backgroundColor)
                            .listRowSeparatorTint(theme.currentTheme.dividerColor)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    modelContext.delete(bookmark)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.currentTheme.backgroundColor, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(theme.currentTheme.textColor)
                }
            }
        }
        .preferredColorScheme(theme.currentTheme.colorScheme)
    }
}
