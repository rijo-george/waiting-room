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

    func testEmptyStringReturnsNil() {
        XCTAssertNil(ISO8601Flexible.date(from: ""))
    }

    func testGarbageReturnsNil() {
        XCTAssertNil(ISO8601Flexible.date(from: "not-a-date"))
    }

    func testOversizedMicroseconds() {
        let date = ISO8601Flexible.date(from: "2026-04-05T12:31:42.357149999999")
        XCTAssertNotNil(date, "Should handle oversized microsecond strings")
    }
}

// MARK: - WaitingItem Tests

final class WaitingItemTests: XCTestCase {

    func testAgeDaysForToday() {
        let now = pythonISO(Date())
        let item = makeItem(since: now)
        XCTAssertEqual(item.ageDays, 0)
    }

    func testAgeDaysForPastDate() {
        let fiveDaysAgo = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let item = makeItem(since: pythonISO(fiveDaysAgo))
        XCTAssertEqual(item.ageDays, 5)
    }

    func testAgeDaysForInvalidDate() {
        let item = makeItem(since: "garbage")
        XCTAssertEqual(item.ageDays, 0)
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
        XCTAssertEqual(item.expectedDisplay, "next week")
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

    func testHashEquality() {
        let a = makeItem(id: "same")
        let b = makeItem(id: "same")
        XCTAssertEqual(a, b, "Items with same ID should be equal")
        XCTAssertEqual(a.hashValue, b.hashValue)
    }

    func testHashInequality() {
        let a = makeItem(id: "one")
        let b = makeItem(id: "two")
        XCTAssertNotEqual(a, b)
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

    private func pythonISO(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        return f.string(from: date)
    }
}

// MARK: - Nudge Tests

final class NudgeTests: XCTestCase {

    func testNudgeIdentifiable() {
        let nudge = Nudge(at: "2026-04-05T12:00:00", note: "emailed")
        XCTAssertEqual(nudge.id, "2026-04-05T12:00:00")
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
        let data = WaitingData(waiting_for: [item], waiting_on_me: [], history: [])
        let encoded = try JSONEncoder().encode(data)
        let decoded = try JSONDecoder().decode(WaitingData.self, from: encoded)
        XCTAssertEqual(decoded.waiting_for.count, 1)
        XCTAssertEqual(decoded.waiting_for[0].who, "Bob")
        XCTAssertEqual(decoded.waiting_for[0].nudges.count, 1)
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
        XCTAssertEqual(decoded.history[0].resolved_at, "2026-04-12T14:30:00")
        XCTAssertEqual(decoded.history[0].direction, "waiting_for")
        XCTAssertEqual(decoded.history[0].duration_days, 11)
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

    func testShortTitles() {
        XCTAssertEqual(Direction.waitingFor.shortTitle, "Waiting For")
        XCTAssertEqual(Direction.waitingOnMe.shortTitle, "Waiting On Me")
    }

    func testIcons() {
        XCTAssertEqual(Direction.waitingFor.icon, "arrow.right")
        XCTAssertEqual(Direction.waitingOnMe.icon, "arrow.left")
    }

    func testTabIcons() {
        XCTAssertEqual(Direction.waitingFor.tabIcon, "arrow.right.circle.fill")
        XCTAssertEqual(Direction.waitingOnMe.tabIcon, "arrow.left.circle.fill")
    }

    func testAllCases() {
        XCTAssertEqual(Direction.allCases.count, 2)
    }
}

// MARK: - Age Color Tests

final class AgeColorTests: XCTestCase {

    func testFreshItemGreen() {
        let color = ageColor(days: 0)
        XCTAssertEqual(color.g, 1.0)
    }

    func testThreeDayItemYellow() {
        let color = ageColor(days: 3)
        XCTAssertGreaterThan(color.r, 0.8)
        XCTAssertGreaterThan(color.g, 0.7)
    }

    func testSevenDayItemRed() {
        let color = ageColor(days: 7)
        XCTAssertEqual(color.r, 1.0)
        XCTAssertLessThan(color.g, 0.5)
    }

    func testLightBgFreshGreen() {
        let color = ageColor(days: 0, forLightBg: true)
        XCTAssertLessThan(color.r, 0.3)
        XCTAssertGreaterThan(color.g, 0.5)
    }

    func testLightBgRed() {
        let color = ageColor(days: 10, forLightBg: true)
        XCTAssertGreaterThan(color.r, 0.7)
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
    }

    func testMergeRemoteOnly() {
        let item = makeItem(id: "b")
        let local = WaitingData(waiting_for: [], waiting_on_me: [], history: [])
        let remote = WaitingData(waiting_for: [item], waiting_on_me: [], history: [])
        let merged = WaitingRoomStore.testMerge(local: local, remote: remote)
        XCTAssertEqual(merged.waiting_for.count, 1)
    }

    func testMergeUnion() {
        let a = makeItem(id: "a")
        let b = makeItem(id: "b")
        let local = WaitingData(waiting_for: [a], waiting_on_me: [], history: [])
        let remote = WaitingData(waiting_for: [b], waiting_on_me: [], history: [])
        let merged = WaitingRoomStore.testMerge(local: local, remote: remote)
        XCTAssertEqual(merged.waiting_for.count, 2)
    }

    func testMergeDeduplicate() {
        let item = makeItem(id: "same")
        let local = WaitingData(waiting_for: [item], waiting_on_me: [], history: [])
        let remote = WaitingData(waiting_for: [item], waiting_on_me: [], history: [])
        let merged = WaitingRoomStore.testMerge(local: local, remote: remote)
        XCTAssertEqual(merged.waiting_for.count, 1)
    }

    func testMergeHistoryExcludesFromActive() {
        let item = makeItem(id: "resolved-item")
        var resolved = item
        resolved.resolved_at = "2026-04-10T12:00:00"

        let local = WaitingData(waiting_for: [item], waiting_on_me: [], history: [])
        let remote = WaitingData(waiting_for: [], waiting_on_me: [], history: [resolved])
        let merged = WaitingRoomStore.testMerge(local: local, remote: remote)

        XCTAssertEqual(merged.history.count, 1)
        XCTAssertEqual(merged.waiting_for.count, 0,
                       "Item in history should be removed from active lists")
    }

    func testMergePreservesLocalOrder() {
        let a = makeItem(id: "a")
        let b = makeItem(id: "b")
        let c = makeItem(id: "c")
        let local = WaitingData(waiting_for: [b, a], waiting_on_me: [], history: [])
        let remote = WaitingData(waiting_for: [c], waiting_on_me: [], history: [])
        let merged = WaitingRoomStore.testMerge(local: local, remote: remote)
        XCTAssertEqual(merged.waiting_for.map(\.id), ["b", "a", "c"])
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

// MARK: - Theme Tests

final class ThemeNameTests: XCTestCase {

    func testAllThemesExist() {
        XCTAssertEqual(ThemeName.allCases.count, 6)
    }

    func testDisplayNames() {
        let names = ThemeName.allCases.map(\.displayName)
        XCTAssertEqual(names, ["Dark", "Light", "Sunset", "Ocean", "Forest", "Rose"])
    }

    func testIsDark() {
        XCTAssertTrue(ThemeName.dark.isDark)
        XCTAssertFalse(ThemeName.light.isDark)
        XCTAssertTrue(ThemeName.sunset.isDark)
        XCTAssertTrue(ThemeName.ocean.isDark)
        XCTAssertTrue(ThemeName.forest.isDark)
        XCTAssertTrue(ThemeName.rose.isDark)
    }

    func testAllThemesHaveIcons() {
        for theme in ThemeName.allCases {
            XCTAssertFalse(theme.icon.isEmpty, "\(theme) should have an icon")
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
}
