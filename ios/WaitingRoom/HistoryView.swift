import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: WaitingRoomStore
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.dismiss) var dismiss

    @State private var selectedItem: WaitingItem?

    private var tc: ThemeColors { theme.colors }

    var body: some View {
        NavigationStack {
            Group {
                if store.data.history.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .background(tc.bg)
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.circle.fill")
                            .foregroundColor(tc.accent)
                        Text("Resolved History")
                            .font(.headline)
                        Text("\(store.data.history.count)")
                            .font(.caption.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(tc.accent.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
            .sheet(item: $selectedItem) { item in
                let dir: Direction = item.direction == "waiting_on_me" ? .waitingOnMe : .waitingFor
                ReceiptView(item: item, direction: dir)
                    .environmentObject(theme)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40))
                .foregroundColor(tc.textSecondary.opacity(0.3))
            Text("No resolved items yet")
                .font(.body)
                .foregroundColor(tc.textSecondary)
            Text("Resolve items to see them here")
                .font(.caption)
                .foregroundColor(tc.textSecondary.opacity(0.5))
            Spacer()
        }
    }

    private var historyList: some View {
        List(store.data.history.reversed()) { item in
            Button {
                selectedItem = item
            } label: {
                historyRow(item)
            }
            .listRowBackground(tc.surface)
        }
        .scrollContentBackground(.hidden)
    }

    private func historyRow(_ item: WaitingItem) -> some View {
        HStack(spacing: 12) {
            // Direction indicator
            Image(systemName: item.direction == "waiting_on_me" ? "arrow.left.circle.fill" : "arrow.right.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(item.direction == "waiting_on_me" ? tc.panelRightColor : tc.panelLeftColor)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.who)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(tc.textPrimary)
                    Text("·")
                        .foregroundColor(tc.textSecondary)
                    Text(item.what)
                        .font(.system(size: 14))
                        .foregroundColor(tc.textPrimary.opacity(0.8))
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    Text("\(item.sinceDisplay) -> \(item.resolvedDisplay)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(tc.textSecondary)

                    if let days = item.duration_days {
                        Text("\(days)d")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(tc.accent)
                    }

                    if !item.nudges.isEmpty {
                        HStack(spacing: 2) {
                            Image(systemName: "bell.fill").font(.system(size: 8))
                            Text("\(item.nudges.count)")
                                .font(.system(size: 10, design: .monospaced))
                        }
                        .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 10))
                .foregroundColor(tc.textSecondary.opacity(0.4))
        }
        .padding(.vertical, 4)
    }
}
