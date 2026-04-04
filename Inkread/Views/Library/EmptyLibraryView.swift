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
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(theme.currentTheme.textColor)

                Text("Import EPUB or PDF files\nto start reading")
                    .font(.system(size: 15))
                    .foregroundStyle(theme.currentTheme.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button(action: onImport) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Import Book")
                        .font(.system(size: 16, weight: .semibold))
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
