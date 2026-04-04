import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var theme
    @Query(sort: \Book.addedDate, order: .reverse) private var books: [Book]

    @State private var showImporter = false
    @State private var showSettings = false
    @State private var importError: String?

    private let columns = [
        GridItem(.adaptive(minimum: 110, maximum: 150), spacing: 20)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                theme.currentTheme.backgroundColor
                    .ignoresSafeArea()

                if books.isEmpty {
                    EmptyLibraryView { showImporter = true }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(books) { book in
                                NavigationLink {
                                    ReaderView(book: book)
                                } label: {
                                    BookCardView(book: book)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        deleteBook(book)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Inkread")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(theme.currentTheme.backgroundColor, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 18) {
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape")
                                .foregroundStyle(theme.currentTheme.textColor)
                        }
                        Button { showImporter = true } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(theme.currentTheme.textColor)
                        }
                    }
                }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.epub, .pdf],
                allowsMultipleSelection: true
            ) { result in
                handleImport(result)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environment(theme)
            }
            .alert("Import Failed", isPresented: Binding(
                get: { importError != nil },
                set: { if !$0 { importError = nil } }
            )) {
                Button("OK") { importError = nil }
            } message: {
                Text(importError ?? "")
            }
        }
        .preferredColorScheme(theme.currentTheme.colorScheme)
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                do {
                    let info = try LibraryManager.shared.importBook(from: url)
                    let book = Book(
                        title: info.title,
                        author: info.author,
                        fileName: info.fileName,
                        fileFormat: info.format
                    )
                    modelContext.insert(book)
                } catch {
                    importError = error.localizedDescription
                }
            }
        case .failure(let error):
            importError = error.localizedDescription
        }
    }

    private func deleteBook(_ book: Book) {
        LibraryManager.shared.deleteFile(for: book)
        modelContext.delete(book)
    }
}
