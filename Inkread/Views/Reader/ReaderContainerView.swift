import SwiftUI
import SwiftData
import UIKit

struct ReaderContainerView: View {
    let document: EPUBDocument
    let book: Book

    @Environment(ThemeManager.self)    private var theme
    @Environment(SettingsManager.self) private var settings
    @Environment(\.modelContext)       private var modelContext
    @Environment(\.dismiss)            private var dismiss

    @Query private var allHighlights: [Highlight]
    @Query private var allBookmarks:  [Bookmark]

    @State private var pages: [TextPage] = []
    @State private var fullText: NSAttributedString = NSAttributedString()
    @State private var chapterOffsets: [Int] = []        // page index per chapter start
    @State private var currentPage   = 0
    @State private var isPaginating  = true
    @State private var showControls  = true
    @State private var showTOC       = false
    @State private var showBookmarks = false
    @State private var showSettings  = false
    @State private var pageSize: CGSize = .zero
    @State private var isCurrentPageBookmarked = false

    private let hPad: CGFloat = 24
    private let vPad: CGFloat = 20

    private var highlights: [HighlightRange] {
        allHighlights
            .filter { $0.bookId == book.id }
            .map { HighlightRange(startOffset: $0.startOffset, endOffset: $0.endOffset, color: $0.color) }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                theme.currentTheme.backgroundColor.ignoresSafeArea()

                if isPaginating {
                    paginatingView
                } else {
                    contentView
                }

                if showControls && !isPaginating {
                    overlayView
                        .transition(.opacity)
                }
            }
            .onAppear {
                let w = geo.size.width  - hPad * 2
                let h = geo.size.height - vPad * 2
                pageSize    = CGSize(width: w, height: h)
                currentPage = min(book.currentPage, max(0, pages.count - 1))
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .task { await loadAndPaginate() }
        .onChange(of: settings.fontSize)    { await repaginate() }
        .onChange(of: settings.readingFont) { await repaginate() }
        .onChange(of: settings.lineSpacing) { await repaginate() }
        .onChange(of: currentPage) {
            saveProgress()
            updateBookmarkState()
        }
        .sheet(isPresented: $showTOC) {
            TOCView(
                toc: document.toc,
                chapterOffsets: chapterOffsets,
                currentPage: currentPage
            ) { page in
                withAnimation { currentPage = page }
            }
            .environment(theme)
        }
        .sheet(isPresented: $showBookmarks) {
            BookmarksSheet(bookId: book.id) { page in
                withAnimation { currentPage = page }
            }
            .environment(theme)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environment(theme)
                .environment(settings)
                .presentationDetents([.medium])
        }
        .preferredColorScheme(theme.currentTheme.colorScheme)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        if book.readingMode == .page {
            PagedReaderView(
                pages: pages,
                currentPage: $currentPage,
                highlights: highlights,
                onTapCenter: { withAnimation(.easeInOut(duration: 0.2)) { showControls.toggle() } },
                onHighlight: { range, color, pageStartOffset in
                    addHighlight(range: range, color: color, pageStartOffset: pageStartOffset)
                },
                horizontalPadding: hPad,
                verticalPadding: vPad
            )
        } else {
            ScrollReaderView(
                fullText: fullText,
                horizontalPadding: hPad,
                verticalPadding: vPad,
                onTapCenter: { withAnimation(.easeInOut(duration: 0.2)) { showControls.toggle() } }
            )
        }
    }

    // MARK: - Overlay

    private var overlayView: some View {
        VStack(spacing: 0) {
            topBar
            progressBar
            Spacer()
            bottomBar
        }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
                    Text("Library").font(.system(size: 16))
                }
                .foregroundStyle(theme.currentTheme.textColor)
            }

            Spacer()

            Text(currentChapterTitle)
                .font(.system(size: 13, weight: .medium, design: .serif))
                .foregroundStyle(theme.currentTheme.textColor)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: 160)

            Spacer()

            Button { showSettings = true } label: {
                Image(systemName: "textformat")
                    .font(.system(size: 16))
                    .foregroundStyle(theme.currentTheme.textColor)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(theme.currentTheme.backgroundColor.opacity(0.95).ignoresSafeArea(edges: .top))
        .overlay(alignment: .bottom) {
            Rectangle().fill(theme.currentTheme.dividerColor).frame(height: 0.5)
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(theme.currentTheme.textColor.opacity(0.25))
                .frame(
                    width: pages.isEmpty ? 0 : geo.size.width * (Double(currentPage + 1) / Double(pages.count)),
                    height: 2
                )
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 2)
    }

    private var bottomBar: some View {
        HStack {
            // Page info
            if !pages.isEmpty {
                Text("\(currentPage + 1) / \(pages.count)")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(theme.currentTheme.secondaryTextColor)
            }

            Spacer()

            HStack(spacing: 22) {
                // Bookmark toggle
                Button { toggleBookmark() } label: {
                    Image(systemName: isCurrentPageBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 16))
                        .foregroundStyle(theme.currentTheme.textColor)
                }

                // TOC
                Button { showTOC = true } label: {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 16))
                        .foregroundStyle(theme.currentTheme.textColor)
                }

                // Bookmarks list
                Button { showBookmarks = true } label: {
                    Image(systemName: "bookmark.square")
                        .font(.system(size: 16))
                        .foregroundStyle(theme.currentTheme.textColor)
                }

                // Mode toggle
                Button { toggleReadingMode() } label: {
                    Image(systemName: book.readingMode == .page ? "scroll" : "book.pages")
                        .font(.system(size: 16))
                        .foregroundStyle(theme.currentTheme.textColor)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(theme.currentTheme.backgroundColor.opacity(0.95).ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) {
            Rectangle().fill(theme.currentTheme.dividerColor).frame(height: 0.5)
        }
    }

    private var paginatingView: some View {
        VStack(spacing: 14) {
            ProgressView().scaleEffect(1.1).tint(theme.currentTheme.textColor)
            Text("Preparing book…")
                .font(.system(size: 14))
                .foregroundStyle(theme.currentTheme.secondaryTextColor)
        }
    }

    // MARK: - Helpers

    private var currentChapterTitle: String {
        guard !chapterOffsets.isEmpty else { return book.title }
        var chIdx = 0
        for (i, offset) in chapterOffsets.enumerated() {
            if currentPage >= offset { chIdx = i }
        }
        return document.chapters.indices.contains(chIdx) ? document.chapters[chIdx].title : book.title
    }

    // MARK: - Loading

    @MainActor
    private func loadAndPaginate() async {
        guard pageSize != .zero else { return }
        isPaginating = true

        let htmlStrings = document.chapters.compactMap {
            try? String(contentsOf: $0.filePath, encoding: .utf8)
        }

        let combined = NSMutableAttributedString()
        var chapterCharOffsets: [Int] = []   // char offset per chapter

        for html in htmlStrings {
            chapterCharOffsets.append(combined.length)
            if let attrStr = await htmlToAttributedString(html) {
                combined.append(attrStr)
                combined.append(NSAttributedString(string: "\n\n"))
            }
        }

        applyReadingStyle(
            to: combined,
            font: settings.readingFont,
            size: settings.fontSize,
            textColor: UIColor(theme.currentTheme.textColor),
            lineSpacing: settings.lineSpacing.value
        )

        let immutable = combined.copy() as! NSAttributedString
        fullText = immutable

        let size = pageSize
        let newPages = await Task.detached(priority: .userInitiated) {
            paginate(immutable, pageSize: size)
        }.value

        pages = newPages

        // Map chapter char offsets → page indices
        chapterOffsets = chapterCharOffsets.map { charOffset in
            newPages.firstIndex { $0.startOffset <= charOffset && $0.endOffset > charOffset }
                ?? newPages.firstIndex { $0.startOffset >= charOffset }
                ?? 0
        }

        currentPage = min(book.currentPage, max(0, newPages.count - 1))
        book.totalPages = newPages.count
        updateBookmarkState()
        isPaginating = false
    }

    @MainActor
    private func repaginate() async {
        await loadAndPaginate()
    }

    // MARK: - Actions

    private func saveProgress() {
        book.currentPage    = currentPage
        book.lastOpenedDate = Date()
    }

    private func toggleReadingMode() {
        book.readingMode = book.readingMode == .page ? .scroll : .page
    }

    private func addHighlight(range: NSRange, color: HighlightColor, pageStartOffset: Int) {
        let absStart = pageStartOffset + range.location
        let absEnd   = absStart + range.length
        let snippet  = (fullText.string as NSString)
            .substring(with: NSRange(location: absStart, length: min(range.length, 80)))
        let highlight = Highlight(
            bookId: book.id,
            startOffset: absStart,
            endOffset: absEnd,
            color: color,
            snippet: snippet
        )
        modelContext.insert(highlight)
    }

    private func toggleBookmark() {
        let existing = allBookmarks.first {
            $0.bookId == book.id && $0.pageIndex == currentPage
        }
        if let bm = existing {
            modelContext.delete(bm)
            isCurrentPageBookmarked = false
        } else {
            let snippet = pages.indices.contains(currentPage)
                ? String(pages[currentPage].attributedText.string.prefix(80))
                : ""
            modelContext.insert(Bookmark(bookId: book.id, pageIndex: currentPage, snippet: snippet))
            isCurrentPageBookmarked = true
        }
    }

    private func updateBookmarkState() {
        isCurrentPageBookmarked = allBookmarks.contains {
            $0.bookId == book.id && $0.pageIndex == currentPage
        }
    }
}
