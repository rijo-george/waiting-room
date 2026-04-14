import SwiftUI

// MARK: - Panel View

struct PanelView: View {
    @EnvironmentObject var store: WaitingRoomStore
    @EnvironmentObject var theme: ThemeManager
    let direction: Direction
    let isActive: Bool
    @Binding var selectedItemID: String?
    var onActivate: () -> Void
    var onResolve: (WaitingItem) -> Void
    var onNudge: (WaitingItem) -> Void
    var onDelete: (WaitingItem) -> Void

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
                    .font(.system(size: 12))
                Text(direction.title)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                Spacer()
                Text("\(store.items(for: direction).count)")
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(panelColor.opacity(0.2))
                    .clipShape(Capsule())
            }
            .foregroundColor(panelColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(panelBG)
            .onTapGesture { onActivate() }

            // Items
            let items = store.items(for: direction)
            if items.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(items) { item in
                        ItemRow(
                            item: item,
                            isSelected: isActive && selectedItemID == item.id
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onActivate()
                            selectedItemID = item.id
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                onResolve(item)
                            } label: {
                                Label("Resolve", systemImage: "checkmark.circle.fill")
                            }
                            .tint(tc.accent)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                onNudge(item)
                            } label: {
                                Label("Nudge", systemImage: "bell.circle.fill")
                            }
                            .tint(.orange)

                            Button(role: .destructive) {
                                onDelete(item)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .listRowBackground(
                            (isActive && selectedItemID == item.id) ? tc.selectedBg : tc.surface
                        )
                        .listRowSeparatorTint(tc.borderInactive.opacity(0.3))
                        .listRowInsets(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(tc.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? tc.borderActive : tc.borderInactive, lineWidth: isActive ? 2 : 1)
        )
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 28))
                .foregroundColor(tc.textSecondary.opacity(0.3))
            Text("No items yet")
                .font(.subheadline)
                .foregroundColor(tc.textSecondary.opacity(0.5))
            Text("Tap + to add one")
                .font(.caption)
                .foregroundColor(tc.textSecondary.opacity(0.3))
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .onTapGesture { onActivate() }
    }
}

// MARK: - Item Row

struct ItemRow: View {
    @EnvironmentObject var theme: ThemeManager
    let item: WaitingItem
    let isSelected: Bool

    private var tc: ThemeColors { theme.colors }
    private var isLightTheme: Bool { theme.current == .light }

    var body: some View {
        HStack(spacing: 8) {
            // Age indicator dot
            let days = item.ageDays
            let color = ageColor(days: days, forLightBg: isLightTheme)
            let ageLabel = days < 3 ? "fresh" : days < 7 ? "aging" : "overdue"
            Circle()
                .fill(Color(red: color.r, green: color.g, blue: color.b))
                .frame(width: 10, height: 10)
                .accessibilityLabel("\(ageLabel) indicator")

            // Main content
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.who)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(tc.textPrimary)
                        .lineLimit(1)

                    Text("·")
                        .foregroundColor(tc.textSecondary)

                    Text(item.what)
                        .font(.system(size: 14))
                        .foregroundColor(tc.textPrimary.opacity(0.85))
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    let dayStr = days > 0 ? "\(days)d ago" : "today"
                    Text(dayStr)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color(red: color.r, green: color.g, blue: color.b))

                    if !item.expected.isEmpty {
                        Text("due \(item.expectedDisplay)")
                            .font(.system(size: 11))
                            .foregroundColor(tc.textSecondary)
                    }

                    if !item.nudges.isEmpty {
                        HStack(spacing: 2) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 9))
                            Text("\(item.nudges.count)")
                                .font(.system(size: 11, design: .monospaced))
                        }
                        .foregroundColor(.orange)
                    }
                }
            }

            Spacer(minLength: 4)

            if isSelected {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(tc.accent)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isSelected ? tc.selectedBg : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? tc.accent.opacity(0.4) : Color.clear, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.who), \(item.what), \(days > 0 ? "\(days) days" : "today")\(item.nudges.isEmpty ? "" : ", \(item.nudges.count) nudge\(item.nudges.count == 1 ? "" : "s")")")
    }
}
