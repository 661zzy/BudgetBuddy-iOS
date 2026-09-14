import XCTest
@testable import BudgetBuddy

final class FeedbackInboxTests: XCTestCase {

    /// Exactly what backend 4.9 returns from POST /feedback/threads (captured from the local run).
    private let serverJSON = """
    {"threads":[{"id":7,"message":"能不能加自定义分类","imageCount":1,"status":"replied","createdAt":1789398000,
      "updatedAt":1789401600,"unread":1,"messages":[{"id":3,"author":"team","body":"1.6.1 已经加上了","createdAt":1789401600}]},
     {"id":5,"message":"","imageCount":0,"status":"open","createdAt":1789300000,"updatedAt":1789300000,"unread":0,"messages":[]}],
     "unread":1}
    """

    private func stubDefaults(_ json: String) -> UserDefaults {
        let d = UserDefaults(suiteName: "FeedbackInboxTests-\(UUID().uuidString)")!
        d.set(json, forKey: FeedbackInbox.stubKey)
        return d
    }

    func testDecodesServerShape() throws {
        let r = try JSONDecoder().decode(FeedbackThreadsResponse.self, from: Data(serverJSON.utf8))
        XCTAssertEqual(r.unread, 1)
        XCTAssertEqual(r.threads.map(\.id), [7, 5])
        let t = r.threads[0]
        XCTAssertEqual(t.imageCount, 1)
        XCTAssertTrue(t.messages[0].isTeam)
        XCTAssertTrue(t.hasTeamReply)
        XCTAssertEqual(t.preview, "1.6.1 已经加上了")
        XCTAssertEqual(r.threads[1].preview, "（只发送了诊断信息）", "empty message falls back")
    }

    func testStatusLabels() throws {
        let r = try JSONDecoder().decode(FeedbackThreadsResponse.self, from: Data(serverJSON.utf8))
        var t = r.threads[0]
        XCTAssertEqual(t.statusLabel, "已回复")
        t.status = "closed"; XCTAssertEqual(t.statusLabel, "已处理")
        t.status = "open"; XCTAssertEqual(t.statusLabel, "等待回复")
        t.status = "something-new"; XCTAssertEqual(t.statusLabel, "等待回复", "unknown statuses read as waiting")
    }

    func testDeviceKeyFormat() {
        XCTAssertTrue(FeedbackKey.isValid(String(repeating: "a1", count: 32)))
        XCTAssertFalse(FeedbackKey.isValid(String(repeating: "A1", count: 32)), "server only accepts lowercase")
        XCTAssertFalse(FeedbackKey.isValid("abc"))
        XCTAssertFalse(FeedbackKey.isValid(String(repeating: "g", count: 64)))
    }

    @MainActor
    func testStubbedInboxReadAndFollowUp() async throws {
        let inbox = FeedbackInbox(defaults: stubDefaults(serverJSON))
        XCTAssertEqual(inbox.unread, 1)
        XCTAssertEqual(inbox.firstUnread?.id, 7)

        await inbox.markRead(7)
        XCTAssertEqual(inbox.unread, 0)
        XCTAssertNil(inbox.firstUnread)

        try await inbox.sendFollowUp("  图标能再多一点吗  ", to: 7)
        let t = try XCTUnwrap(inbox.thread(7))
        XCTAssertEqual(t.messages.map(\.author), ["team", "user"])
        XCTAssertEqual(t.messages.last?.body, "图标能再多一点吗", "trimmed")
        XCTAssertEqual(t.status, "open", "a follow-up reopens the thread")

        try await inbox.sendFollowUp("   ", to: 7)
        XCTAssertEqual(inbox.thread(7)?.messages.count, 2, "blank follow-ups are ignored")

        // A refresh never touches stubbed data.
        await inbox.refresh(signedInAs: 42, force: true)
        XCTAssertEqual(inbox.threads.count, 2)
    }

    @MainActor
    func testApplyMovesUpdatedThreadToTop() throws {
        let inbox = FeedbackInbox(defaults: stubDefaults(serverJSON))
        var fresh = try XCTUnwrap(inbox.thread(5))
        fresh.status = "open"
        fresh.messages = [FeedbackMessage(id: 9, author: "user", body: "补充一下", createdAt: 1789500000)]
        inbox.apply(fresh)
        XCTAssertEqual(inbox.threads.map(\.id), [5, 7])
        XCTAssertEqual(inbox.thread(5)?.messages.count, 1)
    }

    @MainActor
    func testBadStubIsIgnored() {
        let inbox = FeedbackInbox(defaults: stubDefaults("{not json"))
        XCTAssertTrue(inbox.threads.isEmpty)
    }

    func testTimeLabels() {
        let now = Date(timeIntervalSince1970: 1_789_401_600)
        XCTAssertEqual(bbFeedbackTime(now.timeIntervalSince1970 - 20, now: now), "刚刚")
        XCTAssertEqual(bbFeedbackTime(now.timeIntervalSince1970 - 300, now: now), "5 分钟前")
        XCTAssertTrue(bbFeedbackTime(now.timeIntervalSince1970 - 2 * 3600, now: now).hasPrefix("今天 ")
                      || !Calendar.current.isDate(now.addingTimeInterval(-7200), inSameDayAs: now))
        XCTAssertFalse(bbFeedbackTime(now.timeIntervalSince1970 - 3 * 86400, now: now).hasPrefix("今天"))
    }
}
