import Foundation
import SwiftUI

// MARK: - Store (reads/writes same JSON format as macOS app & TUI)

class WaitingRoomStore: ObservableObject {
    @Published var data: WaitingData

    private let dataFile: URL
    private let configFile: URL
    private var fileMonitor: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private var metadataQuery: NSMetadataQuery?

    init() {
        let dir = Self.storageDirectory()
        dataFile = dir.appendingPathComponent("data.json")
        configFile = dir.appendingPathComponent("config.json")
        data = WaitingData(waiting_for: [], waiting_on_me: [], history: [])
        coordinatedLoad()
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Storage resolution

    /// Resolves the best storage directory.
    /// Prefers iCloud ubiquity container for cross-device sync, falls back to Documents.
    static func storageDirectory() -> URL {
        let fm = FileManager.default

        // Try iCloud container first — this syncs with macOS app
        if let iCloudURL = fm.url(forUbiquityContainerIdentifier: "iCloud.com.rijo.waitingroom") {
            let docsURL = iCloudURL.appendingPathComponent("Documents")
            try? fm.createDirectory(at: docsURL, withIntermediateDirectories: true)
            return docsURL
        }

        // Fall back to app group container (for potential widget sharing)
        if let groupURL = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.com.rijo.waitingroom") {
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

    // MARK: - Coordinated Load / Save

    func load() { coordinatedLoad() }

    /// Reads from disk and merges with in-memory state so local changes aren't lost.
    /// On first load (empty in-memory), this is effectively a full replace.
    /// On subsequent loads (file monitor), this preserves items added locally
    /// that haven't synced to the other device yet.
    func coordinatedLoad() {
        let coordinator = NSFileCoordinator()
        var coordError: NSError?
        var needsSave = false
        coordinator.coordinate(readingItemAt: dataFile, options: [], error: &coordError) { url in
            guard let raw = try? Data(contentsOf: url),
                  let disk = try? JSONDecoder().decode(WaitingData.self, from: raw)
            else { return }
            let merged = Self.merge(local: self.data, remote: disk)
            // If merge produced something different from disk, we need to save back
            needsSave = !Self.dataEqual(merged, disk)
            DispatchQueue.main.async {
                self.data = merged
            }
        }
        if needsSave { save() }
    }

    func save() {
        let coordinator = NSFileCoordinator()
        var coordError: NSError?

        coordinator.coordinate(readingItemAt: dataFile, options: [],
                               writingItemAt: dataFile, options: .forReplacing,
                               error: &coordError) { readURL, writeURL in
            // Read latest from disk and merge to avoid overwriting remote changes
            var merged = self.data
            if let raw = try? Data(contentsOf: readURL),
               let disk = try? JSONDecoder().decode(WaitingData.self, from: raw) {
                merged = Self.merge(local: self.data, remote: disk)
            }

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            guard let raw = try? encoder.encode(merged) else { return }
            try? raw.write(to: writeURL, options: .atomic)

            DispatchQueue.main.async {
                self.data = merged
            }
        }
    }

    private static func dataEqual(_ a: WaitingData, _ b: WaitingData) -> Bool {
        let ids = { (d: WaitingData) in
            Set(d.waiting_for.map(\.id) + d.waiting_on_me.map(\.id) + d.history.map(\.id))
        }
        return ids(a) == ids(b)
    }

    // MARK: - Merge logic (union by item ID)

    private static func merge(local: WaitingData, remote: WaitingData) -> WaitingData {
        // Merge history first — union of all resolved items
        let mergedHistory = mergeItems(local: local.history, remote: remote.history)
        let historyIDs = Set(mergedHistory.map(\.id))

        // Merge active lists, excluding anything that's been resolved (in history)
        return WaitingData(
            waiting_for: mergeItems(local: local.waiting_for, remote: remote.waiting_for)
                .filter { !historyIDs.contains($0.id) },
            waiting_on_me: mergeItems(local: local.waiting_on_me, remote: remote.waiting_on_me)
                .filter { !historyIDs.contains($0.id) },
            history: mergedHistory
        )
    }

    private static func mergeItems(local: [WaitingItem], remote: [WaitingItem]) -> [WaitingItem] {
        var byID: [String: WaitingItem] = [:]
        for item in remote { byID[item.id] = item }
        for item in local { byID[item.id] = item }
        var result: [WaitingItem] = []
        var seen = Set<String>()
        for item in local {
            if seen.insert(item.id).inserted { result.append(byID[item.id]!) }
        }
        for item in remote {
            if seen.insert(item.id).inserted { result.append(byID[item.id]!) }
        }
        return result
    }

    // MARK: - File monitoring

    private func startMonitoring() {
        // Use NSMetadataQuery for iCloud file changes (handles offline→online)
        let query = NSMetadataQuery()
        query.predicate = NSPredicate(format: "%K == %@", NSMetadataItemFSNameKey, "data.json")
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        NotificationCenter.default.addObserver(
            self, selector: #selector(fileDidChange),
            name: .NSMetadataQueryDidUpdate, object: query)
        query.start()
        metadataQuery = query

        // Also monitor via GCD for local/direct changes
        startFileMonitor()

        // Reload when app returns to foreground (covers offline→online)
        NotificationCenter.default.addObserver(
            self, selector: #selector(fileDidChange),
            name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    private func startFileMonitor() {
        // Cancel existing monitor if any
        fileMonitor?.cancel()
        fileMonitor = nil

        let fd = open(dataFile.path, O_EVTONLY)
        guard fd >= 0 else { return }
        fileDescriptor = fd
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd, eventMask: [.write, .rename], queue: .main)
        source.setEventHandler { [weak self] in
            guard let self else { return }
            self.coordinatedLoad()
            // Re-establish monitor on rename (iCloud replaces the file)
            self.startFileMonitor()
        }
        source.setCancelHandler { close(fd) }
        source.resume()
        fileMonitor = source
    }

    private func stopMonitoring() {
        fileMonitor?.cancel()
        fileMonitor = nil
        metadataQuery?.stop()
        metadataQuery = nil
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func fileDidChange() {
        coordinatedLoad()
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
