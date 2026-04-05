import SwiftUI

// MARK: - Theme definitions shared with TUI via ~/.waiting-room/config.json

struct ThemeColors {
    // Main backgrounds
    let bg: Color
    let surface: Color
    let headerBg: Color
    let statusBarBg: Color

    // Panel: waiting_for (left)
    let panelLeftColor: Color
    let panelLeftBg: Color

    // Panel: waiting_on_me (right)
    let panelRightColor: Color
    let panelRightBg: Color

    // Text
    let textPrimary: Color
    let textSecondary: Color

    // Accent / selection
    let accent: Color
    let selectedBg: Color
    let borderActive: Color
    let borderInactive: Color

    // Modal
    let modalBg: Color
    let modalTitle: Color
}

enum ThemeName: String, CaseIterable, Identifiable {
    case dark = "dark"
    case light = "light"
    case sunset = "sunset"
    case ocean = "ocean"
    case forest = "forest"
    case rose = "rose"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dark: return "Dark"
        case .light: return "Light"
        case .sunset: return "Sunset"
        case .ocean: return "Ocean"
        case .forest: return "Forest"
        case .rose: return "Rose"
        }
    }

    var icon: String {
        switch self {
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        case .sunset: return "sunset.fill"
        case .ocean: return "water.waves"
        case .forest: return "leaf.fill"
        case .rose: return "camera.macro"
        }
    }

    var colors: ThemeColors {
        switch self {
        case .dark:
            return ThemeColors(
                bg:              Color(r: 0.11, g: 0.11, b: 0.17),
                surface:         Color(r: 0.13, g: 0.13, b: 0.20),
                headerBg:        Color(r: 0.10, g: 0.10, b: 0.18),
                statusBarBg:     Color(r: 0.07, g: 0.07, b: 0.13),
                panelLeftColor:  Color(r: 0.40, g: 1.00, b: 0.67),
                panelLeftBg:     Color(r: 0.10, g: 0.23, b: 0.18),
                panelRightColor: Color(r: 1.00, g: 0.53, b: 0.80),
                panelRightBg:    Color(r: 0.23, g: 0.10, b: 0.18),
                textPrimary:     .white,
                textSecondary:   Color(r: 0.53, g: 0.53, b: 0.53),
                accent:          Color(r: 0.48, g: 0.41, b: 0.93),
                selectedBg:      Color(r: 0.17, g: 0.17, b: 0.30),
                borderActive:    Color(r: 0.48, g: 0.41, b: 0.93),
                borderInactive:  Color.gray.opacity(0.3),
                modalBg:         Color(r: 0.10, g: 0.10, b: 0.18),
                modalTitle:      Color(r: 0.67, g: 0.67, b: 1.00)
            )

        case .light:
            return ThemeColors(
                bg:              Color(r: 0.96, g: 0.96, b: 0.98),
                surface:         .white,
                headerBg:        Color(r: 0.94, g: 0.94, b: 0.97),
                statusBarBg:     Color(r: 0.92, g: 0.92, b: 0.95),
                panelLeftColor:  Color(r: 0.13, g: 0.55, b: 0.33),
                panelLeftBg:     Color(r: 0.90, g: 0.98, b: 0.93),
                panelRightColor: Color(r: 0.75, g: 0.20, b: 0.50),
                panelRightBg:    Color(r: 0.98, g: 0.90, b: 0.94),
                textPrimary:     Color(r: 0.13, g: 0.13, b: 0.17),
                textSecondary:   Color(r: 0.50, g: 0.50, b: 0.55),
                accent:          Color(r: 0.35, g: 0.30, b: 0.80),
                selectedBg:      Color(r: 0.90, g: 0.90, b: 0.98),
                borderActive:    Color(r: 0.35, g: 0.30, b: 0.80),
                borderInactive:  Color.gray.opacity(0.25),
                modalBg:         .white,
                modalTitle:      Color(r: 0.35, g: 0.30, b: 0.80)
            )

        case .sunset:
            return ThemeColors(
                bg:              Color(r: 0.15, g: 0.10, b: 0.10),
                surface:         Color(r: 0.18, g: 0.12, b: 0.12),
                headerBg:        Color(r: 0.20, g: 0.10, b: 0.08),
                statusBarBg:     Color(r: 0.12, g: 0.07, b: 0.07),
                panelLeftColor:  Color(r: 1.00, g: 0.75, b: 0.30),
                panelLeftBg:     Color(r: 0.25, g: 0.18, b: 0.08),
                panelRightColor: Color(r: 1.00, g: 0.45, b: 0.45),
                panelRightBg:    Color(r: 0.25, g: 0.10, b: 0.10),
                textPrimary:     Color(r: 1.00, g: 0.95, b: 0.90),
                textSecondary:   Color(r: 0.60, g: 0.50, b: 0.45),
                accent:          Color(r: 1.00, g: 0.55, b: 0.20),
                selectedBg:      Color(r: 0.30, g: 0.18, b: 0.12),
                borderActive:    Color(r: 1.00, g: 0.55, b: 0.20),
                borderInactive:  Color(r: 0.35, g: 0.25, b: 0.20),
                modalBg:         Color(r: 0.20, g: 0.12, b: 0.10),
                modalTitle:      Color(r: 1.00, g: 0.75, b: 0.40)
            )

        case .ocean:
            return ThemeColors(
                bg:              Color(r: 0.08, g: 0.12, b: 0.18),
                surface:         Color(r: 0.10, g: 0.15, b: 0.22),
                headerBg:        Color(r: 0.06, g: 0.10, b: 0.18),
                statusBarBg:     Color(r: 0.05, g: 0.08, b: 0.14),
                panelLeftColor:  Color(r: 0.30, g: 0.85, b: 0.95),
                panelLeftBg:     Color(r: 0.08, g: 0.18, b: 0.25),
                panelRightColor: Color(r: 0.60, g: 0.75, b: 1.00),
                panelRightBg:    Color(r: 0.12, g: 0.15, b: 0.28),
                textPrimary:     Color(r: 0.90, g: 0.95, b: 1.00),
                textSecondary:   Color(r: 0.45, g: 0.55, b: 0.65),
                accent:          Color(r: 0.20, g: 0.60, b: 0.90),
                selectedBg:      Color(r: 0.12, g: 0.20, b: 0.32),
                borderActive:    Color(r: 0.20, g: 0.60, b: 0.90),
                borderInactive:  Color(r: 0.20, g: 0.28, b: 0.38),
                modalBg:         Color(r: 0.08, g: 0.12, b: 0.20),
                modalTitle:      Color(r: 0.40, g: 0.80, b: 1.00)
            )

        case .forest:
            return ThemeColors(
                bg:              Color(r: 0.10, g: 0.14, b: 0.10),
                surface:         Color(r: 0.12, g: 0.18, b: 0.12),
                headerBg:        Color(r: 0.08, g: 0.14, b: 0.08),
                statusBarBg:     Color(r: 0.06, g: 0.10, b: 0.06),
                panelLeftColor:  Color(r: 0.55, g: 0.95, b: 0.55),
                panelLeftBg:     Color(r: 0.10, g: 0.22, b: 0.10),
                panelRightColor: Color(r: 0.90, g: 0.80, b: 0.50),
                panelRightBg:    Color(r: 0.20, g: 0.18, b: 0.08),
                textPrimary:     Color(r: 0.92, g: 0.96, b: 0.90),
                textSecondary:   Color(r: 0.50, g: 0.58, b: 0.48),
                accent:          Color(r: 0.40, g: 0.75, b: 0.40),
                selectedBg:      Color(r: 0.15, g: 0.25, b: 0.15),
                borderActive:    Color(r: 0.40, g: 0.75, b: 0.40),
                borderInactive:  Color(r: 0.22, g: 0.30, b: 0.22),
                modalBg:         Color(r: 0.10, g: 0.16, b: 0.10),
                modalTitle:      Color(r: 0.55, g: 0.90, b: 0.55)
            )

        case .rose:
            return ThemeColors(
                bg:              Color(r: 0.14, g: 0.10, b: 0.14),
                surface:         Color(r: 0.18, g: 0.12, b: 0.18),
                headerBg:        Color(r: 0.16, g: 0.08, b: 0.16),
                statusBarBg:     Color(r: 0.10, g: 0.06, b: 0.10),
                panelLeftColor:  Color(r: 1.00, g: 0.65, b: 0.85),
                panelLeftBg:     Color(r: 0.22, g: 0.10, b: 0.18),
                panelRightColor: Color(r: 0.80, g: 0.60, b: 1.00),
                panelRightBg:    Color(r: 0.18, g: 0.10, b: 0.24),
                textPrimary:     Color(r: 0.96, g: 0.92, b: 0.96),
                textSecondary:   Color(r: 0.58, g: 0.48, b: 0.55),
                accent:          Color(r: 0.85, g: 0.40, b: 0.65),
                selectedBg:      Color(r: 0.25, g: 0.15, b: 0.25),
                borderActive:    Color(r: 0.85, g: 0.40, b: 0.65),
                borderInactive:  Color(r: 0.30, g: 0.22, b: 0.30),
                modalBg:         Color(r: 0.16, g: 0.10, b: 0.16),
                modalTitle:      Color(r: 1.00, g: 0.60, b: 0.85)
            )
        }
    }
}

// MARK: - Color convenience

extension Color {
    init(r: Double, g: Double, b: Double) {
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Config persistence (shared with TUI)

struct AppConfig: Codable {
    var theme: String

    static var configFile: URL {
        StorageLocation.resolve().appendingPathComponent("config.json")
    }

    static func load() -> AppConfig {
        guard let raw = try? Data(contentsOf: configFile),
              let config = try? JSONDecoder().decode(AppConfig.self, from: raw)
        else { return AppConfig(theme: "dark") }
        return config
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let raw = try? encoder.encode(self) else { return }
        try? raw.write(to: AppConfig.configFile, options: .atomic)
    }
}

// MARK: - Theme manager

class ThemeManager: ObservableObject {
    @Published var current: ThemeName {
        didSet {
            var config = AppConfig.load()
            config.theme = current.rawValue
            config.save()
        }
    }

    var colors: ThemeColors { current.colors }

    init() {
        let config = AppConfig.load()
        self.current = ThemeName(rawValue: config.theme) ?? .dark
    }
}
