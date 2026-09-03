import XCTest
@testable import BudgetBuddy

// Data-integrity tests for the bundled content. Every story is a small graph;
// a typo in a `next` or `end` id used to be invisible until a player hit it.
final class StoriesDataTests: XCTestCase {

    func testStoriesDecodeAndGraphsAreWellFormed() {
        let all = StoryStore.all
        XCTAssertGreaterThanOrEqual(all.count, 33, "stories.json failed to decode (or lost stories)")
        for s in all {
            XCTAssertNotNil(s.scenes[s.start], "\(s.id): start scene '\(s.start)' missing")
            XCTAssertFalse(s.endings.isEmpty, "\(s.id): no endings")

            var reach = Set<String>(), todo = [s.start]
            while let n = todo.popLast() {
                guard !reach.contains(n), let sc = s.scenes[n] else { continue }
                reach.insert(n)
                todo.append(contentsOf: sc.choices.compactMap(\.next))
            }
            XCTAssertEqual(reach, Set(s.scenes.keys),
                           "\(s.id): unreachable scenes \(Set(s.scenes.keys).subtracting(reach).sorted())")

            for (k, sc) in s.scenes {
                XCTAssertFalse(sc.narrator.isEmpty, "\(s.id)/\(k): empty narrator")
                for c in sc.choices {
                    if let nx = c.next { XCTAssertNotNil(s.scenes[nx], "\(s.id)/\(k): next '\(nx)' missing") }
                    if let e = c.end { XCTAssertNotNil(s.endings[e], "\(s.id)/\(k): end '\(e)' missing") }
                    if let score = c.score { XCTAssertTrue((0...2).contains(score), "\(s.id)/\(k): score \(score)") }
                }
            }
            // Score-ranked stories need at least one ending with a threshold;
            // choice-routed stories (`end`) need none. Both must resolve.
            let ranked = s.endings.values.contains { $0.min != nil }
            let routed = s.scenes.values.flatMap(\.choices).contains { $0.end != nil }
            XCTAssertTrue(ranked || routed, "\(s.id): no way to reach an ending")
        }
    }

    func testLessonsAndCodexDecode() {
        XCTAssertGreaterThanOrEqual(LessonStore.all.count, 12)
        XCTAssertFalse(CodexStore.all.isEmpty)
    }

    func testEveryChineseStoryStringHasEnglish() {
        var missing: [String] = []
        func check(_ s: String?, _ at: String) {
            guard let s, s.range(of: "\\p{Han}", options: .regularExpression) != nil else { return }
            if L10n.contentEN[s] == nil && L10n.en[s] == nil { missing.append("\(at): \(s.prefix(30))") }
        }
        for s in StoryStore.all {
            check(s.title, s.id); check(s.desc, s.id); check(s.intro, s.id)
            for (k, sc) in s.scenes {
                let at = "\(s.id)/\(k)"
                check(sc.setting, at); check(sc.sceneTitle, at); check(sc.narrator, at); check(sc.npcLine, at)
                for c in sc.choices { check(c.label, at); check(c.hint, at); check(c.consequence, at); check(c.tip, at) }
            }
            for (ek, e) in s.endings {
                let at = "\(s.id)/ending.\(ek)"
                check(e.title, at); check(e.did_well, at); check(e.improve, at); check(e.habit, at)
            }
        }
        XCTAssertTrue(missing.isEmpty, "Untranslated story strings (\(missing.count)):\n" + missing.prefix(25).joined(separator: "\n"))
    }
}
