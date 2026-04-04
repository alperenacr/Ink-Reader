import SwiftUI

// Phase 1 placeholder — full reading engine implemented in Phase 2
struct ReaderView: View {
    let book: Book
    @Environment(ThemeManager.self) private var theme

    var body: some View {
        ZStack {
            theme.currentTheme.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [coverColor(for: book.title).opacity(0.8), coverColor(for: book.title)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 120, height: 170)
                        .shadow(radius: 8)

                    Text(book.title.prefix(1).uppercased())
                        .font(.system(size: 48, weight: .semibold, design: .serif))
                        .foregroundStyle(.white.opacity(0.9))
                }

                VStack(spacing: 6) {
                    Text(book.title)
                        .font(.system(size: 20, weight: .semibold, design: .serif))
                        .foregroundStyle(theme.currentTheme.textColor)
                        .multilineTextAlignment(.center)

                    Text(book.author)
                        .font(.system(size: 14))
                        .foregroundStyle(theme.currentTheme.secondaryTextColor)
                }

                Text("Reading engine — Phase 2")
                    .font(.system(size: 13))
                    .foregroundStyle(theme.currentTheme.secondaryTextColor.opacity(0.5))
                    .padding(.top, 8)
            }
            .padding(.horizontal, 40)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.currentTheme.backgroundColor, for: .navigationBar)
        .preferredColorScheme(theme.currentTheme.colorScheme)
    }

    private func coverColor(for title: String) -> Color {
        let hash = abs(title.hashValue)
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.35, brightness: 0.60)
    }
}
