import SwiftUI
import PDFKit

struct PDFReaderView: UIViewRepresentable {
    let url: URL
    @Binding var currentPage: Int
    @Binding var totalPages: Int
    var isPageMode: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales       = true
        pdfView.backgroundColor  = .clear
        pdfView.displayMode      = isPageMode ? .singlePage : .singlePageContinuous
        pdfView.displayDirection = isPageMode ? .horizontal : .vertical

        if isPageMode {
            pdfView.usePageViewController(true, withViewOptions: nil)
        }

        if let document = PDFDocument(url: url) {
            pdfView.document = document
            DispatchQueue.main.async {
                self.totalPages = document.pageCount
            }
        }

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageDidChange(_:)),
            name: .PDFViewPageChanged,
            object: pdfView
        )

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        guard let doc = uiView.document,
              currentPage < doc.pageCount,
              let page = doc.page(at: currentPage) else { return }

        if uiView.currentPage != page {
            uiView.go(to: page)
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject {
        var parent: PDFReaderView

        init(parent: PDFReaderView) {
            self.parent = parent
        }

        @objc func pageDidChange(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let page    = pdfView.currentPage,
                  let doc     = pdfView.document else { return }
            let index = doc.index(for: page)
            DispatchQueue.main.async {
                self.parent.currentPage = index
            }
        }
    }
}
