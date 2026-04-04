import SwiftUI
import UIKit

struct ReaderPageView: UIViewRepresentable {
    let baseText: NSAttributedString
    let highlights: [HighlightRange]
    let pageStartOffset: Int
    var onHighlight: ((NSRange, HighlightColor) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> SelectableTextView {
        let tv = SelectableTextView()
        tv.isEditable            = false
        tv.isSelectable          = true
        tv.isScrollEnabled       = false
        tv.backgroundColor       = .clear
        tv.textContainerInset    = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.delegate              = context.coordinator
        tv.onHighlight           = { range, color in context.coordinator.parent.onHighlight?(range, color) }
        tv.attributedText        = renderedText
        return tv
    }

    func updateUIView(_ uiView: SelectableTextView, context: Context) {
        context.coordinator.parent = self
        uiView.onHighlight = { range, color in context.coordinator.parent.onHighlight?(range, color) }
        let rendered = renderedText
        if uiView.attributedText != rendered {
            uiView.attributedText = rendered
        }
    }

    private var renderedText: NSAttributedString {
        applyHighlights(highlights, to: baseText, pageStartOffset: pageStartOffset)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: ReaderPageView

        init(parent: ReaderPageView) {
            self.parent = parent
        }
    }
}

// MARK: - Custom UITextView with highlight menu

final class SelectableTextView: UITextView {
    var onHighlight: ((NSRange, HighlightColor) -> Void)?

    // Replace standard menu with highlight-only menu
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }

    @available(iOS 16.0, *)
    override func editMenu(
        for textRange: UITextRange,
        suggestedActions: [UIMenuElement]
    ) -> UIMenu? {
        let start  = offset(from: beginningOfDocument, to: textRange.start)
        let length = offset(from: textRange.start, to: textRange.end)
        guard length > 0 else { return nil }
        let nsRange = NSRange(location: start, length: length)

        let actions = HighlightColor.allCases.map { color in
            UIAction(title: color.rawValue.capitalized,
                     image: circleImage(color: color.uiColor)) { [weak self] _ in
                self?.onHighlight?(nsRange, color)
                self?.selectedRange = NSRange(location: 0, length: 0)
            }
        }

        return UIMenu(
            title: "Highlight",
            image: UIImage(systemName: "highlighter"),
            children: actions
        )
    }

    private func circleImage(color: UIColor) -> UIImage? {
        let size = CGSize(width: 20, height: 20)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            color.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
        }
    }
}
