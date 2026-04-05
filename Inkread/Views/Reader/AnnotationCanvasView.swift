import SwiftUI
import PencilKit

struct AnnotationCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    var isActive: Bool
    var toolColor: UIColor = .systemBlue
    var onChanged: (PKDrawing) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawing       = drawing
        canvas.isOpaque      = false
        canvas.backgroundColor = .clear
        // Only Pencil input — finger still scrolls/taps through
        canvas.drawingPolicy = .pencilOnly
        canvas.delegate      = context.coordinator
        canvas.isUserInteractionEnabled = isActive
        canvas.tool = PKInkingTool(.pen, color: toolColor, width: 2)
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        context.coordinator.parent = self
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
        uiView.isUserInteractionEnabled = isActive
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: AnnotationCanvasView

        init(parent: AnnotationCanvasView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.onChanged(canvasView.drawing)
        }
    }
}
