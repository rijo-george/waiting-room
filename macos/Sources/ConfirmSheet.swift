import SwiftUI

struct ConfirmSheet: View {
    @EnvironmentObject var theme: ThemeManager
    let title: String
    let message: String
    var confirmLabel: String = "Confirm"
    var onConfirm: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 32))
                .foregroundColor(theme.colors.accent)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button("Cancel") { onCancel() }
                    .keyboardShortcut(.cancelAction)
                Button(confirmLabel) { onConfirm() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 4)
        }
        .padding(24)
        .frame(width: 340)
    }
}
