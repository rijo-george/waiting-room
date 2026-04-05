import SwiftUI
import AppKit
import NaturalLanguage

// MARK: - Clipboard Radar

class ClipboardRadar: ObservableObject {
    @Published var suggestedItem: ClipboardSuggestion?

    private var lastChangeCount: Int = 0
    private var timer: Timer?

    struct ClipboardSuggestion: Identifiable {
        let id = UUID()
        let who: String
        let what: String
        let expected: String
        let rawText: String
    }

    private let patterns: [String] = [
        #"(?i)i'?ll (?:get back to you|send|share|follow up|have it|deliver|finish|complete|update you)"#,
        #"(?i)(?:will|gonna|going to) (?:send|share|get back|follow up|have|deliver|finish|reply|respond)"#,
        #"(?i)(?:expect|should have|should be ready|target|aiming for|by) (?:\w+ \d+|\d+\/\d+|tomorrow|monday|tuesday|wednesday|thursday|friday|end of (?:week|day|month))"#,
        #"(?i)(?:waiting on|waiting for|need from|pending|blocked on|depends on) .{3,40}"#,
        #"(?i)(?:can you|could you|please|would you|do you mind|when can you) (?:send|share|review|approve|sign|confirm|check|look at|finish|complete|update)"#,
        #"(?i)(?:need you to|need your|waiting for your|waiting on your|expecting your) (?:review|approval|feedback|input|response|reply|sign)"#,
        #"(?i)(?:this is on you|assigned to you|over to you|your turn|action needed|action required)"#,
    ]

    func start() {
        lastChangeCount = NSPasteboard.general.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func dismiss() {
        suggestedItem = nil
    }

    private func checkClipboard() {
        let currentCount = NSPasteboard.general.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        guard let text = NSPasteboard.general.string(forType: .string),
              text.count > 10, text.count < 1000 else { return }

        if text.contains("func ") || text.contains("class ") || text.contains("{") ||
           text.hasPrefix("http") || text.hasPrefix("/") { return }

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil {
                let snippet = String(text.prefix(200))
                if let suggestion = parseSuggestion(from: snippet) {
                    DispatchQueue.main.async {
                        self.suggestedItem = suggestion
                    }
                }
                return
            }
        }
    }

    private func parseSuggestion(from text: String) -> ClipboardSuggestion? {
        var who = ""
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, range in
            if tag == .personalName && who.isEmpty {
                who = String(text[range])
            }
            return true
        }

        var expected = ""
        let deadlinePatterns = [
            #"(?i)by (\w+ \d+)"#,
            #"(?i)by (tomorrow|monday|tuesday|wednesday|thursday|friday|end of \w+)"#,
            #"(?i)(tomorrow|next \w+)"#,
        ]
        for dp in deadlinePatterns {
            if let regex = try? NSRegularExpression(pattern: dp),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: text) {
                expected = String(text[range])
                break
            }
        }

        let what = text.components(separatedBy: .newlines).first ?? text
        let trimmedWhat = String(what.prefix(60)).trimmingCharacters(in: .whitespaces)

        if who.isEmpty { who = "Someone" }

        return ClipboardSuggestion(
            who: who,
            what: trimmedWhat,
            expected: expected,
            rawText: String(text.prefix(200))
        )
    }
}

// MARK: - Clipboard Banner

struct ClipboardBanner: View {
    @EnvironmentObject var theme: ThemeManager
    let suggestion: ClipboardRadar.ClipboardSuggestion
    let onAdd: () -> Void
    let onDismiss: () -> Void

    private var tc: ThemeColors { theme.colors }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "clipboard.fill")
                .font(.system(size: 14))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Clipboard Radar")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(tc.textPrimary)
                Text("\"\(suggestion.rawText.prefix(60))\"")
                    .font(.system(size: 10))
                    .foregroundColor(tc.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onAdd) {
                Text("Add Wait")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(tc.accent)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(tc.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(tc.surface)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}
