import Foundation
import SwiftData
import PencilKit

@Model
final class PageAnnotation {
    var id: UUID
    var bookId: UUID
    var pageIndex: Int
    var drawingData: Data

    init(bookId: UUID, pageIndex: Int) {
        self.id          = UUID()
        self.bookId      = bookId
        self.pageIndex   = pageIndex
        self.drawingData = Data()
    }

    var drawing: PKDrawing {
        get { (try? PKDrawing(data: drawingData)) ?? PKDrawing() }
        set { drawingData = (try? newValue.dataRepresentation()) ?? Data() }
    }
}
