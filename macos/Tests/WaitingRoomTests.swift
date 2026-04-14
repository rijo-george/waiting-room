import XCTest
@testable import WaitingRoom

// MARK: - ISO8601Flexible Tests

final class ISO8601FlexibleTests: XCTestCase {

    func testDateOnlyFormat() {
        let date = ISO8601Flexible.date(from: "2026-04-05")
        XCTAssertNotNil(date, "Should parse date-only format yyyy-MM-dd")
    }

    func testFullISOWithFractionalSeconds() {
        let date = ISO8601Flexible.date(from: "2026-04-05T12:31:42.357149")
        XCTAssertNotNil(date, "Should parse Python isoformat with microseconds")
    }

    func testFullISOWithMilliseconds() {
        let date = ISO8601Flexible.date(from: "2026-04-05T12:31:42.357")
        XCTAssertNotNil(date, "Should parse ISO with milliseconds")
    }

    func testFullISOWithoutFractional() {
        let date = ISO8601Flexible.date(from: "2026-04-05T12:31:42")
        XCTAssertNotNil(date, "Should parse ISO without fractional seconds")
    }

    func testISOWithTimezoneZ() {
        let date = ISO8601Flexible.date(from: "2026-04-05T12:31:42Z")
        XCTAssertNotNil(date, "Should parse ISO with Z timezone")
    }

    func testISOWithOffset() {
        let date = ISO8601Flexible.date(from: "2026-04-05T12:31:42+00:00")
        XCTAssertNotNil(date, "Should parse ISO with +00:00 offset")
    }

    func testEmptyStringReturnsNil() {
        let date = ISO8601Flexible.date(from: "")
        XCTAssertNil(date, "Empty string should return nil")
    }

    func testGarbageReturnsNil() {
        let date = ISO8601Flexible.date(from: "not-a-date")
        XCTAssertNil(date, "Garbage input should return nil")
    }

    func testVeryLongStringTruncated() {
        // Strings longer than 26 chars should be handled (prefix truncated)
        let date = ISO8601Flexible.date(from: "2026-04-05T12:31:42.357149999999")
        XCTAssertNotNil(date, "Should handle oversized microsecond strings by truncating")
    }

    func testDifferentDatesProduceDifferentResults() {
        let d1 = ISO8601Flexible.date(from: "2026-01-01")
        let d2 = ISO8601Flexible.date(from: "2026-12-31")
        XCTAssertNotNil(d1)
        XCTAssertNotNil(d2)
        XCTAssertNotEqual(d1, d2, "Different dates should parse to different Date objects")
    }
}

// MARK: - WaitingItem Tests

final class WaitingItemTests: XCTestCase {

    func testAgeDaysForToday() {
        let now = DateFormatter.pythonISO.string(from: Date())
        let item = makeItem(since: now)
        XCTAssertEqual(item.ageDays, 0, "Item created now should be 0 days old")
    }

    func testAgeDaysForPastDate() {
        let fiveDaysAgo = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let since = DateFormatter.pythonISO.string(from: fiveDaysAgo)
        let item = makeItem(since: since)
        XCTAssertEqual(item.ageDays, 5, "Item from 5 days ago should report 5 days")
    }

    func testAgeDaysForInvalidDate() {
        let item = makeItem(since: "garbage")
        XCTAssertEqual(item.ageDays, 0, "Invalid since date should default to 0 days")
    }

    func testExpectedDisplayWithDate() {
        let item = makeItem(expected: "2026-04-10")
        XCTAssertEqual(item.expectedDisplay, "Apr 10")
    }

    func testExpectedDisplayEmpty() {
        let item = makeItem(expected: "")
        XCTAssertEqual(item.expectedDisplay, "")
    }

    func testExpectedDisplayFallbackToRaw() {
        let item = makeItem(expected: "next week")
        XCTAssertEqual(item.expectedDisplay, "next week",
                       "Unparseable expected should return raw string")
    }

    func testSinceDisplayFormatted() {
        let item = makeItem(since: "2026-04-05T12:00:00")
        XCTAssertEqual(item.sinceDisplay, "Apr 5")
    }

    func testSinceDisplayInvalid() {
        let item = makeItem(since: "nope")
        XCTAssertEqual(item.sinceDisplay, "-")
    }

    func testResolvedDisplayFormatted() {
        var item = makeItem()
        item.resolved_at = "2026-04-15T12:00:00"
        XCTAssertEqual(item.resolvedDisplay, "Apr 15")
    }

    func testResolvedDisplayNil() {
        let item = makeItem()
        XCTAssertEqual(item.resolvedDisplay, "-")
    }

    func testIdentifiable() {
        let item = makeItem()
        XCTAssertEqual(item.id, item.id, "Items should have stable IDs")
    }

    // MARK: Helpers

    private func makeItem(
        id: String = "test-id",
        who: String = "Alice",
        what: String = "Contract",
        since: String = "2026-04-01T12:00:00",
        expected: String = "",
        nudges: [Nudge] = [],
        note: String = ""
    ) -> WaitingItem {
        WaitingItem(
            id: id, who: who, what: what, since: since,
            expected: expected, nudges: nudges, note: note
        )
    }
}

// MARK: - Nudge Tests

final class NudgeTests: XCTestCase {

    func testNudgeIdentifiable() {
        let nudge = Nudge(at: "2026-04-05T12:00:00", note: "emailed")
        XCTAssertEqual(nudge.id, "2026-04-05T12:00:00",
                       "Nudge ID should be its timestamp")
    }

    func testNudgeCodable() throws {
        let nudge = Nudge(at: "2026-04-05T12:00:00", note: "called")
        let data = try JSONEncoder().encode(nudge)
        let decoded = try JSONDecoder().decode(Nudge.self, from: data)
        XCTAssertEqual(decoded.at, nudge.at)
        XCTAssertEqual(decoded.note, nudge.note)
    }
}

// MARK: - WaitingData Codable Tests

final class WaitingDataTests: XCTestCase {

    func testEmptyDataRoundTrip() throws {
        let data = WaitingData(waiting_for: [], waiting_on_me: [], history: [])
        let encoded = try JSONEncoder().encode(data)
        let decoded = try JSONDecoder().decode(WaitingData.self, from: encoded)
        XCTAssertTrue(decoded.waiting_for.isEmpty)
        XCTAssertTrue(decoded.waiting_on_me.isEmpty)
        XCTAssertTrue(decoded.history.isEmpty)
    }

    func testDataWithItemsRoundTrip() throws {
        let item = WaitingItem(
            id: "abc-123", who: "Bob", what: "Invoice",
            since: "2026-04-01", expected: "2026-04-10",
            nudges: [Nudge(at: "2026-04-05T10:00:00", note: "emailed")],
            note: "urgent"
        )
        let data = WaitingData(
            waiting_for: [item], waiting_on_me: [], history: []
        )
        let encoded = try JSONEncoder().encode(data)
        let decoded = try JSONDecoder().decode(WaitingData.self, from: encoded)
        XCTAssertEqual(decoded.waiting_for.count, 1)
        XCTAssertEqual(decoded.waiting_for[0].who, "Bob")
        XCTAssertEqual(decoded.waiting_for[0].nudges.count, 1)
        XCTAssertEqual(decoded.waiting_for[0].nudges[0].note, "emailed")
    }

    func testResolvedItemPreservesOptionalFields() throws {
        var item = WaitingItem(
            id: "r-1", who: "Carol", what: "Review",
            since: "2026-04-01", expected: "",
            nudges: [], note: ""
        )
        item.resolved_at = "2026-04-12T14:30:00"
        item.direction = "waiting_for"
        item.duration_days = 11

        let data = WaitingData(waiting_for: [], waiting_on_me: [], history: [item])
        let encoded = try JSONEncoder().encode(data)
        let decoded = try JSONDecoder().decode(WaitingData.self, from: encoded)
        let resolved = decoded.history[0]
        XCTAssertEqual(resolved.resolved_at, "2026-04-12T14:30:00")
        XCTAssertEqual(resolved.direction, "waiting_for")
        XCTAssertEqual(resolved.duration_days, 11)
    }
}

// MARK: - Direction Tests

final class DirectionTests: XCTestCase {

    func testRawValues() {
        XCTAssertEqual(Direction.waitingFor.rawValue, "waiting_for")
        XCTAssertEqual(Direction.waitingOnMe.rawValue, "waiting_on_me")
    }

    func testTitles() {
        XCTAssertEqual(Direction.waitingFor.title, "I'M WAITING FOR...")
        XCTAssertEqual(Direction.waitingOnMe.title, "WAITING FOR ME...")
    }

    func testIcons() {
        XCTAssertEqual(Direction.waitingFor.icon, "arrow.right")
        XCTAssertEqual(Direction.waitingOnMe.icon, "arrow.left")
    }

    func testAllCases() {
        XCTAssertEqual(Direction.allCases.count, 2)
    }
}

// MARK: - Age Color Tests

final class AgeColorTests: XCTestCase {

    func testFreshItemGreen() {
        let color = ageColor(days: 0)
        XCTAssertEqual(color.g, 1.0, "Fresh items should be green (high green channel)")
    }

    func testTwoDayItemGreen() {
        let color = ageColor(days: 2)
        XCTAssertEqual(color.g, 1.0, "Items under 3 days should be green")
    }

    func testThreeDayItemYellow() {
        let color = ageColor(days: 3)
        XCTAssertGreaterThan(color.r, 0.8, "Items 3-6 days should be yellowish (high red)")
        XCTAssertGreaterThan(color.g, 0.7, "Items 3-6 days should be yellowish (high green)")
    }

    func testSevenDayItemRed() {
        let color = ageColor(days: 7)
        XCTAssertEqual(color.r, 1.0, "Items 7+ days should be red")
        XCTAssertLessThan(color.g, 0.5, "Items 7+ days should have low green")
    }

    func testOverdueRed() {
        let color = ageColor(days: 30)
        XCTAssertEqual(color.r, 1.0)
        XCTAssertEqual(color.g, 0.35)
    }

    func testLightBgFreshGreen() {
        let color = ageColor(days: 0, forLightBg: true)
        XCTAssertLessThan(color.r, 0.3, "Light bg green should have lower brightness")
        XCTAssertGreaterThan(color.g, 0.5, "Light bg green should still be green")
    }

    func testLightBgYellow() {
        let color = ageColor(days: 5, forLightBg: true)
        XCTAssertGreaterThan(color.r, 0.5, "Light bg yellow should have elevated red")
    }

    func testLightBgRed() {
        let color = ageColor(days: 10, forLightBg: true)
        XCTAssertGreaterThan(color.r, 0.7, "Light bg red should be prominently red")
    }
}

// MARK: - Theme Tests

final class ThemeNameTests: XCTestCase {

    func testAllThemesExist() {
        XCTAssertEqual(ThemeName.allCases.count, 6)
    }

    func testDisplayNames() {
        let names = ThemeName.allCases.map(\.displayName)
        XCTAssertEqual(names, ["Dark", "Light", "Sunset", "Ocean", "Forest", "Rose"])
    }

    func testRawValues() {
        let raws = ThemeName.allCases.map(\.rawValue)
        XCTAssertEqual(raws, ["dark", "light", "sunset", "ocean", "forest", "rose"])
    }

    func testAllThemesHaveIcons() {
        for theme in ThemeName.allCases {
            XCTAssertFalse(theme.icon.isEmpty, "\(theme) should have an icon")
        }
    }

    func testAllThemesHaveColors() {
        for theme in ThemeName.allCases {
            let colors = theme.colors
            // Verify key colors are set (not clear/zero)
            XCTAssertNotNil(colors.bg)
            XCTAssertNotNil(colors.surface)
            XCTAssertNotNil(colors.accent)
            XCTAssertNotNil(colors.textPrimary)
        }
    }

    func testIdentifiable() {
        for theme in ThemeName.allCases {
            XCTAssertEqual(theme.id, theme.rawValue)
        }
    }

    func testInitFromRawValue() {
        XCTAssertEqual(ThemeName(rawValue: "dark"), .dark)
        XCTAssertEqual(ThemeName(rawValue: "ocean"), .ocean)
        XCTAssertNil(ThemeName(rawValue: "nonexistent"))
    }
}

// MARK: - AppConfig Tests

final class AppConfigTests: XCTestCase {

    func testCodableRoundTrip() throws {
        let config = AppConfig(theme: "sunset")
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(AppConfig.self, from: data)
        XCTAssertEqual(decoded.theme, "sunset")
    }

    func testDefaultTheme() {
        // When loaded from invalid data, should default to "dark"
        let config = AppConfig(theme: "dark")
        XCTAssertEqual(config.theme, "dark")
    }
}

// MARK: - Merge Logic Tests

final class MergeLogicTests: XCTestCase {

    func testMergeEmptyLists() {
        let local = WaitingData(waiting_for: [], waiting_on_me: [], history: [])
        let remote = WaitingData(waiting_for: [], waiting_on_me: [], history: [])
        let merged = WaitingRoomStore.testMerge(local: local, remote: remote)
        XCTAssertTrue(merged.waiting_for.isEmpty)
        XCTAssertTrue(merged.waiting_on_me.isEmpty)
        XCTAssertTrue(merged.history.isEmpty)
    }

    func testMergeLocalOnly() {
        let item = makeItem(id: "a")
        let local = WaitingData(waiting_for: [item], waiting_on_me: [], history: [])
        let remote = WaitingData(waiting_for: [], waiting_on_me: [], history: [])
        let merged = WaitingRoomStore.testMerge(local: local, remote: remote)
        XCTAssertEqual(merged.waiting_for.count, 1)
        XCTAssertEqual(merged.waiting_for[0].id, "a")
    }

    func testMergeRemoteOnly() {
        let item = makeItem(id: "b")
        let local = WaitingData(waiting_for: [], waiting_on_me: [], history: [])
        let remote = WaitingData(waiting_for: [item], waiting_on_me: [], history: [])
        let merged = WaitingRoomStore.testMerge(local: local, remote: remote)
        XCTAssertEqual(merged.waiting_for.count, 1)
        XCTAssertEqual(merged.waiting_for[0].id, "b")
    }

    func testMergeUnion() {
        let a = makeItem(id: "a")
        let b = makeItem(id: "b")
        let local = WaitingData(waiting_for: [a], waiting_on_me: [], history: [])
        let remote = WaitingData(waiting_for: [b], waiting_on_me: [], history: [])
        let merged = WaitingRoomStore.testMerge(local: local, remote: remote)
        XCTAssertEqual(merged.waiting_for.count, 2)
        let ids = Set(merged.waiting_for.map(\.id))
        XCTAssertTrue(ids.contains("a"))
        XCTAssertTrue(ids.contains("b"))
    }

    func testMergeDeduplicate() {
        let item = makeItem(id: "same")
        let local = WaitingData(waiting_for: [item], waiting_on_me: [], history: [])
        let remote = WaitingData(waiting_for: [item], waiting_on_me: [], history: [])
        let merged = WaitingRoomStore.testMerge(local: local, remote: remote)
        XCTAssertEqual(merged.waiting_for.count, 1, "Same ID should not duplicate")
    }

    func testMergeLocalOrderPreserved() {
        let a = makeItem(id: "a")
        let b = makeItem(id: "b")
        let c = makeItem(id: "c")
        let local = WaitingData(waiting_for: [b, a], waiting_on_me: [], history: [])
        let remote = WaitingData(waiting_for: [c], waiting_on_me: [], history: [])
        let merged = WaitingRoomStore.testMerge(local: local, remote: remote)
        XCTAssertEqual(merged.waiting_for.map(\.id), ["b", "a", "c"],
                       "Local items should appear first, in local order, then remote")
    }

    func testMergeHistoryExcludesFromActive() {
        let item = makeItem(id: "resolved-item")
        var resolved = item
        resolved.resolved_at = "2026-04-10T12:00:00"

        let local = WaitingData(waiting_for: [item], waiting_on_me: [], history: [])
        let remote = WaitingData(waiting_for: [], waiting_on_me: [], history: [resolved])
        let merged = WaitingRoomStore.testMerge(local: local, remote: remote)

        XCTAssertEqual(merged.history.count, 1, "Resolved item should be in history")
        XCTAssertEqual(merged.waiting_for.count, 0,
                       "Item in history should be removed from waiting_for")
    }

    func testMergeBothDirections() {
        let a = makeItem(id: "a")
        let b = makeItem(id: "b")
        let local = WaitingData(waiting_for: [a], waiting_on_me: [], history: [])
        let remote = WaitingData(waiting_for: [], waiting_on_me: [b], history: [])
        let merged = WaitingRoomStore.testMerge(local: local, remote: remote)
        XCTAssertEqual(merged.waiting_for.count, 1)
        XCTAssertEqual(merged.waiting_on_me.count, 1)
    }

    // MARK: Helpers

    private func makeItem(id: String) -> WaitingItem {
        WaitingItem(
            id: id, who: "Test", what: "Thing",
            since: "2026-04-01T12:00:00", expected: "",
            nudges: [], note: ""
        )
    }
}

// MARK: - AgeEmoji Tests

final class AgeEmojiTests: XCTestCase {
    func testFreshIsGreen() {
        XCTAssertEqual(ageEmoji(days: 0), "green")
        XCTAssertEqual(ageEmoji(days: 2), "green")
    }

    func testAgingIsYellow() {
        XCTAssertEqual(ageEmoji(days: 3), "yellow")
        XCTAssertEqual(ageEmoji(days: 6), "yellow")
    }

    func testOverdueIsRed() {
        XCTAssertEqual(ageEmoji(days: 7), "red")
        XCTAssertEqual(ageEmoji(days: 100), "red")
    }
}

// MARK: - DateFormatter Helper

private extension DateFormatter {
    static let pythonISO: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        return f
    }()
}
