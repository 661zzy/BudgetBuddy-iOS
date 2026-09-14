import XCTest
@testable import BudgetBuddy

final class BlitzTests: XCTestCase {

    private func clearBlitzState() {
        let d = UserDefaults.standard
        for k in d.dictionaryRepresentation().keys where k.hasPrefix("bb.blitz.") { d.removeObject(forKey: k) }
    }
    // UI tests share this simulator's defaults, so start and end every test clean.
    override func setUp() { super.setUp(); clearBlitzState() }
    override func tearDown() { clearBlitzState(); super.tearDown() }

    // MARK: question bank

    func testBankIsWellFormed() {
        let bank = BlitzStore.bank
        XCTAssertEqual(bank.packs.count, 6, "quiz.json failed to decode or lost a pack")
        XCTAssertGreaterThanOrEqual(bank.questions.count, 48)
        XCTAssertEqual(Set(bank.questions.map(\.id)).count, bank.questions.count, "duplicate question ids")
        let packIds = Set(bank.packs.map(\.id))
        for p in bank.packs {
            XCTAssertGreaterThanOrEqual(BlitzStore.questions(in: p.id).count, 5, "\(p.id) is too small to play")
            XCTAssertFalse(p.titleEN.isEmpty)
        }
        for q in bank.questions {
            XCTAssertTrue(packIds.contains(q.pack), "\(q.id): unknown pack \(q.pack)")
            XCTAssertFalse(q.q.isEmpty || q.qEN.isEmpty || q.why.isEmpty || q.whyEN.isEmpty, "\(q.id): missing text")
            switch q.type {
            case "quiz":
                let o = q.options ?? [], oe = q.optionsEN ?? []
                XCTAssertTrue((2...4).contains(o.count), "\(q.id): \(o.count) options")
                XCTAssertEqual(o.count, oe.count, "\(q.id): EN option count differs")
                XCTAssertTrue(o.indices.contains(q.answer ?? -1), "\(q.id): answer out of range")
                XCTAssertEqual(Set(o).count, o.count, "\(q.id): duplicate options")
            case "tf":
                XCTAssertTrue([0, 1].contains(q.answer ?? -1), "\(q.id): tf answer must be 0/1")
            case "slider":
                guard let lo = q.min, let hi = q.max, let st = q.step, let v = q.value, let tol = q.tol else {
                    return XCTFail("\(q.id): slider fields missing")
                }
                XCTAssertLessThan(lo, hi); XCTAssertGreaterThan(st, 0); XCTAssertGreaterThanOrEqual(tol, 0)
                XCTAssertTrue((lo...hi).contains(v), "\(q.id): answer outside the slider")
                let steps = (v - lo) / st
                XCTAssertEqual(steps, steps.rounded(), accuracy: 1e-9, "\(q.id): answer not reachable by step")
                XCTAssertFalse((q.unit ?? "").isEmpty || (q.unitEN ?? "").isEmpty, "\(q.id): unit missing")
            default:
                XCTFail("\(q.id): unknown type \(q.type)")
            }
        }
    }

    /// Test-writing flaw guard: the right answer must not be the visibly longest one.
    func testCorrectOptionIsNotALengthGiveaway() {
        func width(_ s: String) -> Double {
            s.unicodeScalars.reduce(0) { $0 + ($1.value >= 0x2E80 ? 1 : 0.5) }
        }
        for q in BlitzStore.bank.questions where q.type == "quiz" && (q.options?.count ?? 0) > 2 {
            let o = q.options!, a = q.answer!
            let others = o.indices.filter { $0 != a }.map { width(o[$0]) }
            XCTAssertLessThan(width(o[a]) - (others.max() ?? 0), 2, "\(q.id): correct option is noticeably longest")
        }
    }

    // MARK: scoring — Kahoot's published rules

    func testPointsFormula() {
        XCTAssertEqual(BlitzScore.points(correct: true, elapsed: 0.3, limit: 20), 1000, "< 0.5 s is full marks")
        XCTAssertEqual(BlitzScore.points(correct: true, elapsed: 2, limit: 30), 966)   // floor(966.67)
        XCTAssertEqual(BlitzScore.points(correct: true, elapsed: 10, limit: 20), 750)
        XCTAssertEqual(BlitzScore.points(correct: true, elapsed: 20, limit: 20), 500, "last second still earns half")
        XCTAssertEqual(BlitzScore.points(correct: true, elapsed: 99, limit: 20), 500, "clamped at the limit")
        XCTAssertEqual(BlitzScore.points(correct: false, elapsed: 1, limit: 20), 0)
    }

    func testStreakBonus() {
        XCTAssertEqual([0, 1, 2, 3, 6, 9].map(BlitzScore.streakBonus), [0, 0, 100, 200, 500, 500])
    }

    func testSliderTolerance() {
        let q = BlitzStore.find("b3")!          // 450, tol 20
        XCTAssertTrue(BlitzScore.sliderCorrect(q, 470))
        XCTAssertTrue(BlitzScore.sliderCorrect(q, 430))
        XCTAssertFalse(BlitzScore.sliderCorrect(q, 480))
    }

    // MARK: determinism

    func testRivalsAndDailySetAreStable() {
        let q = BlitzStore.find("s3")!
        for r in BlitzRival.all {
            let a = r.play(q, seed: "x"), b = r.play(q, seed: "x")
            XCTAssertEqual(a.correct, b.correct); XCTAssertEqual(a.elapsed, b.elapsed, accuracy: 1e-12)
            XCTAssertTrue((0...q.limit).contains(a.elapsed))
        }
        let day = Date(timeIntervalSince1970: 1_790_000_000)
        let d1 = BlitzProgress.dailyQuestions(date: day).map(\.id)
        let d2 = BlitzProgress.dailyQuestions(date: day).map(\.id)
        XCTAssertEqual(d1, d2); XCTAssertEqual(d1.count, 5); XCTAssertEqual(Set(d1).count, 5)
    }

    func testImpulsiveRivalIsFastButLessAccurate() {
        let qs = BlitzStore.bank.questions
        func stats(_ id: String) -> (acc: Double, time: Double) {
            let r = BlitzRival.all.first { $0.id == id }!
            let res = qs.map { r.play($0, seed: "calib") }
            return (Double(res.filter(\.correct).count) / Double(res.count),
                    res.map { $0.elapsed }.reduce(0, +) / Double(res.count))
        }
        let ajie = stats("ajie"), xiaoyu = stats("xiaoyu")
        XCTAssertLessThan(ajie.time, xiaoyu.time, "the impulsive rival should answer faster")
        XCTAssertLessThan(ajie.acc, xiaoyu.acc, "…and be wrong more often, which is the lesson")
    }

    // MARK: a whole round through the engine

    @MainActor
    func testFullRoundScoresStreaksAndSavesGhost() {
        let game = BlitzGame(mode: .pack("budget"))
        XCTAssertEqual(game.questions.count, 8)
        var t = Date()
        game.tick(t.addingTimeInterval(game.readyDuration + 0.01)); XCTAssertEqual(game.phase, .reading)
        t = game.phaseStart
        for i in 0..<game.questions.count {
            game.tick(t.addingTimeInterval(game.readingDuration + 0.01))
            XCTAssertEqual(game.phase, .answering, "q\(i) should be open")
            let q = game.questions[i]
            let answerAt = game.phaseStart.addingTimeInterval(0.2)
            if q.isSlider { game.sliderValue = q.value!; game.submitSlider(now: answerAt) }
            else { game.pick(game.correctSlot(i)!, now: answerAt) }
            XCTAssertEqual(game.phase, .reveal)
            XCTAssertTrue(game.lastCorrect, "q\(i) \(q.id) should be correct")
            XCTAssertEqual(game.lastPoints, 1000, "answered in 0.2 s")
            XCTAssertEqual(game.streak, i + 1)
            t = Date()
            game.next(now: t)
        }
        XCTAssertEqual(game.phase, .podium)
        // 8 × 1000 + streak bonuses 0,100,200,300,400,500,500,500
        XCTAssertEqual(game.total, 8000 + 2500)
        XCTAssertEqual(game.yourRank, 1)
        XCTAssertTrue(game.firstPlay)
        XCTAssertFalse(game.newRecord, "a first play is not a 'new record'")
        XCTAssertEqual(BlitzProgress.best("budget"), 10_500)
        XCTAssertEqual(BlitzProgress.ghost("budget").last, 10_500)
        XCTAssertTrue(BlitzProgress.mistakes.isEmpty)

        // The next round has "you, last time" in the room.
        let rematch = BlitzGame(mode: .pack("budget"))
        XCTAssertTrue(rematch.standings.contains { $0.id == "ghost" })
    }

    @MainActor
    func testTimeoutIsWrongAndLandsInTheMistakeBank() {
        let game = BlitzGame(mode: .pack("scam"))
        game.tick(Date().addingTimeInterval(game.readyDuration + 0.01))
        game.tick(game.phaseStart.addingTimeInterval(game.readingDuration + 0.01))
        let q = game.questions[0]
        game.tick(game.phaseStart.addingTimeInterval(q.limit + 0.1))
        XCTAssertEqual(game.phase, .reveal)
        XCTAssertTrue(game.timedOut); XCTAssertFalse(game.lastCorrect); XCTAssertEqual(game.total, 0)
        XCTAssertEqual(BlitzProgress.mistakes.first, q.id)
    }

    @MainActor
    func testQuizOptionsAreShuffledPerRound() {
        // Over a few rounds, the correct answer must not always sit in the same slot.
        var slots = Set<Int>()
        for _ in 0..<12 {
            let g = BlitzGame(mode: .pack("budget"))
            let i = g.questions.firstIndex { $0.id == "b1" }!
            slots.insert(g.correctSlot(i)!)
        }
        XCTAssertGreaterThan(slots.count, 1)
    }

    /// Cross-platform contract: these vectors were computed by an independent Python
    /// implementation of the spec (设计说明 · 对手). Android checks the same file.
    func testRivalVectorsMatchSpec() {
        let vectors: [(String, String, String, Bool, Double)] = [
            ("xiaoyu", "b1", "pack|budget", true, 11.686127),
            ("xiaoyu", "b1", "daily|2026-09-12", false, 12.29721),
            ("xiaoyu", "s3", "pack|budget", true, 10.68835),
            ("xiaoyu", "s3", "daily|2026-09-12", false, 10.991406),
            ("xiaoyu", "c2", "pack|budget", false, 18.16435),
            ("xiaoyu", "c2", "daily|2026-09-12", false, 12.442884),
            ("xiaoyu", "t7", "pack|budget", true, 11.732917),
            ("xiaoyu", "t7", "daily|2026-09-12", true, 9.977813),
            ("xiaolin", "b1", "pack|budget", true, 5.37391),
            ("xiaolin", "b1", "daily|2026-09-12", true, 7.113566),
            ("xiaolin", "s3", "pack|budget", true, 7.138458),
            ("xiaolin", "s3", "daily|2026-09-12", true, 8.915442),
            ("xiaolin", "c2", "pack|budget", true, 7.085681),
            ("xiaolin", "c2", "daily|2026-09-12", true, 11.019257),
            ("xiaolin", "t7", "pack|budget", false, 9.570995),
            ("xiaolin", "t7", "daily|2026-09-12", true, 8.840615),
            ("ajie", "b1", "pack|budget", true, 5.093556),
            ("ajie", "b1", "daily|2026-09-12", true, 0.942595),
            ("ajie", "s3", "pack|budget", false, 1.625586),
            ("ajie", "s3", "daily|2026-09-12", false, 2.373666),
            ("ajie", "c2", "pack|budget", false, 6.984245),
            ("ajie", "c2", "daily|2026-09-12", false, 3.313176),
            ("ajie", "t7", "pack|budget", false, 1.927999),
            ("ajie", "t7", "daily|2026-09-12", true, 5.20791)
        ]
        for (rid, qid, seed, correct, elapsed) in vectors {
            let r = BlitzRival.all.first { $0.id == rid }!
            let got = r.play(BlitzStore.find(qid)!, seed: seed)
            XCTAssertEqual(got.correct, correct, "\(rid)|\(qid)|\(seed)")
            XCTAssertEqual(got.elapsed, elapsed, accuracy: 1e-5, "\(rid)|\(qid)|\(seed)")
        }
    }

    /// v1.6.1: today's five stay the same even after the mistake bank changes.
    func testDailySetIsFrozenForTheDay() {
        let today = Date()
        let first = BlitzProgress.dailyQuestions(date: today).map(\.id)
        // Answer three questions wrong: the bank now leads with them.
        let others = BlitzStore.bank.questions.map(\.id).filter { !first.contains($0) }
        for id in others.prefix(3) { BlitzProgress.record(id, correct: false) }
        XCTAssertEqual(BlitzProgress.dailyQuestions(date: today).map(\.id), first, "same five all day")
        // A new day draws fresh, putting the mistakes first.
        let tomorrow = today.addingTimeInterval(86_400)
        let next = BlitzProgress.dailyQuestions(date: tomorrow).map(\.id)
        // The bank is newest-first, so the two most recent misses lead tomorrow's set.
        XCTAssertEqual(Array(next.prefix(2)), [others[2], others[1]], "tomorrow's set starts from the mistake bank")
    }
}
