import SwiftUI
import UIKit

// MARK: - 财商快答 (Money Blitz)
//
// A Kahoot-style quiz for the dry parts of money literacy: a timer, points for
// speed, answer streaks, a standings board after every question and a podium at
// the end. The app is single-player, so the "room" is filled the way Kahoot's
// own ghost mode does it: your previous best run, plus three computer rivals
// whose styles mirror money habits (the impulsive one answers fastest and is
// wrong most often, which is the lesson). Unlike a plain Kahoot, every answer is
// followed by one line of *why*, because feedback is what makes the practice stick.

struct BlitzPack: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let titleEN: String
    let icon: String
    let tint: String
    let fg: String
    var name: String { BBLang.isEN ? titleEN : title }
    var tintColor: Color { Color(hex: UInt(tint, radix: 16) ?? 0xE4EFE7) }
    var fgColor: Color { Color(hex: UInt(fg, radix: 16) ?? 0x3E5F4D) }
}

struct BlitzQuestion: Codable, Identifiable, Hashable {
    let id: String
    let pack: String
    let type: String            // quiz | tf | slider
    let q: String
    let qEN: String
    let options: [String]?
    let optionsEN: [String]?
    let answer: Int?            // quiz/tf: index into the ORIGINAL option order (tf: 0 = true)
    let min: Double?
    let max: Double?
    let step: Double?
    let value: Double?
    let tol: Double?
    let unit: String?
    let unitEN: String?
    let why: String
    let whyEN: String
    let time: Int?

    var text: String { BBLang.isEN ? qEN : q }
    var explanation: String { BBLang.isEN ? whyEN : why }
    var limit: Double { Double(time ?? 20) }
    var isSlider: Bool { type == "slider" }
    var isTrueFalse: Bool { type == "tf" }
    var unitLabel: String { (BBLang.isEN ? unitEN : unit) ?? "" }
    /// Options in their original (authored) order.
    var choices: [String] {
        if isTrueFalse { return ["对".tr, "错".tr] }
        return (BBLang.isEN ? optionsEN : options) ?? []
    }
    var correctText: String {
        if isSlider { return BlitzFormat.number(value ?? 0) + " " + unitLabel }
        let c = choices
        guard let a = answer, c.indices.contains(a) else { return "" }
        return c[a]
    }
}

struct BlitzBank: Codable {
    let packs: [BlitzPack]
    let questions: [BlitzQuestion]
}

enum BlitzStore {
    static let bank: BlitzBank = loadBundleJSON("quiz", as: BlitzBank.self) ?? BlitzBank(packs: [], questions: [])
    static var packs: [BlitzPack] { bank.packs }
    static func pack(_ id: String) -> BlitzPack? { bank.packs.first { $0.id == id } }
    static func questions(in pack: String) -> [BlitzQuestion] { bank.questions.filter { $0.pack == pack } }
    static func find(_ id: String) -> BlitzQuestion? { bank.questions.first { $0.id == id } }
}

enum BlitzFormat {
    static func number(_ v: Double) -> String {
        v.rounded() == v ? String(Int(v)) : String(format: "%.1f", v)
    }
}

// MARK: - Scoring (Kahoot's published rules)

enum BlitzScore {
    static let maxPoints = 1000

    /// points = floor((1 − (t / T) / 2) × 1000); a correct answer inside 0.5 s gets the full 1000.
    static func points(correct: Bool, elapsed: Double, limit: Double) -> Int {
        guard correct, limit > 0 else { return 0 }
        if elapsed < 0.5 { return maxPoints }
        let t = Swift.min(Swift.max(elapsed, 0), limit)
        return Int((1 - (t / limit) / 2) * Double(maxPoints))
    }

    /// +100 for each answer in a streak after the first, capped at +500.
    static func streakBonus(_ streak: Int) -> Int {
        Swift.min(500, Swift.max(0, streak - 1) * 100)
    }

    static func sliderCorrect(_ q: BlitzQuestion, _ v: Double) -> Bool {
        abs(v - (q.value ?? 0)) <= (q.tol ?? 0) + 1e-9
    }
}

// MARK: - Deterministic randomness (rivals and the daily set must not reshuffle on relaunch)

struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(_ seed: String) {
        var h: UInt64 = 0xcbf29ce484222325           // FNV-1a
        for b in seed.utf8 { h ^= UInt64(b); h = h &* 0x100000001b3 }
        state = h == 0 ? 0x9E3779B97F4A7C15 : h
    }
    mutating func next() -> UInt64 {                 // SplitMix64
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
    mutating func unit() -> Double { Double(next() >> 11) / Double(1 << 53) }
}

// MARK: - Rivals

struct BlitzRival: Identifiable {
    let id: String
    let name: String
    let nameEN: String
    let style: String
    let styleEN: String
    let emoji: String
    let accuracy: Double      // chance of a correct answer
    let speed: Double         // typical share of the timer used
    var displayName: String { BBLang.isEN ? nameEN : name }
    var displayStyle: String { BBLang.isEN ? styleEN : style }

    static let all: [BlitzRival] = [
        BlitzRival(id: "xiaoyu", name: "小雨", nameEN: "Rain", style: "学霸型", styleEN: "The studier",
                   emoji: "📚", accuracy: 0.85, speed: 0.6),
        BlitzRival(id: "xiaolin", name: "小林", nameEN: "Lin", style: "稳健型", styleEN: "The steady one",
                   emoji: "🧭", accuracy: 0.75, speed: 0.38),
        BlitzRival(id: "ajie", name: "阿杰", nameEN: "Jay", style: "冲动型", styleEN: "The impulsive one",
                   emoji: "⚡️", accuracy: 0.55, speed: 0.16),
    ]

    /// One rival's answer to one question: same inputs, same result, every time.
    func play(_ q: BlitzQuestion, seed: String) -> (correct: Bool, elapsed: Double) {
        var rng = SeededRNG("\(id)|\(q.id)|\(seed)")
        let correct = rng.unit() < accuracy
        let share = Swift.min(0.95, Swift.max(0.04, speed + (rng.unit() - 0.5) * 0.3))
        return (correct, share * q.limit)
    }
}

// MARK: - Progress (local; best scores, ghost runs, mistake bank, daily streak)

enum BlitzProgress {
    private static var d: UserDefaults { .standard }
    private static let mistakesKey = "bb.blitz.mistakes"
    private static let dailyLastKey = "bb.blitz.daily.last"
    private static let dailyStreakKey = "bb.blitz.daily.streak"
    private static let dailyScoreKey = "bb.blitz.daily.score"

    static func best(_ pack: String) -> Int { d.integer(forKey: "bb.blitz.best.\(pack)") }
    static func ghost(_ pack: String) -> [Int] { d.array(forKey: "bb.blitz.ghost.\(pack)") as? [Int] ?? [] }

    /// Keeps the run as the new ghost when it beats the old best. Returns true on a new record.
    @discardableResult
    static func saveRun(pack: String, total: Int, cumulative: [Int]) -> Bool {
        guard total > best(pack) else { return false }
        d.set(total, forKey: "bb.blitz.best.\(pack)")
        d.set(cumulative, forKey: "bb.blitz.ghost.\(pack)")
        return true
    }

    static var mistakes: [String] { d.stringArray(forKey: mistakesKey) ?? [] }
    static func record(_ id: String, correct: Bool) {
        var m = mistakes.filter { $0 != id }
        if !correct { m.insert(id, at: 0) }
        d.set(Array(m.prefix(40)), forKey: mistakesKey)
    }

    static func dayKey(_ date: Date = Date()) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
    static var doneToday: Bool { d.string(forKey: dailyLastKey) == dayKey() }
    static var todayScore: Int { doneToday ? d.integer(forKey: dailyScoreKey) : 0 }
    /// Days in a row, counting today or yesterday (a streak is alive until a day is skipped).
    static var dailyStreak: Int {
        guard let last = d.string(forKey: dailyLastKey) else { return 0 }
        let yesterday = dayKey(Date().addingTimeInterval(-86_400))
        return (last == dayKey() || last == yesterday) ? d.integer(forKey: dailyStreakKey) : 0
    }
    /// Counts only the first finished run of the day.
    static func finishDaily(score: Int) {
        guard !doneToday else { return }
        let yesterday = dayKey(Date().addingTimeInterval(-86_400))
        let next = d.string(forKey: dailyLastKey) == yesterday ? d.integer(forKey: dailyStreakKey) + 1 : 1
        d.set(next, forKey: dailyStreakKey)
        d.set(dayKey(), forKey: dailyLastKey)
        d.set(score, forKey: dailyScoreKey)
    }

    /// Today's five: up to two from the mistake bank (spaced repetition), the rest
    /// drawn across every pack with a date seed, so the set is stable all day.
    static func dailyQuestions(count: Int = 5, date: Date = Date()) -> [BlitzQuestion] {
        let all = BlitzStore.bank.questions
        var rng = SeededRNG("daily|\(dayKey(date))")
        var picked: [BlitzQuestion] = []
        for id in mistakes.prefix(2) { if let q = BlitzStore.find(id) { picked.append(q) } }
        for q in all.shuffled(using: &rng) where picked.count < count && !picked.contains(q) { picked.append(q) }
        return picked
    }
}

// MARK: - Game engine

enum BlitzMode: Equatable {
    case daily
    case pack(String)
    case review

    var ghostKey: String? {
        if case .pack(let id) = self { return id }
        return nil
    }
    var title: String {
        switch self {
        case .daily: return "今日快答".tr
        case .review: return "错题重练".tr
        case .pack(let id): return BlitzStore.pack(id)?.name ?? "快答挑战".tr
        }
    }
}

struct BlitzStanding: Identifiable {
    let id: String
    let name: String
    let tag: String?
    let emoji: String
    let score: Int
    let gained: Int
    let isYou: Bool
}

struct BlitzAnswerLog: Identifiable {
    let id: String
    let question: BlitzQuestion
    let correct: Bool
    let yourAnswer: String
}

@MainActor
final class BlitzGame: ObservableObject {
    enum Phase { case ready, reading, answering, reveal, podium, summary }

    let mode: BlitzMode
    let questions: [BlitzQuestion]
    let seed: String
    /// Per question: display slot → original option index (quiz options are shuffled each run).
    let orders: [[Int]]
    let ghost: [Int]
    let fast: Bool

    @Published var index = 0
    @Published var phase: Phase = .ready
    @Published var phaseStart = Date()
    @Published var pickedSlot: Int?
    @Published var sliderValue: Double = 0
    @Published var timedOut = false
    @Published var lastCorrect = false
    @Published var lastPoints = 0
    @Published var lastBonus = 0
    @Published var streak = 0
    @Published var bestStreak = 0
    @Published var total = 0
    @Published var newRecord = false       // beat a previous best (never on a first play)
    @Published var firstPlay = false
    @Published private(set) var log: [BlitzAnswerLog] = []

    private(set) var cumulative: [Int] = []
    private var rivalTotals: [String: Int] = [:]
    private var rivalStreaks: [String: Int] = [:]
    private var rivalGained: [String: Int] = [:]
    private var prevRank: [String: Int] = [:]

    init(mode: BlitzMode) {
        self.mode = mode
        switch mode {
        case .daily:
            questions = BlitzProgress.dailyQuestions()
            seed = "daily|\(BlitzProgress.dayKey())"
        case .pack(let id):
            questions = BlitzStore.questions(in: id)
            seed = "pack|\(id)"
        case .review:
            questions = BlitzProgress.mistakes.compactMap(BlitzStore.find).prefix(8).map { $0 }
            seed = "review|\(BlitzProgress.dayKey())"
        }
        orders = questions.map { q in
            let n = q.choices.count
            return q.type == "quiz" ? Array(0..<n).shuffled() : Array(0..<n)
        }
        ghost = mode.ghostKey.map(BlitzProgress.ghost) ?? []
        fast = UserDefaults.standard.bool(forKey: "bb.blitz.fast")
        sliderValue = questions.first.map(Self.sliderStart) ?? 0
    }

    var current: BlitzQuestion? { questions.indices.contains(index) ? questions[index] : nil }
    var isLast: Bool { index >= questions.count - 1 }
    var readyDuration: Double { fast ? 0.3 : 2.4 }
    var readingDuration: Double { fast ? 0.3 : 2.2 }

    func displayChoices(_ i: Int) -> [String] {
        let q = questions[i]; let c = q.choices
        return orders[i].map { c[$0] }
    }
    func correctSlot(_ i: Int) -> Int? {
        guard let a = questions[i].answer else { return nil }
        return orders[i].firstIndex(of: a)
    }
    func remaining(_ now: Date) -> Double {
        guard let q = current else { return 0 }
        return Swift.max(0, q.limit - now.timeIntervalSince(phaseStart))
    }

    private static func sliderStart(_ q: BlitzQuestion) -> Double {
        guard q.isSlider, let lo = q.min, let hi = q.max, let st = q.step else { return 0 }
        return ((lo + hi) / 2 / st).rounded() * st
    }

    // Driven by the view's clock.
    func tick(_ now: Date) {
        let t = now.timeIntervalSince(phaseStart)
        switch phase {
        case .ready where t >= readyDuration: go(.reading, now)
        case .reading where t >= readingDuration: go(.answering, now)
        case .answering where remaining(now) <= 0: resolve(slot: nil, value: nil, elapsed: current?.limit ?? 20, now: now)
        default: break
        }
    }

    func pick(_ slot: Int, now: Date = Date()) {
        guard phase == .answering else { return }
        resolve(slot: slot, value: nil, elapsed: now.timeIntervalSince(phaseStart), now: now)
    }

    func submitSlider(now: Date = Date()) {
        guard phase == .answering else { return }
        resolve(slot: nil, value: sliderValue, elapsed: now.timeIntervalSince(phaseStart), now: now)
    }

    func next(now: Date = Date()) {
        guard phase == .reveal else { return }
        if isLast { finish(); go(.podium, now); return }
        index += 1
        pickedSlot = nil
        timedOut = false
        if let q = current { sliderValue = Self.sliderStart(q) }
        go(.reading, now)
    }

    func toSummary() { phase = .summary }

    private func go(_ p: Phase, _ now: Date) { phase = p; phaseStart = now }

    private func resolve(slot: Int?, value: Double?, elapsed: Double, now: Date) {
        guard let q = current else { return }
        let correct: Bool
        let yours: String
        if let v = value {
            correct = BlitzScore.sliderCorrect(q, v)
            yours = BlitzFormat.number(v) + " " + q.unitLabel
        } else if let s = slot {
            correct = s == correctSlot(index)
            yours = displayChoices(index)[s]
        } else {
            correct = false
            yours = "（没作答）".tr
        }
        pickedSlot = slot
        timedOut = slot == nil && value == nil
        lastCorrect = correct
        streak = correct ? streak + 1 : 0
        bestStreak = Swift.max(bestStreak, streak)
        lastPoints = BlitzScore.points(correct: correct, elapsed: elapsed, limit: q.limit)
        lastBonus = correct ? BlitzScore.streakBonus(streak) : 0
        prevRank = Dictionary(uniqueKeysWithValues: standings.enumerated().map { ($1.id, $0) })
        total += lastPoints + lastBonus
        cumulative.append(total)
        log.append(BlitzAnswerLog(id: q.id, question: q, correct: correct, yourAnswer: yours))
        BlitzProgress.record(q.id, correct: correct)

        for r in BlitzRival.all {
            let res = r.play(q, seed: seed)
            let s = res.correct ? (rivalStreaks[r.id] ?? 0) + 1 : 0
            rivalStreaks[r.id] = s
            let g = BlitzScore.points(correct: res.correct, elapsed: res.elapsed, limit: q.limit)
                  + (res.correct ? BlitzScore.streakBonus(s) : 0)
            rivalGained[r.id] = g
            rivalTotals[r.id, default: 0] += g
        }
        BBHaptics.result(correct)
        go(.reveal, now)
    }

    private func finish() {
        if let key = mode.ghostKey {
            let previous = BlitzProgress.best(key)
            let saved = BlitzProgress.saveRun(pack: key, total: total, cumulative: cumulative)
            firstPlay = previous == 0
            newRecord = saved && previous > 0
        }
        if mode == .daily { BlitzProgress.finishDaily(score: total) }
    }

    /// Everyone in the room, best first. The ghost is "you, last time" at the same question.
    var standings: [BlitzStanding] {
        let answered = cumulative.count
        var rows: [BlitzStanding] = [
            BlitzStanding(id: "you", name: "你".tr, tag: nil, emoji: "🙂", score: total,
                          gained: answered > 0 ? lastPoints + lastBonus : 0, isYou: true)
        ]
        if !ghost.isEmpty {
            let i = Swift.min(Swift.max(answered, 1), ghost.count) - 1
            let prev = i > 0 ? ghost[i - 1] : 0
            rows.append(BlitzStanding(id: "ghost", name: "上次的你".tr, tag: "幽灵".tr, emoji: "👻",
                                      score: answered > 0 ? ghost[i] : 0,
                                      gained: answered > 0 ? ghost[i] - prev : 0, isYou: false))
        }
        for r in BlitzRival.all {
            rows.append(BlitzStanding(id: r.id, name: r.displayName, tag: r.displayStyle, emoji: r.emoji,
                                      score: rivalTotals[r.id] ?? 0, gained: rivalGained[r.id] ?? 0, isYou: false))
        }
        return rows.sorted { $0.score != $1.score ? $0.score > $1.score : $0.isYou }
    }

    func rankChange(_ id: String) -> Int {
        guard let before = prevRank[id], let now = standings.firstIndex(where: { $0.id == id }) else { return 0 }
        return before - now
    }

    var yourRank: Int { (standings.firstIndex { $0.isYou } ?? 0) + 1 }
    var correctCount: Int { log.filter(\.correct).count }
    var misses: [BlitzAnswerLog] { log.filter { !$0.correct } }
}

enum BBHaptics {
    static func result(_ ok: Bool) {
        UINotificationFeedbackGenerator().notificationOccurred(ok ? .success : .error)
    }
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func tick() { UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.6) }
}
