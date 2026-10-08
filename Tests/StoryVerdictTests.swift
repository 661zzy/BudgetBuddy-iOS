import XCTest
@testable import BudgetBuddy

// The red "wrong move" alert fires on exactly the choices judged .wrong, so the
// rule and the content it reads must stay in step.
final class StoryVerdictTests: XCTestCase {

    private func scene(_ scores: [Int?]) -> StoryScene {
        let choices = scores.enumerated().map { i, s in
            Choice(label: "c\(i)", hint: nil, effects: nil, consequence: nil, tip: nil, score: s, next: nil, end: nil)
        }
        return StoryScene(setting: nil, sceneTitle: nil, emoji: nil, npcName: nil, npcLine: nil,
                          narrator: "n", isFinal: nil, choices: choices)
    }

    func testVerdictRule() {
        let sc = scene([2, 1, 0])
        XCTAssertEqual(sc.verdict(for: sc.choices[0]), .best)
        XCTAssertEqual(sc.verdict(for: sc.choices[1]), .okay)
        XCTAssertEqual(sc.verdict(for: sc.choices[2]), .wrong)
        XCTAssertEqual(sc.bestChoices.map(\.label), ["c0"])
    }

    func testTwoRightAnswersAreBothBest() {
        let sc = scene([2, 2, 0])
        XCTAssertEqual(sc.bestChoices.map(\.label), ["c0", "c1"])
        XCTAssertEqual(sc.verdict(for: sc.choices[1]), .best)
    }

    func testSceneWithoutARightAnswerNeverScolds() {
        let sc = scene([0, 0, nil])
        for c in sc.choices { XCTAssertEqual(sc.verdict(for: c), .neutral) }
        XCTAssertTrue(sc.bestChoices.isEmpty)
    }

    func testMissingScoreCountsAsWrongWhenABetterMoveExists() {
        let sc = scene([2, nil])
        XCTAssertEqual(sc.verdict(for: sc.choices[1]), .wrong)
    }

    // Every wrong pick in the shipped stories can explain itself in both languages.
    func testEveryWrongChoiceInTheContentHasWhatTheAlertShows() {
        var wrong = 0
        for s in StoryStore.all {
            for (k, sc) in s.scenes {
                for c in sc.choices where sc.verdict(for: c) == .wrong {
                    wrong += 1
                    XCTAssertNotNil(c.consequence, "\(s.id)/\(k): wrong choice has no consequence")
                    XCTAssertNotNil(c.tip, "\(s.id)/\(k): wrong choice has no tip")
                    XCTAssertFalse(sc.bestChoices.isEmpty, "\(s.id)/\(k): no better move to show")
                    for text in [c.label, c.consequence, c.tip].compactMap({ $0 }) + sc.bestChoices.map(\.label) {
                        XCTAssertNotNil(L10n.contentEN[text], "\(s.id)/\(k): missing English for \(text.prefix(20))")
                    }
                }
            }
        }
        XCTAssertGreaterThan(wrong, 100, "expected the content to contain many trap choices")
    }

    func testAlertStringsAreTranslated() {
        for key in ["这一步有坑", "没关系，看清楚了下次就能躲开", "你选的是", "接下来会发生什么", "为什么要小心",
                    "下次可以这样做", "我记住了", "好选择", "还能更好", "这步有坑"] {
            XCTAssertNotNil(L10n.en[key], "no English for \(key)")
        }
    }
}
