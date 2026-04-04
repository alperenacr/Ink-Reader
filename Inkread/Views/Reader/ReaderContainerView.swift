import SwiftUI
import UIKit

struct ReaderContainerView: View {
    let document: EPUBDocument
    let book: Book

    @Environment(ThemeManager.self)    private var theme
    @Environment(SettingsManager.self) private var settings
    @Environment(\.modelContext)       private var modelContext
    @Environment(\.dismiss)            private var dismiss

    @State private var pages: [TextPage] = []
    @State private var fullText: NSAttributedString = NSAttributedString()
    @State private var currentPage: Int = 0
    @State private var isPaginating = true
    @State private var showControls = true
    @State private var showSettingsSheet = false
    @State private var pageSize: CGSize = .zero

    private let hPad: CGFloat = 24
    private let vPad: CGFloat = 20

    var body: some View {
        GeometryReader { geo in
            ZStack {
                theme.currentTheme.backgroundColor.ignoresSafeArea()

                if isPaginating {
                    paginatingView
                } else {
                    contentView(geo: geo)
                }

                if showControls && !isPaginating {
                    ReaderOverlayView(
                        book: book,
                        currentPage: currentPage,
                        totalPages: pages.count,
                        onDismiss: { dismiss() },
                        onToggleMode: { toggleReadingMode() },
                        onOpenSettings: { showSettingsSheet = true }
                    )
                    .transition(.opacity)
                }
            }
            .onAppear {
                let textArea = CGSize(
                    width:  geo.size.width  - hPad * 2,
                    height: geo.size.height - vPad * 2
                )
                pageSize = textArea
                currentPage = book.currentPage
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .task { await loadAndPaginate() }
        .onChange(of: settings.fontSize)    { await repaginate() }
        .onChange(of: settings.readingFont) { await repaginate() }
        .onChange(of: settings.lineSpacing) { await repaginate() }
        .onChange(of: currentPage) { saveProgress() }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsView()
                .environment(theme)
                .environment(settings)
                .presentationDetents([.medium])
        }
        .preferredColorScheme(theme.currentTheme.colorScheme)
    }

    // MARK: - Content Views

    private var paginatingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .scaleEffect(1.1)
                .tint(theme.currentTheme.textColor)
            Text("Preparing book…")
                .font(.system(size: 14))
                .foregroundStyle(theme.currentTheme.secondaryTextColor)
        }
    }

    @ViewBuilder
    private func contentView(geo: GeometryProxy) -> some View {
        if book.readingMode == .page {
            PagedReaderView(
                pages: pages,
                currentPage: $currentPage,
                onTapCenter: { withAnimation(.easeInOut(duration: 0.2)) { showControls.toggle() } },
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

    // MARK: - Loading

    @MainActor
    private func loadAndPaginate() async {
        guard pageSize != .zero else { return }
        isPaginating = true

        // 1. Load HTML strings from files (can be done anywhere)
        let htmlStrings = document.chapters.compactMap { chapter -> String? in
            try? String(contentsOf: chapter.filePath, encoding: .utf8)
        }

        // 2. Convert HTML → NSAttributedString (main thread required)
        let combined = NSMutableAttributedString()
        for html in htmlStrings {
            if let attrStr = await htmlToAttributedString(html) {
                combined.append(attrStr)
                combined.append(NSAttributedString(string: "\n\n"))
            }
        }

        // 3. Apply user typography settings
        applyReadingStyle(
            to: combined,
            font: settings.readingFont,
            size: settings.fontSize,
            textColor: UIColor(theme.currentTheme.textColor),
            lineSpacing: settings.lineSpacing.value
        )

        let immutable = combined.copy() as! NSAttributedString
        fullText = immutable

        // 4. Paginate on background thread
        let size = pageSize
        let newPages = await Task.detached(priority: .userInitiated) {
            paginate(immutable, pageSize: size)
        }.value

        pages = newPages
        currentPage = min(book.currentPage, max(0, newPages.count - 1))
        isPaginating = false
    }

    @MainActor
    private func repaginate() async {
        await loadAndPaginate()
    }

    // MARK: - Helpers

    private func toggleReadingMode() {
        book.readingMode = book.readingMode == .page ? .scroll : .page
    }

    private func saveProgress() {
        book.currentPage = currentPage
        book.lastOpenedDate = Date()
        if !pages.isEmpty {
            book.totalPages = pages.count
        }
    }
}
