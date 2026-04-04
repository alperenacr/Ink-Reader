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

enum EPUBParser {

    static func parse(fileURL: URL, bookId: UUID) async throws -> EPUBDocument {
        let url = fileURL
        let id  = bookId
        return try await Task.detached(priority: .userInitiated) {
            try parseSync(fileURL: url, bookId: id)
        }.value
    }

    static func deleteExtracted(for bookId: UUID) {
        try? FileManager.default.removeItem(at: extractedDir(for: bookId))
    }

    // MARK: - Sync implementation

    private static func parseSync(fileURL: URL, bookId: UUID) throws -> EPUBDocument {
        let destDir = extractedDir(for: bookId)

        if !isExtracted(at: destDir) {
            try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
            try FileManager.default.unzipItem(at: fileURL, to: destDir)
        }

        let opfPath = try parseContainerXML(in: destDir)
        let opfURL  = destDir.appendingPathComponent(opfPath)
        let opfDir  = opfURL.deletingLastPathComponent()
        let opf     = try parseOPF(at: opfURL)

        // Cover image
        var coverData: Data?
        if let coverId = opf.coverImageId, let item = opf.manifest[coverId] {
            coverData = try? Data(contentsOf: opfDir.appendingPathComponent(item.href))
        }
        if coverData == nil {
            for name in ["cover.jpg", "cover.jpeg", "cover.png"] {
                if let data = try? Data(contentsOf: opfDir.appendingPathComponent(name)) {
                    coverData = data; break
                }
            }
        }

        // Build chapters
        var chapters: [EPUBChapter] = []
        for (index, idref) in opf.spine.enumerated() {
            guard let item = opf.manifest[idref],
                  item.mediaType.contains("html") else { continue }
            chapters.append(EPUBChapter(
                id: item.id,
                title: "Chapter \(index + 1)",
                filePath: opfDir.appendingPathComponent(item.href)
            ))
        }
        guard !chapters.isEmpty else { throw EPUBParserError.invalidEPUB }

        // Build TOC
        let toc = buildTOC(opf: opf, opfDir: opfDir, chapters: chapters)

        return EPUBDocument(
            title: opf.title.isEmpty ? "Unknown Title" : opf.title,
            author: opf.author.isEmpty ? "Unknown Author" : opf.author,
            coverImageData: coverData,
            chapters: chapters,
            toc: toc
        )
    }

    // MARK: - TOC

    private static func buildTOC(
        opf: OPFResult,
        opfDir: URL,
        chapters: [EPUBChapter]
    ) -> [TOCEntry] {
        // EPUB 3: look for nav item
        if let navItem = opf.manifest.values.first(where: { $0.properties?.contains("nav") == true }) {
            let navURL = opfDir.appendingPathComponent(navItem.href)
            if let entries = parseNavXHTML(at: navURL, chapters: chapters), !entries.isEmpty {
                return entries
            }
        }

        // EPUB 2: look for toc.ncx
        if let ncxItem = opf.manifest.values.first(where: { $0.mediaType == "application/x-dtbncx+xml" }) {
            let ncxURL = opfDir.appendingPathComponent(ncxItem.href)
            if let entries = parseNCX(at: ncxURL, chapters: chapters), !entries.isEmpty {
                return entries
            }
        }

        // Fallback: generate from chapters
        return chapters.enumerated().map { index, ch in
            TOCEntry(title: ch.title, href: ch.filePath.lastPathComponent, chapterIndex: index)
        }
    }

    private static func parseNavXHTML(at url: URL, chapters: [EPUBChapter]) -> [TOCEntry]? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let delegate = NavXHTMLDelegate()
        let parser   = XMLParser(data: data)
        parser.shouldProcessNamespaces = true
        parser.delegate = delegate
        parser.parse()

        return delegate.entries.map { raw in
            let hrefBase = raw.href.components(separatedBy: "#").first ?? raw.href
            let chIdx = chapters.firstIndex { ch in
                ch.filePath.lastPathComponent == hrefBase ||
                ch.filePath.absoluteString.hasSuffix(hrefBase)
            } ?? 0
            return TOCEntry(title: raw.title, href: raw.href, chapterIndex: chIdx, level: raw.level)
        }
    }

    private static func parseNCX(at url: URL, chapters: [EPUBChapter]) -> [TOCEntry]? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let delegate = NCXDelegate()
        let parser   = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()

        return delegate.entries.map { raw in
            let hrefBase = raw.href.components(separatedBy: "#").first ?? raw.href
            let chIdx = chapters.firstIndex { ch in
                ch.filePath.lastPathComponent == hrefBase ||
                ch.filePath.absoluteString.hasSuffix(hrefBase)
            } ?? 0
            return TOCEntry(title: raw.title, href: raw.href, chapterIndex: chIdx, level: raw.level)
        }
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
        guard let data = try? Data(contentsOf: url) else { throw EPUBParserError.missingContainerXML }
        let delegate = ContainerXMLDelegate()
        let parser   = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        guard let path = delegate.opfPath else { throw EPUBParserError.missingOPFPath }
        return path
    }

    private static func parseOPF(at url: URL) throws -> OPFResult {
        guard let data = try? Data(contentsOf: url) else { throw EPUBParserError.missingOPFFile }
        let delegate = OPFXMLDelegate()
        let parser   = XMLParser(data: data)
        parser.shouldProcessNamespaces = true
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

private struct RawTOCEntry {
    let title: String
    let href: String
    let level: Int
}

// MARK: - XML Delegates

private final class ContainerXMLDelegate: NSObject, XMLParserDelegate {
    var opfPath: String?
    func parser(_ p: XMLParser, didStartElement el: String, namespaceURI: String?,
                qualifiedName _: String?, attributes attr: [String: String] = [:]) {
        if el == "rootfile" { opfPath = attr["full-path"] }
    }
}

private final class OPFXMLDelegate: NSObject, XMLParserDelegate {
    var title = ""; var author = ""
    var manifest: [String: ManifestItem] = [:]
    var spine: [String] = []
    var coverImageId: String?
    private var currentElement = ""; private var currentText = ""

    func parser(_ p: XMLParser, didStartElement el: String, namespaceURI ns: String?,
                qualifiedName _: String?, attributes attr: [String: String] = [:]) {
        currentElement = el; currentText = ""
        switch el {
        case "item":
            let id   = attr["id"] ?? UUID().uuidString
            let item = ManifestItem(id: id, href: attr["href"] ?? "",
                                    mediaType: attr["media-type"] ?? "",
                                    properties: attr["properties"])
            manifest[id] = item
            if item.properties?.contains("cover-image") == true || id.lowercased() == "cover-image" {
                if coverImageId == nil { coverImageId = id }
            }
        case "itemref":
            if let idref = attr["idref"] { spine.append(idref) }
        default: break
        }
    }

    func parser(_ p: XMLParser, foundCharacters s: String) { currentText += s }

    func parser(_ p: XMLParser, didEndElement el: String, namespaceURI: String?,
                qualifiedName _: String?) {
        let t = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        if (el == "dc:title"   || el == "title")   && title.isEmpty  && !t.isEmpty { title  = t }
        if (el == "dc:creator" || el == "creator") && author.isEmpty && !t.isEmpty { author = t }
        currentText = ""
    }
}

// EPUB 3 nav.xhtml parser
private final class NavXHTMLDelegate: NSObject, XMLParserDelegate {
    var entries: [RawTOCEntry] = []
    private var inTOCNav  = false
    private var level     = 0
    private var currentText = ""
    private var pendingHref: String?

    func parser(_ p: XMLParser, didStartElement el: String, namespaceURI ns: String?,
                qualifiedName _: String?, attributes attr: [String: String] = [:]) {
        let localName = el.components(separatedBy: ":").last ?? el
        if localName == "nav" && (attr["epub:type"] ?? attr["type"] ?? "").contains("toc") {
            inTOCNav = true
        }
        if inTOCNav {
            if localName == "ol" { level += 1 }
            if localName == "a"  { pendingHref = attr["href"]; currentText = "" }
        }
    }

    func parser(_ p: XMLParser, foundCharacters s: String) {
        if inTOCNav { currentText += s }
    }

    func parser(_ p: XMLParser, didEndElement el: String, namespaceURI: String?,
                qualifiedName _: String?) {
        let localName = el.components(separatedBy: ":").last ?? el
        if inTOCNav {
            if localName == "a", let href = pendingHref {
                let title = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !title.isEmpty {
                    entries.append(RawTOCEntry(title: title, href: href, level: max(0, level - 1)))
                }
                pendingHref = nil; currentText = ""
            }
            if localName == "ol" { level -= 1 }
            if localName == "nav" { inTOCNav = false }
        }
    }
}

// EPUB 2 toc.ncx parser
private final class NCXDelegate: NSObject, XMLParserDelegate {
    var entries: [RawTOCEntry] = []
    private var depth = 0
    private var currentTitle = ""
    private var currentSrc   = ""
    private var inLabel = false

    func parser(_ p: XMLParser, didStartElement el: String, namespaceURI: String?,
                qualifiedName _: String?, attributes attr: [String: String] = [:]) {
        switch el {
        case "navPoint":  depth += 1
        case "text":      if depth > 0 { inLabel = true; currentTitle = "" }
        case "content":   currentSrc = attr["src"] ?? ""
        default: break
        }
    }

    func parser(_ p: XMLParser, foundCharacters s: String) {
        if inLabel { currentTitle += s }
    }

    func parser(_ p: XMLParser, didEndElement el: String, namespaceURI: String?,
                qualifiedName _: String?) {
        switch el {
        case "text": inLabel = false
        case "navPoint":
            let title = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            if !title.isEmpty && !currentSrc.isEmpty {
                entries.append(RawTOCEntry(title: title, href: currentSrc, level: depth - 1))
            }
            depth -= 1; currentTitle = ""; currentSrc = ""
        default: break
        }
    }
}
