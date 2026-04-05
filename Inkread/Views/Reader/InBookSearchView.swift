import SwiftUI

struct SearchResult: Identifiable {
    let id       = UUID()
    let pageIndex: Int
    let context: String
    let matchRange: NSRange
}

struct InBookSearchView: View {
    let fullText: NSAttributedString
    let pages: [TextPage]
    let onSelect: (Int) -> Void

    @Environment(\.dismiss)       private var dismiss
    @Environment(ThemeManager.self) private var theme

    @State private var query   = ""
    @State private var results: [SearchResult] = []
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            ZStack {
                theme.currentTheme.backgroundColor.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(theme.currentTheme.secondaryTextColor)

                        TextField("Search in book…", text: $query)
                            .font(.system(size: 16))
                            .foregroundStyle(theme.currentTheme.textColor)
                            .autocorrectionDisabled()

                        if !query.isEmpty {
                            Button { query = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(theme.currentTheme.secondaryTextColor)
                            }
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(theme.currentTheme.cardColor)
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    Rectangle()
                        .fill(theme.currentTheme.dividerColor)
                        .frame(height: 0.5)

                    if isSearching {
                        ProgressView()
                            .padding(.top, 40)
                            .tint(theme.currentTheme.textColor)
                        Spacer()
                    } else if query.isEmpty {
                        emptyPrompt
                    } else if results.isEmpty {
                        noResults
                    } else {
                        resultsList
                    }
                }
            }
            .navigationTitle("Search")
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
        .onChange(of: query) { performSearch() }
    }

    // MARK: - States

    private var emptyPrompt: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(theme.currentTheme.secondaryTextColor.opacity(0.4))
            Text("Search within this book")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(theme.currentTheme.secondaryTextColor)
            Spacer()
            Spacer()
        }
    }

    private var noResults: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("No results for "\(query)"")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(theme.currentTheme.secondaryTextColor)
            Spacer()
            Spacer()
        }
    }

    private var resultsList: some View {
        List(results) { result in
            Button {
                onSelect(result.pageIndex)
                dismiss()
            } label: {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Page \(result.pageIndex + 1)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(theme.currentTheme.secondaryTextColor)

                    Text(result.context)
                        .font(.system(size: 14, design: .serif))
                        .foregroundStyle(theme.currentTheme.textColor)
                        .lineLimit(3)
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(theme.currentTheme.backgroundColor)
            .listRowSeparatorTint(theme.currentTheme.dividerColor)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .overlay(alignment: .top) {
            Text("\(results.count) result\(results.count == 1 ? "" : "s")")
                .font(.system(size: 12))
                .foregroundStyle(theme.currentTheme.secondaryTextColor)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(theme.currentTheme.backgroundColor)
        }
    }

    // MARK: - Search

    private func performSearch() {
        let q = query
        guard !q.isEmpty else { results = []; return }

        isSearching = true
        let text  = fullText
        let pgs   = pages

        Task.detached(priority: .userInitiated) {
            let found = searchText(q, in: text, pages: pgs)
            await MainActor.run {
                results    = found
                isSearching = false
            }
        }
    }
}

// MARK: - Search algorithm

private func searchText(_ query: String, in text: NSAttributedString, pages: [TextPage]) -> [SearchResult] {
    var results: [SearchResult] = []
    let str    = text.string as NSString
    var range  = NSRange(location: 0, length: str.length)
    var seen   = Set<Int>()  // dedupe by page

    while range.location < str.length {
        let found = str.range(of: query, options: .caseInsensitive, range: range)
        guard found.location != NSNotFound else { break }

        let pageIdx = pages.first {
            $0.startOffset <= found.location && $0.endOffset > found.location
        }?.index ?? 0

        if !seen.contains(pageIdx) {
            seen.insert(pageIdx)
            let ctxStart = max(0, found.location - 50)
            let ctxLen   = min(str.length - ctxStart, 140)
            let context  = str.substring(with: NSRange(location: ctxStart, length: ctxLen))
                             .trimmingCharacters(in: .whitespacesAndNewlines)
            results.append(SearchResult(pageIndex: pageIdx, context: context, matchRange: found))
        }

        range = NSRange(location: found.location + found.length,
                        length: str.length - found.location - found.length)
    }

    return results
}
