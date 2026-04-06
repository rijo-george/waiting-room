import SwiftUI

struct ReceiptView: View {
    @EnvironmentObject var theme: ThemeManager
    @Environment(\.dismiss) var dismiss

    let item: WaitingItem
    let direction: Direction

    @State private var showCopiedToast = false

    private var dirLabel: String {
        direction == .waitingFor ? "I WAITED" : "THEY WAITED ON ME"
    }

    private var durationDays: Int {
        item.duration_days ?? item.ageDays
    }

    private var resolvedDate: String {
        if item.resolved_at != nil {
            return item.resolvedDisplay
        }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: Date())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    receiptCard
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                    actionButtons
                        .padding(.top, 20)
                        .padding(.bottom, 32)
                }
            }
            .background(theme.colors.bg)
            .navigationTitle("Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .overlay {
                if showCopiedToast {
                    copiedToast
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Receipt card

    private var receiptCard: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                Text("THE WAITING ROOM")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(3)
                    .foregroundColor(.black.opacity(0.4))
                Text("- RESOLVED -")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.black.opacity(0.3))
            }
            .padding(.top, 28)
            .padding(.bottom, 18)

            dashedLine

            // Details
            VStack(alignment: .leading, spacing: 14) {
                receiptRow("WHO", item.who)
                receiptRow("WHAT", item.what)
                receiptRow("DIRECTION", dirLabel)
                receiptRow("OPENED", item.sinceDisplay)
                receiptRow("RESOLVED", resolvedDate)
                if !item.expected.isEmpty {
                    receiptRow("EXPECTED", item.expectedDisplay)
                }
                if !item.note.isEmpty {
                    receiptRow("NOTE", item.note)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 18)

            dashedLine

            // Duration — the big number
            VStack(spacing: 4) {
                Text("\(durationDays)")
                    .font(.system(size: 56, weight: .black, design: .monospaced))
                    .foregroundColor(.black.opacity(0.85))
                Text(durationDays == 1 ? "DAY" : "DAYS")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(.black.opacity(0.4))
            }
            .padding(.vertical, 24)

            dashedLine

            // Nudges
            if !item.nudges.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("FOLLOW-UPS: \(item.nudges.count)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.black.opacity(0.4))
                    ForEach(item.nudges) { nudge in
                        HStack(alignment: .top, spacing: 6) {
                            Text("->")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.black.opacity(0.3))
                            Text(nudge.note)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.black.opacity(0.5))
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 14)

                dashedLine
            }

            // Footer
            VStack(spacing: 4) {
                Text("THANK YOU FOR YOUR PATIENCE")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .tracking(1.5)
                    .foregroundColor(.black.opacity(0.3))
                Text("waitingroom.app")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.black.opacity(0.2))
            }
            .padding(.vertical, 24)
        }
        .frame(maxWidth: .infinity)
        .background(Color(r: 0.98, g: 0.97, b: 0.94))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
    }

    private var dashedLine: some View {
        HStack(spacing: 4) {
            ForEach(0..<25, id: \.self) { _ in
                Rectangle()
                    .fill(Color.black.opacity(0.15))
                    .frame(width: 6, height: 1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }

    private func receiptRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.black.opacity(0.35))
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.black.opacity(0.75))
        }
    }

    // MARK: - Actions

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                copyReceipt()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
                    .font(.body.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(theme.colors.surface)
                    .foregroundColor(theme.colors.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.colors.borderInactive, lineWidth: 1)
                    )
            }

            ShareLink(item: buildReceiptText()) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(.body.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(theme.colors.accent)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 24)
    }

    private var copiedToast: some View {
        VStack {
            Text("Copied to clipboard")
                .font(.subheadline.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(.top, 8)
            Spacer()
        }
    }

    // MARK: - Receipt text

    private func buildReceiptText() -> String {
        var lines: [String] = []
        lines.append("================================")
        lines.append("      THE WAITING ROOM")
        lines.append("         - RESOLVED -")
        lines.append("================================")
        lines.append("")
        lines.append("  WHO:       \(item.who)")
        lines.append("  WHAT:      \(item.what)")
        lines.append("  DIRECTION: \(dirLabel)")
        lines.append("  OPENED:    \(item.sinceDisplay)")
        lines.append("  RESOLVED:  \(resolvedDate)")
        if !item.expected.isEmpty {
            lines.append("  EXPECTED:  \(item.expectedDisplay)")
        }
        lines.append("")
        lines.append("  ~~~~~~~~  \(durationDays) \(durationDays == 1 ? "DAY" : "DAYS")  ~~~~~~~~")
        lines.append("")
        if !item.nudges.isEmpty {
            lines.append("  FOLLOW-UPS: \(item.nudges.count)")
            for n in item.nudges {
                lines.append("    -> \(n.note)")
            }
            lines.append("")
        }
        lines.append("================================")
        lines.append("  THANK YOU FOR YOUR PATIENCE")
        lines.append("================================")
        return lines.joined(separator: "\n")
    }

    private func copyReceipt() {
        UIPasteboard.general.string = buildReceiptText()
        withAnimation {
            showCopiedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showCopiedToast = false
            }
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
