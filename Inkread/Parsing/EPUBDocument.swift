import Foundation

struct EPUBDocument: Sendable {
    let title: String
    let author: String
    let coverImageData: Data?
    let chapters: [EPUBChapter]
    let toc: [TOCEntry]
}

struct EPUBChapter: Sendable, Identifiable {
    let id: String
    let title: String
    let filePath: URL
}

struct TOCEntry: Sendable, Identifiable {
    let id: UUID
    let title: String
    let href: String       // relative href (may include #anchor)
    let chapterIndex: Int  // index into document.chapters
    let level: Int

    init(title: String, href: String, chapterIndex: Int, level: Int = 0) {
        self.id           = UUID()
        self.title        = title
        self.href         = href
        self.chapterIndex = chapterIndex
        self.level        = level
    }
}

struct ManifestItem: Sendable {
    let id: String
    let href: String
    let mediaType: String
    let properties: String?
}
