import SwiftUI

struct NudgeSheet: View {
    @EnvironmentObject var store: WaitingRoomStore
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.dismiss) var dismiss

    let direction: Direction
    let item: WaitingItem

    @State private var note = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bell.circle.fill")
                    .foregroundColor(.orange)
                Text("Nudge -- \(item.who) / \(item.what)")
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Add a note (optional)").font(.caption).foregroundColor(.secondary)
                TextField("e.g. sent follow-up email", text: $note)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Log Nudge") {
                    store.nudgeItem(direction: direction, item: item, note: note.trimmingCharacters(in: .whitespaces))
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}
