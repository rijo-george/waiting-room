import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.dismiss) var dismiss

    private let allThemes = ThemeName.allCases
    private var tc: ThemeColors { theme.colors }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 14) {
                    ForEach(allThemes) { t in
                        ThemeCard(themeName: t, isSelected: theme.current == t)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    theme.current = t
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                    }
                }
                .padding(20)
            }
            .background(tc.bg)
            .navigationTitle("Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Theme Card

struct ThemeCard: View {
    let themeName: ThemeName
    let isSelected: Bool

    private var tc: ThemeColors { themeName.colors }

    var body: some View {
        VStack(spacing: 8) {
            // Mini preview of two panels
            HStack(spacing: 3) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(tc.panelLeftBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(tc.panelLeftColor.opacity(0.6), lineWidth: 1)
                    )
                    .frame(height: 50)
                    .overlay(
                        VStack(spacing: 4) {
                            Circle().fill(Color(red: 0.4, green: 1.0, blue: 0.67)).frame(width: 6, height: 6)
                            Circle().fill(Color(red: 1.0, green: 0.85, blue: 0.3)).frame(width: 6, height: 6)
                        }
                    )
                RoundedRectangle(cornerRadius: 4)
                    .fill(tc.panelRightBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(tc.panelRightColor.opacity(0.6), lineWidth: 1)
                    )
                    .frame(height: 50)
                    .overlay(
                        VStack(spacing: 4) {
                            Circle().fill(Color(red: 1.0, green: 0.35, blue: 0.35)).frame(width: 6, height: 6)
                            Circle().fill(Color(red: 0.4, green: 1.0, blue: 0.67)).frame(width: 6, height: 6)
                        }
                    )
            }
            .padding(8)
            .background(tc.bg)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Label
            HStack(spacing: 5) {
                Image(systemName: themeName.icon)
                    .font(.system(size: 12))
                Text(themeName.displayName)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? tc.accent : .secondary)
        }
        .padding(10)
        .background(isSelected ? tc.accent.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? tc.accent : Color.gray.opacity(0.2), lineWidth: isSelected ? 2.5 : 1)
        )
    }
}
