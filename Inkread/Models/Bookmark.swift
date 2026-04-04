import SwiftData
import Foundation

@Model
final class Bookmark {
    var id: UUID
    var bookId: UUID
    var pageIndex: Int
    var snippet: String
    var createdAt: Date

    init(bookId: UUID, pageIndex: Int, snippet: String) {
        self.id        = UUID()
        self.bookId    = bookId
        self.pageIndex = pageIndex
        self.snippet   = snippet
        self.createdAt = Date()
    }
}
