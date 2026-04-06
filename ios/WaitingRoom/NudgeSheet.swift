import SwiftUI

struct NudgeSheet: View {
    @EnvironmentObject var store: WaitingRoomStore
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.dismiss) var dismiss

    let direction: Direction
    let item: WaitingItem

    @State private var note = ""
    @FocusState private var isFocused: Bool

    private var tc: ThemeColors { theme.colors }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Item info
                HStack(spacing: 10) {
                    Image(systemName: "bell.circle.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.who)
                            .font(.headline)
                            .foregroundColor(tc.textPrimary)
                        Text(item.what)
                            .font(.subheadline)
                            .foregroundColor(tc.textSecondary)
                    }
                    Spacer()
                }
                .padding()
                .background(tc.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Nudge history
                if !item.nudges.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Previous nudges (\(item.nudges.count))")
                            .font(.caption)
                            .foregroundColor(tc.textSecondary)
                        ForEach(item.nudges.suffix(3)) { nudge in
                            HStack(spacing: 6) {
                                Text("->")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(tc.textSecondary)
                                Text(nudge.note)
                                    .font(.system(size: 13))
                                    .foregroundColor(tc.textPrimary.opacity(0.7))
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }

                // Note input
                VStack(alignment: .leading, spacing: 6) {
                    Text("Add a note (optional)")
                        .font(.caption)
                        .foregroundColor(tc.textSecondary)
                    TextField("e.g. sent follow-up email", text: $note)
                        .focused($isFocused)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                        .onSubmit { logNudge() }
                }

                Spacer()
            }
            .padding()
            .background(tc.bg)
            .navigationTitle("Log Nudge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log Nudge") { logNudge() }
                        .bold()
                }
            }
            .onAppear { isFocused = true }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func logNudge() {
        store.nudgeItem(direction: direction, item: item, note: note.trimmingCharacters(in: .whitespaces))
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}
