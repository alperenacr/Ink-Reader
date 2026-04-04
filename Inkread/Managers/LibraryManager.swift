import Foundation

@MainActor
final class LibraryManager {
    static let shared = LibraryManager()

    let booksDirectory: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        booksDirectory = docs.appendingPathComponent("Books", isDirectory: true)
        try? FileManager.default.createDirectory(at: booksDirectory, withIntermediateDirectories: true)
    }

    struct ImportedBook {
        let title: String
        let author: String
        let fileName: String
        let format: BookFormat
    }

    func importBook(from sourceURL: URL) throws -> ImportedBook {
        let ext = sourceURL.pathExtension.lowercased()
        let format: BookFormat = ext == "pdf" ? .pdf : .epub
        let fileName = UUID().uuidString + "." + ext
        let destURL = booksDirectory.appendingPathComponent(fileName)

        let accessed = sourceURL.startAccessingSecurityScopedResource()
        defer { if accessed { sourceURL.stopAccessingSecurityScopedResource() } }

        try FileManager.default.copyItem(at: sourceURL, to: destURL)

        let title = sourceURL.deletingPathExtension().lastPathComponent
        return ImportedBook(title: title, author: "Unknown Author", fileName: fileName, format: format)
    }

    func fileURL(for book: Book) -> URL {
        booksDirectory.appendingPathComponent(book.fileName)
    }

    func deleteFile(for book: Book) {
        try? FileManager.default.removeItem(at: fileURL(for: book))
        if book.fileFormat == .epub {
            EPUBParser.deleteExtracted(for: book.id)
        }
    }

    func fileExists(for book: Book) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(for: book).path)
    }
}
