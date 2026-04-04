import Foundation
import ZIPFoundation

enum EPUBParserError: LocalizedError {
    case missingContainerXML
    case missingOPFPath
    case missingOPFFile
    case invalidEPUB

    var errorDescription: String? {
        switch self {
        case .missingContainerXML: return "Could not find META-INF/container.xml"
        case .missingOPFPath:      return "Could not locate OPF package file"
        case .missingOPFFile:      return "Could not read OPF file"
        case .invalidEPUB:         return "File does not appear to be a valid EPUB"
        }
    }
}

// MARK: - Parser entry point (nonisolated, runs on background thread)

enum EPUBParser {

    static func parse(fileURL: URL, bookId: UUID) async throws -> EPUBDocument {
        let url = fileURL
        let id = bookId
        return try await Task.detached(priority: .userInitiated) {
            try parseSync(fileURL: url, bookId: id)
        }.value
    }

    static func deleteExtracted(for bookId: UUID) {
        let dir = extractedDir(for: bookId)
        try? FileManager.default.removeItem(at: dir)
    }

    // MARK: - Private sync implementation

    private static func parseSync(fileURL: URL, bookId: UUID) throws -> EPUBDocument {
        let destDir = extractedDir(for: bookId)

        // Extract if not already done
        if !isExtracted(at: destDir) {
            try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
            try FileManager.default.unzipItem(at: fileURL, to: destDir)
        }

        // container.xml → OPF path
        let opfPath = try parseContainerXML(in: destDir)
        let opfURL  = destDir.appendingPathComponent(opfPath)
        let opfDir  = opfURL.deletingLastPathComponent()

        // OPF → metadata + manifest + spine
        let opf = try parseOPF(at: opfURL)

        // Cover image
        var coverData: Data?
        if let coverId = opf.coverImageId,
           let item = opf.manifest[coverId] {
            let coverURL = opfDir.appendingPathComponent(item.href)
            coverData = try? Data(contentsOf: coverURL)
        }
        // Fallback: look for cover.jpg / cover.png in opfDir
        if coverData == nil {
            for name in ["cover.jpg", "cover.jpeg", "cover.png"] {
                if let data = try? Data(contentsOf: opfDir.appendingPathComponent(name)) {
                    coverData = data
                    break
                }
            }
        }

        // Build chapters from spine
        var chapters: [EPUBChapter] = []
        for (index, idref) in opf.spine.enumerated() {
            guard let item = opf.manifest[idref],
                  item.mediaType.contains("html") else { continue }
            let chapterURL = opfDir.appendingPathComponent(item.href)
            chapters.append(EPUBChapter(
                id: item.id,
                title: "Chapter \(index + 1)",
                filePath: chapterURL
            ))
        }

        guard !chapters.isEmpty else { throw EPUBParserError.invalidEPUB }

        return EPUBDocument(
            title: opf.title.isEmpty ? "Unknown Title" : opf.title,
            author: opf.author.isEmpty ? "Unknown Author" : opf.author,
            coverImageData: coverData,
            chapters: chapters
        )
    }

    // MARK: - Helpers

    private static func extractedDir(for bookId: UUID) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("ExtractedEPUBs/\(bookId.uuidString)")
    }

    private static func isExtracted(at dir: URL) -> Bool {
        let contents = try? FileManager.default.contentsOfDirectory(atPath: dir.path)
        return (contents?.count ?? 0) > 0
    }

    private static func parseContainerXML(in dir: URL) throws -> String {
        let url = dir.appendingPathComponent("META-INF/container.xml")
        guard let data = try? Data(contentsOf: url) else {
            throw EPUBParserError.missingContainerXML
        }
        let delegate = ContainerXMLDelegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        guard let path = delegate.opfPath else {
            throw EPUBParserError.missingOPFPath
        }
        return path
    }

    private static func parseOPF(at url: URL) throws -> OPFResult {
        guard let data = try? Data(contentsOf: url) else {
            throw EPUBParserError.missingOPFFile
        }
        let delegate = OPFXMLDelegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        return OPFResult(
            title: delegate.title,
            author: delegate.author,
            manifest: delegate.manifest,
            spine: delegate.spine,
            coverImageId: delegate.coverImageId
        )
    }
}

// MARK: - Internal types

private struct OPFResult {
    let title: String
    let author: String
    let manifest: [String: ManifestItem]
    let spine: [String]
    let coverImageId: String?
}

// MARK: - XML delegates

private final class ContainerXMLDelegate: NSObject, XMLParserDelegate {
    var opfPath: String?

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName _: String?,
        attributes: [String: String] = [:]
    ) {
        if elementName == "rootfile" {
            opfPath = attributes["full-path"]
        }
    }
}

private final class OPFXMLDelegate: NSObject, XMLParserDelegate {
    var title = ""
    var author = ""
    var manifest: [String: ManifestItem] = [:]
    var spine: [String] = []
    var coverImageId: String?

    private var currentElement = ""
    private var currentText = ""

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName _: String?,
        attributes: [String: String] = [:]
    ) {
        currentElement = elementName
        currentText = ""

        switch elementName {
        case "item":
            let id = attributes["id"] ?? UUID().uuidString
            let item = ManifestItem(
                id: id,
                href: attributes["href"] ?? "",
                mediaType: attributes["media-type"] ?? "",
                properties: attributes["properties"]
            )
            manifest[id] = item
            if item.properties?.contains("cover-image") == true || id.lowercased().contains("cover") {
                if coverImageId == nil { coverImageId = id }
            }
        case "itemref":
            if let idref = attributes["idref"] { spine.append(idref) }
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName _: String?
    ) {
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        switch elementName {
        case "dc:title", "title":
            if title.isEmpty && !text.isEmpty { title = text }
        case "dc:creator", "creator":
            if author.isEmpty && !text.isEmpty { author = text }
        default:
            break
        }
        currentText = ""
    }
}
