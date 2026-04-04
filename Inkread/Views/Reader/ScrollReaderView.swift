import SwiftUI
import UIKit

struct ScrollReaderView: View {
    let fullText: NSAttributedString
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let onTapCenter: () -> Void

    var body: some View {
        ScrollView {
            ScrollTextView(attributedText: fullText)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
        }
        .onTapGesture { onTapCenter() }
    }
}

// UITextView in scroll mode — used for scroll reader
private struct ScrollTextView: UIViewRepresentable {
    let attributedText: NSAttributedString

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isEditable      = false
        tv.isSelectable    = false
        tv.isScrollEnabled = false   // outer SwiftUI ScrollView handles scrolling
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.attributedText != attributedText {
            uiView.attributedText = attributedText
        }
    }
}
