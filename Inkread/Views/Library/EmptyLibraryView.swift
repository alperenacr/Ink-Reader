import SwiftUI

struct EmptyLibraryView: View {
    let onImport: () -> Void
    @Environment(ThemeManager.self) private var theme

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "books.vertical")
                .font(.system(size: 72, weight: .thin))
                .foregroundStyle(theme.currentTheme.secondaryTextColor.opacity(0.4))

            VStack(spacing: 10) {
                Text("Your library is empty")
                    .font(.system(.title3, design: .serif).weight(.semibold))
                    .foregroundStyle(theme.currentTheme.textColor)

                Text("Import EPUB or PDF files\nto start reading")
                    .font(.body)
                    .foregroundStyle(theme.currentTheme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button(action: onImport) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(.subheadline, design: .default).weight(.semibold))
                    Text("Import Book")
                        .font(.headline)
                }
                .foregroundStyle(theme.currentTheme.backgroundColor)
                .padding(.horizontal, 32)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(theme.currentTheme.textColor)
                )
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 48)
    }
}
