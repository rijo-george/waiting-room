import Foundation

// MARK: - Data model (matches ~/.waiting-room/data.json)

struct Nudge: Codable, Identifiable {
    var at: String
    var note: String
    var id: String { at }
}

struct WaitingItem: Codable, Identifiable {
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
}

struct WaitingData: Codable {
    var waiting_for: [WaitingItem]
    var waiting_on_me: [WaitingItem]
    var history: [WaitingItem]
}

// MARK: - Flexible ISO parser (handles both full ISO8601 and date-only)

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
        // Python isoformat uses "T" separator without "Z", e.g. "2026-04-05T12:31:42.357149"
        // Try replacing microseconds and adding timezone
        let cleaned = string.count > 26 ? String(string.prefix(26)) : string
        if let d = fullFormatter.date(from: cleaned + "+00:00") { return d }
        if let d = fullFormatter.date(from: string + "+00:00") { return d }
        if let d = basicFormatter.date(from: string + "+00:00") { return d }
        if let d = basicFormatter.date(from: string) { return d }
        if let d = dateOnly.date(from: string) { return d }
        // Try Python-style isoformat directly
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        for fmt in ["yyyy-MM-dd'T'HH:mm:ss.SSSSSS", "yyyy-MM-dd'T'HH:mm:ss.SSS", "yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd"] {
            df.dateFormat = fmt
            if let d = df.date(from: string) { return d }
        }
        return nil
    }
}

// MARK: - Storage location (iCloud Drive with local fallback)

enum StorageLocation {
    /// iCloud Drive path — syncs across Macs automatically
    static let iCloudDir: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home
            .appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs")
            .appendingPathComponent("WaitingRoom")
    }()

    /// Legacy local path
    static let localDir: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".waiting-room")
    }()

    /// Resolve the best storage directory:
    /// 1. If iCloud Drive exists, use it and symlink ~/.waiting-room -> iCloud for TUI compat
    /// 2. Otherwise fall back to ~/.waiting-room
    static func resolve() -> URL {
        let fm = FileManager.default

        // Check if iCloud Drive root exists
        let iCloudRoot = fm.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs")
        let iCloudAvailable = fm.fileExists(atPath: iCloudRoot.path)

        if iCloudAvailable {
            // Create the WaitingRoom folder in iCloud Drive
            try? fm.createDirectory(at: iCloudDir, withIntermediateDirectories: true)

            // Migrate existing local data to iCloud if needed
            migrateToICloud(fm: fm)

            // Create/update symlink so TUI can find data at ~/.waiting-room
            setupSymlink(fm: fm)

            return iCloudDir
        }

        // Fallback to local
        try? fm.createDirectory(at: localDir, withIntermediateDirectories: true)
        return localDir
    }

    /// Move existing ~/.waiting-room/*.json files to iCloud (one-time migration)
    private static func migrateToICloud(fm: FileManager) {
        let localPath = localDir.path

        // Only migrate if ~/.waiting-room is a real directory (not already a symlink)
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: localPath, isDirectory: &isDir), isDir.boolValue else { return }

        // Check it's not already a symlink
        let attrs = try? fm.attributesOfItem(atPath: localPath)
        if attrs?[.type] as? FileAttributeType == .typeSymbolicLink { return }

        // Move data.json and config.json if they exist and iCloud versions don't
        for file in ["data.json", "config.json"] {
            let src = localDir.appendingPathComponent(file)
            let dst = iCloudDir.appendingPathComponent(file)
            if fm.fileExists(atPath: src.path) && !fm.fileExists(atPath: dst.path) {
                try? fm.copyItem(at: src, to: dst)
            }
        }

        // Remove old directory so we can replace with symlink
        // Rename to .waiting-room-backup first for safety
        let backup = fm.homeDirectoryForCurrentUser.appendingPathComponent(".waiting-room-backup")
        try? fm.removeItem(at: backup)
        try? fm.moveItem(at: localDir, to: backup)
    }

    /// Symlink ~/.waiting-room -> iCloud dir so TUI works transparently
    private static func setupSymlink(fm: FileManager) {
        let linkPath = localDir.path
        let targetPath = iCloudDir.path

        // Already a correct symlink?
        if let dest = try? fm.destinationOfSymbolicLink(atPath: linkPath), dest == targetPath {
            return
        }

        // Remove whatever's there (file, broken symlink, etc) — but not a real directory with data
        var isDir: ObjCBool = false
        if fm.fileExists(atPath: linkPath, isDirectory: &isDir) {
            let attrs = try? fm.attributesOfItem(atPath: linkPath)
            if attrs?[.type] as? FileAttributeType == .typeSymbolicLink {
                try? fm.removeItem(atPath: linkPath)
            }
            // If it's a real directory, migrateToICloud should have handled it
        }

        // Create symlink
        if !fm.fileExists(atPath: linkPath) {
            try? fm.createSymbolicLink(atPath: linkPath, withDestinationPath: targetPath)
        }
    }
}

// MARK: - Store

class WaitingRoomStore: ObservableObject {
    @Published var data: WaitingData

    private let dataDir: URL
    private let dataFile: URL
    private let configFile: URL

    init() {
        dataDir = StorageLocation.resolve()
        dataFile = dataDir.appendingPathComponent("data.json")
        configFile = dataDir.appendingPathComponent("config.json")
        data = WaitingData(waiting_for: [], waiting_on_me: [], history: [])
        load()
    }

    func load() {
        try? FileManager.default.createDirectory(at: dataDir, withIntermediateDirectories: true)
        guard let raw = try? Data(contentsOf: dataFile),
              let decoded = try? JSONDecoder().decode(WaitingData.self, from: raw)
        else { return }
        data = decoded
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let raw = try? encoder.encode(data) else { return }
        try? raw.write(to: dataFile, options: .atomic)
    }

    // MARK: Actions

    func addItem(direction: Direction, who: String, what: String, expected: String, note: String) {
        let item = WaitingItem(
            id: UUID().uuidString,
            who: who,
            what: what,
            since: pythonISO(),
            expected: parseExpected(expected),
            nudges: [],
            note: note
        )
        switch direction {
        case .waitingFor: data.waiting_for.append(item)
        case .waitingOnMe: data.waiting_on_me.append(item)
        }
        save()
    }

    func resolveItem(direction: Direction, item: WaitingItem) {
        var resolved = item
        resolved.resolved_at = pythonISO()
        resolved.direction = direction.rawValue
        resolved.duration_days = item.ageDays
        data.history.append(resolved)

        switch direction {
        case .waitingFor: data.waiting_for.removeAll { $0.id == item.id }
        case .waitingOnMe: data.waiting_on_me.removeAll { $0.id == item.id }
        }
        save()
    }

    func nudgeItem(direction: Direction, item: WaitingItem, note: String) {
        let nudge = Nudge(at: pythonISO(), note: note.isEmpty ? "nudged" : note)
        let update = { (list: inout [WaitingItem]) in
            if let idx = list.firstIndex(where: { $0.id == item.id }) {
                list[idx].nudges.append(nudge)
            }
        }
        switch direction {
        case .waitingFor: update(&data.waiting_for)
        case .waitingOnMe: update(&data.waiting_on_me)
        }
        save()
    }

    func items(for direction: Direction) -> [WaitingItem] {
        switch direction {
        case .waitingFor: return data.waiting_for
        case .waitingOnMe: return data.waiting_on_me
        }
    }

    // MARK: Helpers

    private func pythonISO() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        return f.string(from: Date())
    }

    private func parseExpected(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "" }
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        for fmt in ["yyyy-MM-dd", "MMM d", "MMMM d", "MMM d, yyyy", "MMMM d, yyyy", "d MMM", "d MMMM"] {
            df.dateFormat = fmt
            if var d = df.date(from: trimmed) {
                var comps = Calendar.current.dateComponents([.year, .month, .day], from: d)
                if (comps.year ?? 0) < 2000 {
                    comps.year = Calendar.current.component(.year, from: Date())
                    d = Calendar.current.date(from: comps) ?? d
                }
                let out = DateFormatter()
                out.locale = Locale(identifier: "en_US_POSIX")
                out.dateFormat = "yyyy-MM-dd"
                return out.string(from: d)
            }
        }
        return trimmed
    }
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

    var icon: String {
        switch self {
        case .waitingFor: return "arrow.right"
        case .waitingOnMe: return "arrow.left"
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

func ageEmoji(days: Int) -> String {
    if days < 3 { return "green" }
    if days < 7 { return "yellow" }
    return "red"
}
