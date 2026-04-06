import Foundation
import SwiftUI

// MARK: - Store (reads/writes same JSON format as macOS app & TUI)

class WaitingRoomStore: ObservableObject {
    @Published var data: WaitingData

    private let dataFile: URL
    private let configFile: URL

    init() {
        let dir = Self.storageDirectory()
        dataFile = dir.appendingPathComponent("data.json")
        configFile = dir.appendingPathComponent("config.json")
        data = WaitingData(waiting_for: [], waiting_on_me: [], history: [])
        load()
    }

    // MARK: - Storage resolution

    /// Resolves the best storage directory.
    /// Prefers iCloud ubiquity container for cross-device sync, falls back to Documents.
    static func storageDirectory() -> URL {
        let fm = FileManager.default

        // Try iCloud container first — this syncs with macOS app
        if let iCloudURL = fm.url(forUbiquityContainerIdentifier: nil) {
            let docsURL = iCloudURL.appendingPathComponent("Documents").appendingPathComponent("WaitingRoom")
            try? fm.createDirectory(at: docsURL, withIntermediateDirectories: true)
            return docsURL
        }

        // Fall back to app group container (for potential widget sharing)
        if let groupURL = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.com.waitingroom.app") {
            let dir = groupURL.appendingPathComponent("WaitingRoom")
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
            return dir
        }

        // Last resort: Documents directory
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("WaitingRoom")
        try? fm.createDirectory(at: docs, withIntermediateDirectories: true)
        return docs
    }

    // MARK: - Load / Save

    func load() {
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

    // MARK: - Actions

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

    func deleteItem(direction: Direction, item: WaitingItem) {
        switch direction {
        case .waitingFor: data.waiting_for.removeAll { $0.id == item.id }
        case .waitingOnMe: data.waiting_on_me.removeAll { $0.id == item.id }
        }
        save()
    }

    func items(for direction: Direction) -> [WaitingItem] {
        switch direction {
        case .waitingFor: return data.waiting_for
        case .waitingOnMe: return data.waiting_on_me
        }
    }

    // MARK: - Helpers

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

// MARK: - Config persistence (shared with macOS & TUI via config.json)

struct AppConfig: Codable {
    var theme: String

    static func configFile() -> URL {
        WaitingRoomStore.storageDirectory().appendingPathComponent("config.json")
    }

    static func load() -> AppConfig {
        guard let raw = try? Data(contentsOf: configFile()),
              let config = try? JSONDecoder().decode(AppConfig.self, from: raw)
        else { return AppConfig(theme: "dark") }
        return config
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let raw = try? encoder.encode(self) else { return }
        try? raw.write(to: AppConfig.configFile(), options: .atomic)
    }
}
