import SwiftUI

struct TOCView: View {
    let toc: [TOCEntry]
    let chapterOffsets: [Int]     // page index where each chapter starts
    let currentPage: Int
    let onSelect: (Int) -> Void   // page index to jump to
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var theme

    var body: some View {
        NavigationStack {
            ZStack {
                theme.currentTheme.backgroundColor.ignoresSafeArea()

                if toc.isEmpty {
                    Text("No table of contents available")
                        .font(.system(size: 15))
                        .foregroundStyle(theme.currentTheme.secondaryTextColor)
                } else {
                    List(toc) { entry in
                        Button {
                            let pageIdx = chapterOffsets.indices.contains(entry.chapterIndex)
                                ? chapterOffsets[entry.chapterIndex]
                                : 0
                            onSelect(pageIdx)
                            dismiss()
                        } label: {
                            HStack(spacing: 0) {
                                // Indentation for sub-items
                                if entry.level > 0 {
                                    Rectangle()
                                        .fill(theme.currentTheme.dividerColor)
                                        .frame(width: 2)
                                        .padding(.leading, CGFloat(entry.level) * 16)
                                        .padding(.trailing, 12)
                                }

                                Text(entry.title)
                                    .font(.system(
                                        size: entry.level == 0 ? 15 : 14,
                                        weight: entry.level == 0 ? .medium : .regular,
                                        design: .serif
                                    ))
                                    .foregroundStyle(theme.currentTheme.textColor)
                                    .lineLimit(2)

                                Spacer()

                                if chapterOffsets.indices.contains(entry.chapterIndex),
                                   currentPage >= chapterOffsets[entry.chapterIndex] {
                                    let nextIdx = entry.chapterIndex + 1
                                    let isActive = nextIdx >= chapterOffsets.count ||
                                        currentPage < chapterOffsets[nextIdx]
                                    if isActive {
                                        Circle()
                                            .fill(theme.currentTheme.textColor.opacity(0.5))
                                            .frame(width: 6, height: 6)
                                    }
                                }
                            }
                        }
                        .listRowBackground(theme.currentTheme.backgroundColor)
                        .listRowSeparatorTint(theme.currentTheme.dividerColor)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Contents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.currentTheme.backgroundColor, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(theme.currentTheme.textColor)
                }
            }
        }
        .preferredColorScheme(theme.currentTheme.colorScheme)
    }
}
