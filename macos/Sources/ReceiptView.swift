import SwiftUI
import AppKit

struct ReceiptView: View {
    let item: WaitingItem
    let direction: Direction
    @Environment(\.dismiss) var dismiss

    private var dirLabel: String {
        direction == .waitingFor ? "I WAITED" : "THEY WAITED ON ME"
    }

    private var durationDays: Int {
        item.duration_days ?? item.ageDays
    }

    private var resolvedDate: String {
        if let r = item.resolved_at {
            return item.resolvedDisplay
        }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            // The receipt itself
            VStack(spacing: 0) {
                receiptContent
            }
            .background(Color(r: 0.98, g: 0.97, b: 0.94))
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 12, y: 6)
            .padding(32)

            // Actions
            HStack(spacing: 12) {
                Button("Copy to Clipboard") { copyReceipt() }
                    .keyboardShortcut("c", modifiers: .command)
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.bottom, 24)
        }
        .frame(width: 380)
    }

    private var receiptContent: some View {
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
            .padding(.top, 24)
            .padding(.bottom, 16)

            // Dashed line
            dashedLine

            // Main content
            VStack(alignment: .leading, spacing: 12) {
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
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            dashedLine

            // Duration — the big number
            VStack(spacing: 4) {
                Text("\(durationDays)")
                    .font(.system(size: 48, weight: .black, design: .monospaced))
                    .foregroundColor(.black.opacity(0.85))
                Text(durationDays == 1 ? "DAY" : "DAYS")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(.black.opacity(0.4))
            }
            .padding(.vertical, 20)

            dashedLine

            // Nudges
            if !item.nudges.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("FOLLOW-UPS: \(item.nudges.count)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.black.opacity(0.4))
                    ForEach(item.nudges) { nudge in
                        HStack(alignment: .top, spacing: 6) {
                            Text("->")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.black.opacity(0.3))
                            Text(nudge.note)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.black.opacity(0.5))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)

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
            .padding(.vertical, 20)
        }
    }

    private var dashedLine: some View {
        HStack(spacing: 4) {
            ForEach(0..<30, id: \.self) { _ in
                Rectangle()
                    .fill(Color.black.opacity(0.15))
                    .frame(width: 6, height: 1)
            }
        }
        .padding(.horizontal, 16)
    }

    private func receiptRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.black.opacity(0.35))
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.black.opacity(0.75))
        }
    }

    private func copyReceipt() {
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

        let text = lines.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
