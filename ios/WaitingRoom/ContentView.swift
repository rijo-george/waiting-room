import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: WaitingRoomStore
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

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
    private var isWide: Bool { horizontalSizeClass == .regular }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            clipboardBanner
            panelContent
            statusBar
            bottomToolbar
        }
        .background(tc.bg.ignoresSafeArea())
        .preferredColorScheme(theme.current.isDark ? .dark : .light)
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
            HistoryView()
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
                confirmLabel: "Resolve"
            ) {
                resolvedDirection = activePanel
                store.resolveItem(direction: activePanel, item: item)
                resolvedItemForReceipt = store.data.history.last
                selectedItemID = nil
                itemToResolve = nil
                haptic(.success)
            } onCancel: {
                itemToResolve = nil
            }
            .environmentObject(theme)
        }
        .sheet(isPresented: $showingThemePicker) {
            ThemePickerView()
                .environmentObject(theme)
        }
        .sheet(item: $resolvedItemForReceipt) { item in
            ReceiptView(item: item, direction: resolvedDirection)
                .environmentObject(theme)
        }

        .onAppear {
            store.load()
            clipboard.start()
        }
        .onDisappear {
            clipboard.stop()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            store.load()
            clipboard.checkOnce()
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "door.left.hand.open")
                .font(.title3)
            Text("The Waiting Room")
                .font(.headline)
            Spacer()
            statusText
                .font(.caption2)
                .foregroundColor(tc.textSecondary)
            Button {
                showingThemePicker = true
            } label: {
                Image(systemName: theme.current.icon)
                    .font(.system(size: 14))
                    .padding(8)
                    .background(tc.accent.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .foregroundColor(tc.textPrimary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(tc.headerBg)
    }

    // MARK: - Clipboard banner

    @ViewBuilder
    private var clipboardBanner: some View {
        if let suggestion = clipboard.suggestedItem {
            ClipboardBanner(
                suggestion: suggestion,
                onAdd: {
                    radarSuggestion = suggestion
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
    }

    // MARK: - Panel content (adaptive)

    private var panelContent: some View {
        Group {
            if isWide {
                // iPad: side-by-side panels
                HStack(spacing: 12) {
                    PanelView(
                        direction: .waitingFor,
                        isActive: activePanel == .waitingFor,
                        selectedItemID: $selectedItemID,
                        onActivate: { activePanel = .waitingFor },
                        onResolve: { promptResolve($0) },
                        onNudge: { promptNudge($0) },
                        onDelete: { store.deleteItem(direction: .waitingFor, item: $0); haptic(.success) }
                    )
                    PanelView(
                        direction: .waitingOnMe,
                        isActive: activePanel == .waitingOnMe,
                        selectedItemID: $selectedItemID,
                        onActivate: { activePanel = .waitingOnMe },
                        onResolve: { promptResolve($0) },
                        onNudge: { promptNudge($0) },
                        onDelete: { store.deleteItem(direction: .waitingOnMe, item: $0); haptic(.success) }
                    )
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
            } else {
                // iPhone: segmented control + single panel
                VStack(spacing: 0) {
                    panelSegmentedControl
                    PanelView(
                        direction: activePanel,
                        isActive: true,
                        selectedItemID: $selectedItemID,
                        onActivate: {},
                        onResolve: { promptResolve($0) },
                        onNudge: { promptNudge($0) },
                        onDelete: { store.deleteItem(direction: activePanel, item: $0); haptic(.success) }
                    )
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
                    .id(activePanel) // force rebuild on switch
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var panelSegmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(Direction.allCases, id: \.rawValue) { dir in
                let isActive = activePanel == dir
                let panelColor = dir == .waitingFor ? tc.panelLeftColor : tc.panelRightColor
                let count = store.items(for: dir).count

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        activePanel = dir
                    }
                    haptic(.light)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: dir.icon)
                            .font(.system(size: 12))
                        Text(dir.shortTitle)
                            .font(.system(size: 13, weight: .semibold))
                        if count > 0 {
                            Text("\(count)")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(panelColor.opacity(isActive ? 0.25 : 0.1))
                                .clipShape(Capsule())
                        }
                    }
                    .foregroundColor(isActive ? panelColor : tc.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isActive ? panelColor.opacity(0.08) : Color.clear)
                }
            }
        }
        .background(tc.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    // MARK: - Status bar

    private var statusBar: some View {
        statusText
            .font(.caption2)
            .foregroundColor(tc.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(tc.statusBarBg)
    }

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

    // MARK: - Bottom toolbar

    private var bottomToolbar: some View {
        HStack(spacing: 0) {
            toolbarButton("Add", icon: "plus.circle.fill") {
                showingAddSheet = true
                haptic(.light)
            }
            toolbarButton("Resolve", icon: "checkmark.circle.fill") {
                if let item = selectedItem {
                    promptResolve(item)
                }
            }
            toolbarButton("Nudge", icon: "bell.circle.fill") {
                if let item = selectedItem {
                    promptNudge(item)
                }
            }
            toolbarButton("History", icon: "clock.circle.fill") {
                showingHistory = true
            }
            toolbarButton("Theme", icon: "paintpalette.fill") {
                showingThemePicker = true
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
        .background(tc.statusBarBg)
    }

    private func toolbarButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(tc.textPrimary.opacity(0.7))
            .frame(maxWidth: .infinity)
        }
        .accessibilityLabel(title)
    }

    // MARK: - Actions

    private var selectedItem: WaitingItem? {
        guard let id = selectedItemID else { return nil }
        return store.items(for: activePanel).first { $0.id == id }
    }

    private func promptResolve(_ item: WaitingItem) {
        itemToResolve = item
    }

    private func promptNudge(_ item: WaitingItem) {
        nudgeItem = item
        haptic(.light)
    }

    private func haptic(_ style: HapticStyle) {
        switch style {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

private enum HapticStyle {
    case light, success
}
