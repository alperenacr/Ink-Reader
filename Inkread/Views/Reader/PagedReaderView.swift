import SwiftUI

struct PagedReaderView: View {
    let pages: [TextPage]
    @Binding var currentPage: Int
    let highlights: [HighlightRange]
    let onTapCenter: () -> Void
    let onHighlight: (NSRange, HighlightColor, Int) -> Void  // range, color, pageStartOffset
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat

    var body: some View {
        ZStack {
            TabView(selection: $currentPage) {
                ForEach(pages, id: \.index) { page in
                    ReaderPageView(
                        baseText: page.attributedText,
                        highlights: highlights,
                        pageStartOffset: page.startOffset,
                        onHighlight: { range, color in
                            onHighlight(range, color, page.startOffset)
                        }
                    )
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, verticalPadding)
                    .tag(page.index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.25), value: currentPage)

            // Tap zones (don't interfere with text selection)
            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { if currentPage > 0 { withAnimation { currentPage -= 1 } } }
                    .frame(maxWidth: .infinity)
                    .allowsHitTesting(true)

                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { onTapCenter() }
                    .frame(width: 80)

                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { if currentPage < pages.count - 1 { withAnimation { currentPage += 1 } } }
                    .frame(maxWidth: .infinity)
                    .allowsHitTesting(true)
            }
            .allowsHitTesting(true)
        }
    }
}
