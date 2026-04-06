import SwiftUI
import NaturalLanguage

// MARK: - Clipboard Radar (iOS adaptation)
// On iOS, clipboard access triggers a system prompt, so we check less aggressively:
// - On app foreground (after a delay to avoid the prompt on every launch)
// - Only when explicitly triggered by user via checkOnce()

class ClipboardRadar: ObservableObject {
    @Published var suggestedItem: ClipboardSuggestion?

    private var lastCheckedString: String?
    private var isRunning = false

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
        isRunning = true
    }

    func stop() {
        isRunning = false
    }

    func dismiss() {
        withAnimation {
            suggestedItem = nil
        }
    }

    /// Check clipboard once (e.g. on app foreground).
    /// iOS 16+ shows a paste prompt, so we only do this sparingly.
    func checkOnce() {
        guard isRunning else { return }

        // Use UIPasteboard.general.hasStrings to avoid triggering the paste prompt
        // when there's nothing relevant. The actual .string access will prompt.
        guard UIPasteboard.general.hasStrings else { return }

        // We read the string — this may trigger iOS paste prompt
        guard let text = UIPasteboard.general.string,
              text.count > 10, text.count < 1000,
              text != lastCheckedString else { return }

        lastCheckedString = text

        // Filter out code, URLs, paths
        if text.contains("func ") || text.contains("class ") || text.contains("{") ||
           text.hasPrefix("http") || text.hasPrefix("/") { return }

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil {
                let snippet = String(text.prefix(200))
                if let suggestion = parseSuggestion(from: snippet) {
                    DispatchQueue.main.async {
                        withAnimation {
                            self.suggestedItem = suggestion
                        }
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
                .font(.system(size: 16))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Clipboard Radar")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(tc.textPrimary)
                Text("\"\(suggestion.rawText.prefix(50))\"")
                    .font(.system(size: 11))
                    .foregroundColor(tc.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onAdd) {
                Text("Add Wait")
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(tc.accent)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(tc.textSecondary)
                    .padding(6)
            }
        }
        .padding(12)
        .background(tc.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}
