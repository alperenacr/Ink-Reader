import Foundation

struct EPUBDocument: Sendable {
    let title: String
    let author: String
    let coverImageData: Data?
    let chapters: [EPUBChapter]
}

struct EPUBChapter: Sendable, Identifiable {
    let id: String
    let title: String
    let filePath: URL
}

struct ManifestItem: Sendable {
    let id: String
    let href: String
    let mediaType: String
    let properties: String?
}
