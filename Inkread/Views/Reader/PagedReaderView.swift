import SwiftUI

struct PagedReaderView: View {
    let pages: [TextPage]
    @Binding var currentPage: Int
    let onTapCenter: () -> Void
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat

    var body: some View {
        ZStack {
            TabView(selection: $currentPage) {
                ForEach(pages, id: \.index) { page in
                    ReaderPageView(attributedText: page.attributedText)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.vertical, verticalPadding)
                        .tag(page.index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.25), value: currentPage)

            // Tap zones
            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if currentPage > 0 {
                            withAnimation { currentPage -= 1 }
                        }
                    }
                    .frame(maxWidth: .infinity)

                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { onTapCenter() }
                    .frame(width: 90)

                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if currentPage < pages.count - 1 {
                            withAnimation { currentPage += 1 }
                        }
                    }
                    .frame(maxWidth: .infinity)
            }
        }
    }
}
