import SwiftUI

struct BookCardView: View {
    let book: Book
    @Environment(ThemeManager.self) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            coverView
                .frame(height: 160)

            VStack(alignment: .leading, spacing: 3) {
                Text(book.title)
                    .font(.system(.caption, design: .serif).weight(.medium))
                    .foregroundStyle(theme.currentTheme.textColor)
                    .lineLimit(2)

                Text(book.author)
                    .font(.caption2)
                    .foregroundStyle(theme.currentTheme.secondaryTextColor)
                    .lineLimit(1)
            }

            if book.hasStarted {
                progressBar
            }
        }
    }

    @ViewBuilder
    private var coverView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(coverGradient)

            if let data = book.coverImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                VStack(spacing: 10) {
                    Text(book.title.prefix(1).uppercased())
                        .font(.system(size: 36, weight: .semibold, design: .serif))
                        .foregroundStyle(.white.opacity(0.9))

                    Image(systemName: book.fileFormat == .pdf ? "doc.fill" : "book.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(theme.currentTheme.dividerColor)
                    .frame(height: 3)

                RoundedRectangle(cornerRadius: 2)
                    .fill(theme.currentTheme.textColor.opacity(0.5))
                    .frame(width: geo.size.width * book.progress, height: 3)
            }
        }
        .frame(height: 3)
    }

    private var coverGradient: LinearGradient {
        let hash = abs(book.title.hashValue)
        let hue = Double(hash % 360) / 360.0
        let base = Color(hue: hue, saturation: 0.35, brightness: 0.60)
        let light = Color(hue: hue, saturation: 0.25, brightness: 0.75)
        return LinearGradient(colors: [light, base], startPoint: .top, endPoint: .bottom)
    }
}
