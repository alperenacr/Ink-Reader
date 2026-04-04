import SwiftUI

struct PDFContainerView: View {
    let book: Book

    @Environment(ThemeManager.self)    private var theme
    @Environment(SettingsManager.self) private var settings
    @Environment(\.modelContext)       private var modelContext
    @Environment(\.dismiss)            private var dismiss

    @State private var currentPage = 0
    @State private var totalPages  = 0
    @State private var showControls = true
    @State private var showSettingsSheet = false

    var body: some View {
        ZStack {
            theme.currentTheme.backgroundColor.ignoresSafeArea()

            PDFReaderView(
                url: LibraryManager.shared.fileURL(for: book),
                currentPage: $currentPage,
                totalPages: $totalPages,
                isPageMode: book.readingMode == .page
            )

            // Center tap to toggle overlay
            Color.clear
                .contentShape(Rectangle())
                .frame(width: 90)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) { showControls.toggle() }
                }

            if showControls {
                VStack {
                    pdfTopBar
                    Spacer()
                    pdfBottomBar
                }
                .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(theme.currentTheme.colorScheme)
        .onChange(of: currentPage) {
            book.currentPage    = currentPage
            book.totalPages     = totalPages
            book.lastOpenedDate = Date()
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsView()
                .environment(theme)
                .environment(settings)
                .presentationDetents([.medium])
        }
    }

    // MARK: - Bars

    private var pdfTopBar: some View {
        HStack {
            Button { dismiss() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
                    Text("Library").font(.system(size: 16))
                }
                .foregroundStyle(theme.currentTheme.textColor)
            }
            Spacer()
            Text(book.title)
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundStyle(theme.currentTheme.textColor)
                .lineLimit(1)
                .frame(maxWidth: 180)
            Spacer()
            Button { showSettingsSheet = true } label: {
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

    private var pdfBottomBar: some View {
        HStack {
            if totalPages > 0 {
                Text("\(currentPage + 1) / \(totalPages)")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(theme.currentTheme.secondaryTextColor)
            }
            Spacer()
            if totalPages > 0 {
                Text("\(Int(Double(currentPage) / Double(totalPages) * 100))%")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.currentTheme.secondaryTextColor)
            }
            Spacer()
            Button { toggleMode() } label: {
                Image(systemName: book.readingMode == .page ? "scroll" : "book.pages")
                    .font(.system(size: 16))
                    .foregroundStyle(theme.currentTheme.textColor)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(theme.currentTheme.backgroundColor.opacity(0.95).ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) {
            Rectangle().fill(theme.currentTheme.dividerColor).frame(height: 0.5)
        }
    }

    private func toggleMode() {
        book.readingMode = book.readingMode == .page ? .scroll : .page
    }
}
