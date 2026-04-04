import SwiftUI

struct ReaderView: View {
    let book: Book

    @Environment(ThemeManager.self)    private var theme
    @Environment(SettingsManager.self) private var settings
    @Environment(\.modelContext)       private var modelContext

    @State private var document: EPUBDocument?
    @State private var isLoading = true
    @State private var loadError: String?

    var body: some View {
        ZStack {
            theme.currentTheme.backgroundColor.ignoresSafeArea()

            if book.fileFormat == .pdf {
                // PDF: route directly, no parsing needed
                PDFContainerView(book: book)
                    .environment(theme)
                    .environment(settings)
                    .onAppear { isLoading = false }
            } else if isLoading {
                loadingView
            } else if let error = loadError {
                errorView(error)
            } else if let doc = document {
                ReaderContainerView(document: doc, book: book)
            }
        }
        .navigationBarHidden(true)
        .task {
            guard book.fileFormat == .epub else { return }
            await loadEPUB()
        }
    }

    // MARK: - States

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(theme.currentTheme.textColor)
            Text("Opening…")
                .font(.system(size: 15))
                .foregroundStyle(theme.currentTheme.secondaryTextColor)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44, weight: .thin))
                .foregroundStyle(theme.currentTheme.secondaryTextColor)
            VStack(spacing: 8) {
                Text("Could not open book")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundStyle(theme.currentTheme.textColor)
                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.currentTheme.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }

    // MARK: - Loading

    @MainActor
    private func loadEPUB() async {
        guard LibraryManager.shared.fileExists(for: book) else {
            loadError = "Book file not found."
            isLoading = false
            return
        }

        let fileURL = LibraryManager.shared.fileURL(for: book)

        do {
            let doc = try await EPUBParser.parse(fileURL: fileURL, bookId: book.id)

            if book.title == "Unknown Title" || book.title.isEmpty { book.title = doc.title }
            if book.author == "Unknown Author" && !doc.author.isEmpty { book.author = doc.author }
            if book.coverImageData == nil, let cover = doc.coverImageData { book.coverImageData = cover }

            document = doc
        } catch {
            loadError = error.localizedDescription
        }

        isLoading = false
    }
}
