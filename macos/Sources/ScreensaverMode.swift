import SwiftUI

// MARK: - Screensaver Mode
// A fullscreen ambient view showing open loops. Triggered from the app or run standalone.

struct ScreensaverMode: View {
    @EnvironmentObject var store: WaitingRoomStore
    @Environment(\.dismiss) var dismiss
    @State private var clock = Date()
    @State private var animOffset: CGFloat = 0

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let driftTimer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            // Slow gradient drift
            RadialGradient(
                colors: [Color(r: 0.08, g: 0.06, b: 0.14), Color.black],
                center: .center,
                startRadius: 100,
                endRadius: 600
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Clock
                Text(timeString)
                    .font(.system(size: 72, weight: .thin, design: .monospaced))
                    .foregroundColor(.white.opacity(0.15))
                    .padding(.bottom, 40)

                // Title
                Text("THE WAITING ROOM")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(6)
                    .foregroundColor(.white.opacity(0.2))
                    .padding(.bottom, 40)

                // Two columns
                HStack(alignment: .top, spacing: 80) {
                    // Left: waiting for
                    loopColumn(
                        title: "WAITING FOR",
                        items: store.data.waiting_for,
                        color: Color(r: 0.35, g: 0.85, b: 0.55)
                    )

                    // Divider
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 1)
                        .frame(maxHeight: 300)

                    // Right: waiting on me
                    loopColumn(
                        title: "WAITING ON ME",
                        items: store.data.waiting_on_me,
                        color: Color(r: 0.85, g: 0.45, b: 0.70)
                    )
                }
                .padding(.horizontal, 80)

                Spacer()

                // Summary
                HStack(spacing: 24) {
                    statPill("\(store.data.waiting_for.count) outbound", Color(r: 0.35, g: 0.85, b: 0.55))
                    statPill("\(store.data.waiting_on_me.count) inbound", Color(r: 0.85, g: 0.45, b: 0.70))
                    if let oldest = oldestDays {
                        statPill("oldest: \(oldest)d", Color(r: 0.85, g: 0.55, b: 0.25))
                    }
                }
                .padding(.bottom, 40)

                // Hint
                Text("Press any key or click to exit")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.1))
                    .padding(.bottom, 20)
            }
        }
        .onReceive(timer) { _ in clock = Date() }
        .onReceive(driftTimer) { _ in animOffset += 0.01 }
        .onTapGesture { dismiss() }
        .onKeyPress(.escape) { dismiss(); return .handled }
        // Catch any key press to exit
        .focusable()
        .onKeyPress(characters: .init(charactersIn: "abcdefghijklmnopqrstuvwxyz ")) { _ in dismiss(); return .handled }
    }

    private var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: clock)
    }

    private var oldestDays: Int? {
        let all = store.data.waiting_for + store.data.waiting_on_me
        let days = all.map(\.ageDays)
        return days.max()
    }

    private func loopColumn(title: String, items: [WaitingItem], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(3)
                .foregroundColor(color.opacity(0.5))

            if items.isEmpty {
                Text("all clear")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white.opacity(0.1))
            } else {
                ForEach(items) { item in
                    loopRow(item: item, color: color)
                }
            }
        }
        .frame(minWidth: 250, alignment: .leading)
    }

    private func loopRow(item: WaitingItem, color: Color) -> some View {
        let days = item.ageDays
        let ageColor = days < 3 ? Color(r: 0.35, g: 0.85, b: 0.55) :
                       days < 7 ? Color(r: 0.85, g: 0.70, b: 0.25) :
                                  Color(r: 0.85, g: 0.30, b: 0.30)
        let dayStr = days > 0 ? "\(days)d" : "now"

        return HStack(spacing: 10) {
            Circle()
                .fill(ageColor.opacity(0.6))
                .frame(width: 6, height: 6)

            Text(item.who)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))

            Text(item.what)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.white.opacity(0.3))
                .lineLimit(1)

            Spacer()

            Text(dayStr)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(ageColor.opacity(0.7))
        }
    }

    private func statPill(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundColor(color.opacity(0.5))
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(color.opacity(0.05))
            .cornerRadius(100)
            .overlay(
                RoundedRectangle(cornerRadius: 100)
                    .stroke(color.opacity(0.1), lineWidth: 1)
            )
    }
}
