import SwiftUI
import SwiftData
import UniformTypeIdentifiers

enum LibrarySortOrder: String, CaseIterable, Identifiable {
    case recentlyOpened = "Recently Opened"
    case added          = "Date Added"
    case title          = "Title"
    case author         = "Author"
    var id: String { rawValue }
}

struct LibraryView: View {
    @Binding var spotlightBookId: UUID?

    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var theme
    @Environment(SettingsManager.self) private var settings
    @Query(sort: \Book.addedDate, order: .reverse) private var books: [Book]

    @State private var showImporter  = false
    @State private var showSettings  = false
    @State private var searchText    = ""
    @State private var sortOrder     = LibrarySortOrder.recentlyOpened
    @State private var importError: String?
    @State private var spotlightNavigationBook: Book?

    private let columns = [GridItem(.adaptive(minimum: 110, maximum: 150), spacing: 20)]

    private var displayedBooks: [Book] {
        var result = books
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.author.localizedCaseInsensitiveContains(searchText)
            }
        }
        switch sortOrder {
        case .recentlyOpened:
            result.sort { ($0.lastOpenedDate ?? .distantPast) > ($1.lastOpenedDate ?? .distantPast) }
        case .added:
            result.sort { $0.addedDate > $1.addedDate }
        case .title:
            result.sort { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .author:
            result.sort { $0.author.localizedCompare($1.author) == .orderedAscending }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.currentTheme.backgroundColor.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar (only when there are books)
                    if !books.isEmpty {
                        searchBar
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                    }

                    if books.isEmpty {
                        EmptyLibraryView { showImporter = true }
                    } else if displayedBooks.isEmpty {
                        noResultsView
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 24) {
                                ForEach(displayedBooks) { book in
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
            }
            .navigationTitle("Inkread")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(theme.currentTheme.backgroundColor, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        ForEach(LibrarySortOrder.allCases) { order in
                            Button {
                                sortOrder = order
                                HapticManager.selection()
                            } label: {
                                HStack {
                                    Text(order.rawValue)
                                    if sortOrder == order {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundStyle(theme.currentTheme.textColor)
                    }
                }
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
            ) { handleImport($0) }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environment(theme)
                    .environment(settings)
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
        .onAppear { SpotlightManager.indexAll(books) }
        .onChange(of: spotlightBookId) { id in
            guard let id, let book = books.first(where: { $0.id == id }) else { return }
            spotlightNavigationBook = book
            spotlightBookId = nil
        }
        .navigationDestination(item: $spotlightNavigationBook) { book in
            ReaderView(book: book)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(theme.currentTheme.secondaryTextColor)
                .font(.system(size: 14))

            TextField("Search library…", text: $searchText)
                .font(.system(size: 15))
                .foregroundStyle(theme.currentTheme.textColor)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(theme.currentTheme.secondaryTextColor)
                        .font(.system(size: 14))
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(theme.currentTheme.cardColor)
        )
    }

    private var noResultsView: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("No results for "\(searchText)"")
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(theme.currentTheme.secondaryTextColor)
            Spacer()
        }
    }

    // MARK: - Actions

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                do {
                    let info = try LibraryManager.shared.importBook(from: url)
                    let book = Book(
                        title: info.title, author: info.author,
                        fileName: info.fileName, fileFormat: info.format
                    )
                    modelContext.insert(book)
                    SpotlightManager.indexBook(book)
                    HapticManager.success()
                } catch {
                    importError = error.localizedDescription
                }
            }
        case .failure(let error):
            importError = error.localizedDescription
        }
    }

    private func deleteBook(_ book: Book) {
        SpotlightManager.deindexBook(bookId: book.id)
        LibraryManager.shared.deleteFile(for: book)
        modelContext.delete(book)
        HapticManager.selection()
    }
}
