import SwiftUI

struct AddItemSheet: View {
    @EnvironmentObject var store: WaitingRoomStore
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.dismiss) var dismiss

    let direction: Direction
    var prefillWho: String = ""
    var prefillWhat: String = ""
    var prefillExpected: String = ""
    var prefillNote: String = ""

    @State private var selectedDirection: Direction = .waitingFor
    @State private var who = ""
    @State private var what = ""
    @State private var expected = ""
    @State private var note = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(theme.colors.accent)
                Text("New item")
                    .font(.headline)
            }

            // Direction picker
            Picker("", selection: $selectedDirection) {
                Text("I'm waiting for...").tag(Direction.waitingFor)
                Text("Waiting on me...").tag(Direction.waitingOnMe)
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 4) {
                Text("Who?").font(.caption).foregroundColor(.secondary)
                TextField("e.g. Priya, AWS Support, Zepto", text: $who)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("What?").font(.caption).foregroundColor(.secondary)
                TextField("e.g. contract, reply, package", text: $what)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Expected by? (optional)").font(.caption).foregroundColor(.secondary)
                TextField("e.g. Apr 10", text: $expected)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Note (optional)").font(.caption).foregroundColor(.secondary)
                TextField("optional context", text: $note)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Add") { addItem() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(who.trimmingCharacters(in: .whitespaces).isEmpty || what.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 420)
        .onAppear {
            selectedDirection = direction
            if !prefillWho.isEmpty { who = prefillWho }
            if !prefillWhat.isEmpty { what = prefillWhat }
            if !prefillExpected.isEmpty { expected = prefillExpected }
            if !prefillNote.isEmpty { note = prefillNote }
        }
    }

    private func addItem() {
        let trimmedWho = who.trimmingCharacters(in: .whitespaces)
        let trimmedWhat = what.trimmingCharacters(in: .whitespaces)
        guard !trimmedWho.isEmpty, !trimmedWhat.isEmpty else { return }
        store.addItem(direction: selectedDirection, who: trimmedWho, what: trimmedWhat,
                      expected: expected.trimmingCharacters(in: .whitespaces),
                      note: note.trimmingCharacters(in: .whitespaces))
        dismiss()
    }
}
