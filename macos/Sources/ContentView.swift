import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: WaitingRoomStore
    @EnvironmentObject var theme: ThemeManager
    @State private var activePanel: Direction = .waitingFor
    @State private var selectedItemID: String?
    @State private var showingAddSheet = false
    @State private var showingHistory = false
    @State private var showingNudge = false
    @State private var showingThemePicker = false

    @State private var itemToResolve: WaitingItem?
    @State private var resolvedItemForReceipt: WaitingItem?
    @State private var nudgeItem: WaitingItem?
    @State private var resolvedDirection: Direction = .waitingFor
    @StateObject private var clipboard = ClipboardRadar()
    @State private var radarSuggestion: ClipboardRadar.ClipboardSuggestion?

    private var tc: ThemeColors { theme.colors }

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Image(systemName: "door.left.hand.open")
                    .font(.title2)
                Text("The Waiting Room")
                    .font(.title2.bold())
                Spacer()
                statusText
                    .font(.caption)
                    .foregroundColor(tc.textSecondary)

                // Theme picker button
                Button(action: { showingThemePicker = true }) {
                    Image(systemName: theme.current.icon)
                        .font(.system(size: 14))
                        .padding(6)
                        .background(tc.accent.opacity(0.2))
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .help("Change theme [T]")
            }
            .foregroundColor(tc.textPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(tc.headerBg)

            // Clipboard Radar banner
            if clipboard.suggestedItem != nil {
                ClipboardBanner(
                    suggestion: clipboard.suggestedItem!,
                    onAdd: {
                        radarSuggestion = clipboard.suggestedItem
                        clipboard.dismiss()
                        showingAddSheet = true
                    },
                    onDismiss: { clipboard.dismiss() }
                )
                .environmentObject(theme)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Two panels
            HStack(spacing: 1) {
                PanelView(
                    direction: .waitingFor,
                    isActive: activePanel == .waitingFor,
                    selectedItemID: $selectedItemID,
                    onActivate: { activePanel = .waitingFor }
                )

                PanelView(
                    direction: .waitingOnMe,
                    isActive: activePanel == .waitingOnMe,
                    selectedItemID: $selectedItemID,
                    onActivate: { activePanel = .waitingOnMe }
                )
            }
            .padding(12)

            // Bottom toolbar
            HStack(spacing: 16) {
                toolbarButton("Add", icon: "plus.circle.fill", key: "A") { showingAddSheet = true }
                toolbarButton("Resolve", icon: "checkmark.circle.fill", key: "R") { promptResolve() }
                toolbarButton("Nudge", icon: "bell.circle.fill", key: "N") { promptNudge() }
                toolbarButton("History", icon: "clock.circle.fill", key: "H") { showingHistory = true }
                toolbarButton("Theme", icon: "paintpalette.fill", key: "T") { showingThemePicker = true }

                Spacer()
                toolbarButton("Switch", icon: "arrow.left.arrow.right", key: "Tab") { switchPanel() }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(tc.statusBarBg)
        }
        .focusable()
        .onKeyPress(.tab) { switchPanel(); return .handled }
        .onKeyPress(characters: CharacterSet(charactersIn: "aA")) { _ in showingAddSheet = true; return .handled }
        .onKeyPress(characters: CharacterSet(charactersIn: "rR")) { _ in promptResolve(); return .handled }
        .onKeyPress(characters: CharacterSet(charactersIn: "nN")) { _ in promptNudge(); return .handled }
        .onKeyPress(characters: CharacterSet(charactersIn: "hH")) { _ in showingHistory = true; return .handled }
        .onKeyPress(characters: CharacterSet(charactersIn: "tT")) { _ in showingThemePicker = true; return .handled }

        .onKeyPress(.upArrow) { moveCursor(-1); return .handled }
        .onKeyPress(.downArrow) { moveCursor(1); return .handled }
        .onKeyPress(.leftArrow) { activePanel = .waitingFor; return .handled }
        .onKeyPress(.rightArrow) { activePanel = .waitingOnMe; return .handled }
        .onKeyPress(characters: CharacterSet(charactersIn: "kK")) { _ in moveCursor(-1); return .handled }
        .onKeyPress(characters: CharacterSet(charactersIn: "jJ")) { _ in moveCursor(1); return .handled }
        .onKeyPress(characters: CharacterSet(charactersIn: "sS")) { _ in switchPanel(); return .handled }
        .background(tc.bg)
        .sheet(isPresented: $showingAddSheet, onDismiss: { radarSuggestion = nil }) {
            if let suggestion = radarSuggestion {
                AddItemSheet(
                    direction: activePanel,
                    prefillWho: suggestion.who,
                    prefillWhat: suggestion.what,
                    prefillExpected: suggestion.expected
                )
                .environmentObject(store)
                .environmentObject(theme)
            } else {
                AddItemSheet(direction: activePanel)
                    .environmentObject(store)
                    .environmentObject(theme)
            }
        }
        .sheet(isPresented: $showingHistory) {
            HistorySheet()
                .environmentObject(store)
                .environmentObject(theme)
        }
        .sheet(item: $nudgeItem) { item in
            NudgeSheet(direction: activePanel, item: item)
                .environmentObject(store)
                .environmentObject(theme)
        }
        .sheet(item: $itemToResolve) { item in
            ConfirmSheet(
                title: "Resolve item?",
                message: "Mark '\(item.who) / \(item.what)' as resolved?",
                confirmLabel: "Resolve",
                onConfirm: {
                    resolvedDirection = activePanel
                    store.resolveItem(direction: activePanel, item: item)
                    resolvedItemForReceipt = store.data.history.last
                    selectedItemID = nil
                    itemToResolve = nil
                },
                onCancel: {
                    itemToResolve = nil
                }
            )
            .environmentObject(theme)
        }
        .sheet(isPresented: $showingThemePicker) {
            ThemePickerSheet()
                .environmentObject(theme)
        }
        .sheet(item: $resolvedItemForReceipt) { item in
            ReceiptView(item: item, direction: resolvedDirection)
        }

        .onAppear {
            store.load()
            autoSelectFirst()
            clipboard.start()
        }
        .onDisappear {
            clipboard.stop()
        }
    }

    // MARK: - Computed

    private var selectedItem: WaitingItem? {
        guard let id = selectedItemID else { return nil }
        return store.items(for: activePanel).first { $0.id == id }
    }

    private var currentItems: [WaitingItem] {
        store.items(for: activePanel)
    }

    // MARK: - Actions

    private func switchPanel() {
        activePanel = (activePanel == .waitingFor) ? .waitingOnMe : .waitingFor
        autoSelectFirst()
    }

    private func autoSelectFirst() {
        let items = store.items(for: activePanel)
        selectedItemID = items.first?.id
    }

    private func moveCursor(_ delta: Int) {
        let items = currentItems
        guard !items.isEmpty else { return }
        let currentIdx = items.firstIndex(where: { $0.id == selectedItemID }) ?? -1
        let newIdx = max(0, min(items.count - 1, currentIdx + delta))
        selectedItemID = items[newIdx].id
    }

    private func promptResolve() {
        guard let item = selectedItem else { return }
        itemToResolve = item
    }

    private func promptNudge() {
        guard let item = selectedItem else { return }
        nudgeItem = item
    }

    // MARK: - Status

    private var statusText: some View {
        let wf = store.data.waiting_for.count
        let wm = store.data.waiting_on_me.count
        let resolved = store.data.history.count
        let allItems = store.data.waiting_for + store.data.waiting_on_me
        let oldest = allItems.map(\.ageDays).max() ?? 0

        var parts: [String] = []
        if wf > 0 { parts.append("Waiting on \(wf)") }
        if wm > 0 { parts.append("Blocking \(wm)") }
        if oldest > 0 { parts.append("Oldest: \(oldest)d") }
        if resolved > 0 { parts.append("\(resolved) resolved") }

        let text = parts.isEmpty ? "All clear!" : parts.joined(separator: "  ·  ")
        return Text(text)
    }

    // MARK: - Toolbar button

    private func toolbarButton(_ title: String, icon: String, key: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text(title)
                    .font(.caption)
                Text("[\(key)]")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(tc.textSecondary)
            }
            .foregroundColor(tc.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tc.textPrimary.opacity(0.05))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Panel View

struct PanelView: View {
    @EnvironmentObject var store: WaitingRoomStore
    @EnvironmentObject var theme: ThemeManager
    let direction: Direction
    let isActive: Bool
    @Binding var selectedItemID: String?
    var onActivate: () -> Void

    private var tc: ThemeColors { theme.colors }

    private var panelColor: Color {
        direction == .waitingFor ? tc.panelLeftColor : tc.panelRightColor
    }

    private var panelBG: Color {
        direction == .waitingFor ? tc.panelLeftBg : tc.panelRightBg
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Panel header
            HStack {
                Image(systemName: direction.icon)
                Text(direction.title)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                Spacer()
                Text("\(store.items(for: direction).count)")
                    .font(.caption.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(panelColor.opacity(0.2))
                    .cornerRadius(4)
            }
            .foregroundColor(panelColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(panelBG)
            .onTapGesture { onActivate() }

            // Items list
            let items = store.items(for: direction)
            if items.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text("Empty -- press [A] to add")
                        .foregroundColor(tc.textSecondary.opacity(0.5))
                        .font(.caption)
                    Spacer()
                }
                .onTapGesture { onActivate() }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(items) { item in
                            ItemRow(item: item, isSelected: isActive && selectedItemID == item.id)
                                .onTapGesture {
                                    onActivate()
                                    selectedItemID = item.id
                                }
                        }
                    }
                    .padding(8)
                }
            }
        }
        .background(tc.surface)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isActive ? tc.borderActive : tc.borderInactive, lineWidth: isActive ? 2 : 1)
        )
    }
}

// MARK: - Item Row

struct ItemRow: View {
    @EnvironmentObject var theme: ThemeManager
    let item: WaitingItem
    let isSelected: Bool

    private var tc: ThemeColors { theme.colors }

    private var isLightTheme: Bool {
        theme.current == .light
    }

    var body: some View {
        HStack(spacing: 8) {
            if isSelected {
                Image(systemName: "arrowtriangle.right.fill")
                    .font(.system(size: 8))
                    .foregroundColor(tc.accent)
            }

            let days = item.ageDays
            let color = ageColor(days: days, forLightBg: isLightTheme)
            Circle()
                .fill(Color(red: color.r, green: color.g, blue: color.b))
                .frame(width: 10, height: 10)

            Text(item.who)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(tc.textPrimary)

            Text("·").foregroundColor(tc.textSecondary)

            Text(item.what)
                .font(.system(size: 13))
                .foregroundColor(tc.textPrimary.opacity(0.85))

            Text("·").foregroundColor(tc.textSecondary)

            let dayStr = days > 0 ? "\(days)d" : "today"
            Text(dayStr)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(Color(red: color.r, green: color.g, blue: color.b))

            if !item.expected.isEmpty {
                Text("· due \(item.expectedDisplay)")
                    .font(.system(size: 11))
                    .foregroundColor(tc.textSecondary)
            }

            let nudgeCount = item.nudges.count
            if nudgeCount > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "bell.fill").font(.system(size: 9))
                    Text("\(nudgeCount)").font(.system(size: 11, design: .monospaced))
                }
                .foregroundColor(.orange)
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isSelected ? tc.selectedBg : Color.clear)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? tc.accent.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}
