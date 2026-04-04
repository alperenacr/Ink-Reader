import Foundation
import SwiftData

@Model
final class Book {
    var id: UUID
    var title: String
    var author: String
    var fileName: String
    var fileFormat: BookFormat
    var coverImageData: Data?
    var currentPage: Int
    var totalPages: Int
    var lastOpenedDate: Date?
    var addedDate: Date
    var readingMode: ReadingMode

    init(
        title: String,
        author: String,
        fileName: String,
        fileFormat: BookFormat
    ) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.fileName = fileName
        self.fileFormat = fileFormat
        self.currentPage = 0
        self.totalPages = 0
        self.addedDate = Date()
        self.readingMode = .page
    }

    var progress: Double {
        guard totalPages > 0 else { return 0 }
        return Double(currentPage) / Double(totalPages)
    }

    var hasStarted: Bool {
        currentPage > 0
    }
}

enum BookFormat: String, Codable {
    case epub
    case pdf
}

enum ReadingMode: String, Codable {
    case page
    case scroll
}
