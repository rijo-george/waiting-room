import SwiftUI

struct ConfirmSheet: View {
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.dismiss) var dismiss

    let title: String
    let message: String
    var confirmLabel: String = "Confirm"
    var onConfirm: () -> Void
    var onCancel: () -> Void

    private var tc: ThemeColors { theme.colors }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundColor(tc.accent)

            Text(title)
                .font(.title3.bold())
                .foregroundColor(tc.textPrimary)

            Text(message)
                .font(.body)
                .foregroundColor(tc.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            HStack(spacing: 16) {
                Button {
                    onCancel()
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(tc.surface)
                        .foregroundColor(tc.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(tc.borderInactive, lineWidth: 1)
                        )
                }

                Button {
                    onConfirm()
                    dismiss()
                } label: {
                    Text(confirmLabel)
                        .font(.body.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(tc.accent)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            Spacer()
        }
        .background(tc.bg)
        .presentationDetents([.height(340)])
        .presentationDragIndicator(.visible)
    }
}
