import Foundation
import CoreText
import UIKit

struct TextPage: Sendable {
    let index: Int
    let attributedText: NSAttributedString
    let startOffset: Int   // character offset in full combined text
    let endOffset: Int
}

// MARK: - HTML → NSAttributedString (main thread)

@MainActor
func htmlToAttributedString(_ html: String) -> NSAttributedString? {
    var cleaned = html
    cleaned = cleaned.replacingOccurrences(of: #"<\?xml[^>]*\?>"#, with: "", options: .regularExpression)
    cleaned = cleaned.replacingOccurrences(
        of: #"<style[^>]*>[\s\S]*?</style>"#, with: "",
        options: [.regularExpression, .caseInsensitive]
    )
    if let s = cleaned.range(of: #"<body[^>]*>"#, options: .regularExpression),
       let e = cleaned.range(of: "</body>", options: [.backwards, .caseInsensitive]) {
        cleaned = String(cleaned[s.upperBound..<e.lowerBound])
    }
    guard let data = cleaned.data(using: .utf8) else { return nil }
    return try? NSAttributedString(
        data: data,
        options: [.documentType: NSAttributedString.DocumentType.html,
                  .characterEncoding: String.Encoding.utf8.rawValue],
        documentAttributes: nil
    )
}

// MARK: - Typography style

func applyReadingStyle(
    to attrString: NSMutableAttributedString,
    font: ReadingFont,
    size: CGFloat,
    textColor: UIColor,
    lineSpacing: CGFloat
) {
    let fullRange = NSRange(location: 0, length: attrString.length)

    attrString.enumerateAttribute(.font, in: fullRange, options: []) { value, subRange, _ in
        let traits   = (value as? UIFont)?.fontDescriptor.symbolicTraits ?? []
        let isBold   = traits.contains(.traitBold)
        let isItalic = traits.contains(.traitItalic)

        let finalFont: UIFont
        switch (font, isBold, isItalic) {
        case (.serif, true,  true):  finalFont = UIFont(name: "Georgia-BoldItalic", size: size) ?? .systemFont(ofSize: size)
        case (.serif, true,  false): finalFont = UIFont(name: "Georgia-Bold", size: size)       ?? .boldSystemFont(ofSize: size)
        case (.serif, false, true):  finalFont = UIFont(name: "Georgia-Italic", size: size)     ?? .italicSystemFont(ofSize: size)
        case (.serif, false, false): finalFont = UIFont(name: "Georgia", size: size)            ?? .systemFont(ofSize: size)
        case (.sansSerif, true, _):  finalFont = .boldSystemFont(ofSize: size)
        case (.sansSerif, _, true):  finalFont = .italicSystemFont(ofSize: size)
        default:                     finalFont = .systemFont(ofSize: size)
        }
        attrString.addAttribute(.font, value: finalFont, range: subRange)
    }

    let paragraph = NSMutableParagraphStyle()
    paragraph.lineSpacing      = lineSpacing
    paragraph.paragraphSpacing = size * 0.7

    attrString.addAttributes([
        .foregroundColor: textColor,
        .paragraphStyle: paragraph
    ], range: fullRange)
}

// MARK: - Pagination

func paginate(_ attributedString: NSAttributedString, pageSize: CGSize) -> [TextPage] {
    var pages: [TextPage] = []
    var startIndex = 0
    let total      = attributedString.length
    var pageIndex  = 0

    while startIndex < total {
        let remaining = attributedString.attributedSubstring(
            from: NSRange(location: startIndex, length: total - startIndex)
        )
        let framesetter = CTFramesetterCreateWithAttributedString(remaining as CFAttributedString)
        let path        = CGPath(rect: CGRect(origin: .zero, size: pageSize), transform: nil)
        let frame       = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
        let range       = CTFrameGetVisibleStringRange(frame)

        guard range.length > 0 else { break }

        let pageAttr = attributedString.attributedSubstring(
            from: NSRange(location: startIndex, length: range.length)
        )
        pages.append(TextPage(
            index: pageIndex,
            attributedText: pageAttr,
            startOffset: startIndex,
            endOffset: startIndex + range.length
        ))

        startIndex += range.length
        pageIndex  += 1
    }

    return pages
}

// MARK: - Highlight rendering

func applyHighlights(
    _ highlights: [HighlightRange],
    to base: NSAttributedString,
    pageStartOffset: Int
) -> NSAttributedString {
    guard !highlights.isEmpty else { return base }

    let mutable = NSMutableAttributedString(attributedString: base)
    let pageEnd = pageStartOffset + base.length

    for h in highlights {
        guard h.startOffset < pageEnd && h.endOffset > pageStartOffset else { continue }
        let relStart = max(0, h.startOffset - pageStartOffset)
        let relEnd   = min(base.length, h.endOffset - pageStartOffset)
        guard relEnd > relStart else { continue }
        mutable.addAttribute(
            .backgroundColor,
            value: h.color.uiColor,
            range: NSRange(location: relStart, length: relEnd - relStart)
        )
    }

    return mutable
}
