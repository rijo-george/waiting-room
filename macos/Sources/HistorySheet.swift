import SwiftUI

struct HistorySheet: View {
    @EnvironmentObject var store: WaitingRoomStore
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.circle.fill")
                    .foregroundColor(theme.colors.accent)
                Text("Resolved History")
                    .font(.headline)
                Spacer()
                Text("\(store.data.history.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if store.data.history.isEmpty {
                HStack {
                    Spacer()
                    Text("No resolved items yet").foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical, 40)
            } else {
                Table(store.data.history.reversed()) {
                    TableColumn("Direction") { item in
                        HStack(spacing: 4) {
                            Image(systemName: item.direction == "waiting_on_me" ? "arrow.left" : "arrow.right")
                                .font(.system(size: 10))
                            Text(item.direction == "waiting_on_me" ? "Waiting for me" : "I waited")
                                .font(.system(size: 12))
                        }
                    }
                    .width(min: 110, max: 140)

                    TableColumn("Who") { item in Text(item.who).font(.system(size: 12)) }
                        .width(min: 80, max: 140)
                    TableColumn("What") { item in Text(item.what).font(.system(size: 12)) }
                        .width(min: 100, max: 200)
                    TableColumn("Opened") { item in Text(item.sinceDisplay).font(.system(size: 12)) }
                        .width(min: 60, max: 80)
                    TableColumn("Resolved") { item in Text(item.resolvedDisplay).font(.system(size: 12)) }
                        .width(min: 60, max: 80)
                    TableColumn("Days") { item in
                        Text("\(item.duration_days ?? 0)")
                            .font(.system(size: 12, design: .monospaced))
                    }
                    .width(min: 40, max: 60)
                }
            }

            HStack {
                Spacer()
                Button("Close") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(24)
        .frame(width: 700, height: 450)
    }
}
