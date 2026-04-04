import SwiftUI

struct SettingsView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(SettingsManager.self) private var settings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            ZStack {
                theme.currentTheme.backgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 36) {
                        themeSection
                        divider
                        fontSection
                        divider
                        fontSizeSection
                        divider
                        lineSpacingSection
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.currentTheme.backgroundColor, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.currentTheme.textColor)
                }
            }
        }
        .preferredColorScheme(theme.currentTheme.colorScheme)
    }

    // MARK: - Sections

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Theme")

            HStack(spacing: 10) {
                ForEach(AppTheme.allCases) { appTheme in
                    ThemeOptionButton(
                        appTheme: appTheme,
                        isSelected: theme.currentTheme == appTheme
                    ) {
                        theme.currentTheme = appTheme
                    }
                }
            }
        }
    }

    private var fontSection: some View {
        @Bindable var settings = settings
        return VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Font")

            HStack(spacing: 12) {
                ForEach(ReadingFont.allCases) { font in
                    FontOptionButton(
                        readingFont: font,
                        isSelected: settings.readingFont == font
                    ) {
                        settings.readingFont = font
                    }
                }
            }
        }
    }

    private var fontSizeSection: some View {
        @Bindable var settings = settings
        return VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Font Size")

            HStack(spacing: 14) {
                Text("A")
                    .font(.system(size: 13))
                    .foregroundStyle(theme.currentTheme.secondaryTextColor)

                Slider(value: $settings.fontSize, in: 13...26, step: 1)
                    .tint(theme.currentTheme.textColor)

                Text("A")
                    .font(.system(size: 22))
                    .foregroundStyle(theme.currentTheme.secondaryTextColor)
            }

            Text("The quick brown fox jumps over the lazy dog.")
                .font(settings.readingFont.font(size: settings.fontSize))
                .foregroundStyle(theme.currentTheme.textColor)
                .lineSpacing(settings.lineSpacing.value)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(theme.currentTheme.cardColor)
                )
        }
    }

    private var lineSpacingSection: some View {
        @Bindable var settings = settings
        return VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Line Spacing")

            HStack(spacing: 10) {
                ForEach(LineSpacing.allCases) { spacing in
                    LineSpacingOptionButton(
                        spacing: spacing,
                        isSelected: settings.lineSpacing == spacing
                    ) {
                        settings.lineSpacing = spacing
                    }
                }
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(theme.currentTheme.dividerColor)
            .frame(height: 0.5)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(theme.currentTheme.secondaryTextColor)
            .kerning(0.8)
    }
}

// MARK: - Option Buttons

private struct ThemeOptionButton: View {
    let appTheme: AppTheme
    let isSelected: Bool
    let action: () -> Void
    @Environment(ThemeManager.self) private var theme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(appTheme.backgroundColor)
                        .frame(height: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    isSelected ? theme.currentTheme.textColor : theme.currentTheme.dividerColor,
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )

                    Image(systemName: appTheme.iconName)
                        .font(.system(size: 18))
                        .foregroundStyle(appTheme.textColor)
                }

                Text(appTheme.rawValue)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(theme.currentTheme.textColor)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

private struct FontOptionButton: View {
    let readingFont: ReadingFont
    let isSelected: Bool
    let action: () -> Void
    @Environment(ThemeManager.self) private var theme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text("Aa")
                    .font(readingFont.font(size: 24))
                    .foregroundStyle(theme.currentTheme.textColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(theme.currentTheme.cardColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        isSelected ? theme.currentTheme.textColor : theme.currentTheme.dividerColor,
                                        lineWidth: isSelected ? 2 : 1
                                    )
                            )
                    )

                Text(readingFont.rawValue)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(theme.currentTheme.textColor)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

private struct LineSpacingOptionButton: View {
    let spacing: LineSpacing
    let isSelected: Bool
    let action: () -> Void
    @Environment(ThemeManager.self) private var theme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                VStack(spacing: CGFloat(spacing == .compact ? 1 : spacing == .normal ? 3 : spacing == .relaxed ? 5 : 7)) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(theme.currentTheme.secondaryTextColor)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(theme.currentTheme.cardColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    isSelected ? theme.currentTheme.textColor : theme.currentTheme.dividerColor,
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                )

                Text(spacing.rawValue)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(theme.currentTheme.textColor)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}
