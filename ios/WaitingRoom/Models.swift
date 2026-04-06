import Foundation

// MARK: - Data model (matches ~/.waiting-room/data.json — shared with macOS & TUI)

struct Nudge: Codable, Identifiable, Hashable {
    var at: String
    var note: String
    var id: String { at }
}

struct WaitingItem: Codable, Identifiable, Hashable {
    var id: String
    var who: String
    var what: String
    var since: String
    var expected: String
    var nudges: [Nudge]
    var note: String

    // Only present on resolved items
    var resolved_at: String?
    var direction: String?
    var duration_days: Int?

    var ageDays: Int {
        guard let sinceDate = ISO8601Flexible.date(from: since) else { return 0 }
        return Calendar.current.dateComponents([.day], from: sinceDate, to: Date()).day ?? 0
    }

    var expectedDisplay: String {
        guard !expected.isEmpty else { return "" }
        if let d = ISO8601Flexible.date(from: expected) {
            let fmt = DateFormatter()
            fmt.dateFormat = "MMM d"
            return fmt.string(from: d)
        }
        return expected
    }

    var sinceDisplay: String {
        guard let d = ISO8601Flexible.date(from: since) else { return "-" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: d)
    }

    var resolvedDisplay: String {
        guard let r = resolved_at, let d = ISO8601Flexible.date(from: r) else { return "-" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: d)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: WaitingItem, rhs: WaitingItem) -> Bool {
        lhs.id == rhs.id
    }
}

struct WaitingData: Codable {
    var waiting_for: [WaitingItem]
    var waiting_on_me: [WaitingItem]
    var history: [WaitingItem]
}

// MARK: - Direction enum

enum Direction: String, CaseIterable {
    case waitingFor = "waiting_for"
    case waitingOnMe = "waiting_on_me"

    var title: String {
        switch self {
        case .waitingFor: return "I'M WAITING FOR..."
        case .waitingOnMe: return "WAITING FOR ME..."
        }
    }

    var shortTitle: String {
        switch self {
        case .waitingFor: return "Waiting For"
        case .waitingOnMe: return "Waiting On Me"
        }
    }

    var icon: String {
        switch self {
        case .waitingFor: return "arrow.right"
        case .waitingOnMe: return "arrow.left"
        }
    }

    var tabIcon: String {
        switch self {
        case .waitingFor: return "arrow.right.circle.fill"
        case .waitingOnMe: return "arrow.left.circle.fill"
        }
    }
}

// MARK: - Age helpers

func ageColor(days: Int, forLightBg: Bool = false) -> (r: Double, g: Double, b: Double) {
    if forLightBg {
        if days < 3 { return (0.15, 0.60, 0.35) }
        if days < 7 { return (0.70, 0.55, 0.05) }
        return (0.80, 0.20, 0.20)
    }
    if days < 3 { return (0.4, 1.0, 0.67) }
    if days < 7 { return (1.0, 0.85, 0.3) }
    return (1.0, 0.35, 0.35)
}

// MARK: - Flexible ISO parser (handles Python isoformat, full ISO8601, date-only)

enum ISO8601Flexible {
    private static let fullFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let basicFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let dateOnly: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    static func date(from string: String) -> Date? {
        let cleaned = string.count > 26 ? String(string.prefix(26)) : string
        if let d = fullFormatter.date(from: cleaned + "+00:00") { return d }
        if let d = fullFormatter.date(from: string + "+00:00") { return d }
        if let d = basicFormatter.date(from: string + "+00:00") { return d }
        if let d = basicFormatter.date(from: string) { return d }
        if let d = dateOnly.date(from: string) { return d }
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        for fmt in ["yyyy-MM-dd'T'HH:mm:ss.SSSSSS", "yyyy-MM-dd'T'HH:mm:ss.SSS", "yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd"] {
            df.dateFormat = fmt
            if let d = df.date(from: string) { return d }
        }
        return nil
    }
}
