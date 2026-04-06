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
    @FocusState private var focusedField: Field?

    private enum Field { case who, what, expected, note }
    private var tc: ThemeColors { theme.colors }

    private var isValid: Bool {
        !who.trimmingCharacters(in: .whitespaces).isEmpty &&
        !what.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // Direction picker
                Section {
                    Picker("Direction", selection: $selectedDirection) {
                        Label("I'm waiting for...", systemImage: "arrow.right")
                            .tag(Direction.waitingFor)
                        Label("Waiting on me...", systemImage: "arrow.left")
                            .tag(Direction.waitingOnMe)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(tc.surface)
                }

                // Required fields
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Who?")
                            .font(.caption)
                            .foregroundColor(tc.textSecondary)
                        TextField("e.g. Priya, AWS Support, Zepto", text: $who)
                            .focused($focusedField, equals: .who)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .what }
                    }
                    .listRowBackground(tc.surface)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("What?")
                            .font(.caption)
                            .foregroundColor(tc.textSecondary)
                        TextField("e.g. contract, reply, package", text: $what)
                            .focused($focusedField, equals: .what)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .expected }
                    }
                    .listRowBackground(tc.surface)
                } header: {
                    Text("Details")
                }

                // Optional fields
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Expected by?")
                            .font(.caption)
                            .foregroundColor(tc.textSecondary)
                        TextField("e.g. Apr 10, 2026-04-10", text: $expected)
                            .focused($focusedField, equals: .expected)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .note }
                    }
                    .listRowBackground(tc.surface)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Note")
                            .font(.caption)
                            .foregroundColor(tc.textSecondary)
                        TextField("Optional context", text: $note)
                            .focused($focusedField, equals: .note)
                            .submitLabel(.done)
                            .onSubmit { if isValid { addItem() } }
                    }
                    .listRowBackground(tc.surface)
                } header: {
                    Text("Optional")
                }
            }
            .scrollContentBackground(.hidden)
            .background(tc.bg)
            .navigationTitle("New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addItem() }
                        .bold()
                        .disabled(!isValid)
                }
            }
            .onAppear {
                selectedDirection = direction
                if !prefillWho.isEmpty { who = prefillWho }
                if !prefillWhat.isEmpty { what = prefillWhat }
                if !prefillExpected.isEmpty { expected = prefillExpected }
                if !prefillNote.isEmpty { note = prefillNote }
                focusedField = .who
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func addItem() {
        let trimmedWho = who.trimmingCharacters(in: .whitespaces)
        let trimmedWhat = what.trimmingCharacters(in: .whitespaces)
        guard !trimmedWho.isEmpty, !trimmedWhat.isEmpty else { return }
        store.addItem(
            direction: selectedDirection,
            who: trimmedWho,
            what: trimmedWhat,
            expected: expected.trimmingCharacters(in: .whitespaces),
            note: note.trimmingCharacters(in: .whitespaces)
        )
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}
