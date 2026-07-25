import Foundation

// MARK: - Domain models (match the PHP API JSON)

struct User: Codable, Identifiable {
    let id: Int
    let identifier: String
    var nickname: String
    var ageGroup: String?
}

struct Reflect: Codable {
    var need: String?       // 需要 / 想要 / 不确定
    var plan: String?       // 计划内 / 计划外
    var influence: String?  // 同学 / 平台广告 / …
    var feeling: String?    // 值得 / 一般 / 后悔
}

struct Transaction: Codable, Identifiable {
    var id: String
    var kind: String      // "out" | "in"
    var cat: String
    var note: String
    var amount: Double
    var ts: String        // ISO-8601 string
    var reflect: Reflect? = nil
}

// 记录一次选择 — the exact reflection options from the web app
let REFLECT_NEED      = ["需要", "想要", "不确定"]
let REFLECT_PLAN      = ["计划内", "计划外"]
let REFLECT_INFLUENCE = ["同学", "平台广告", "限时优惠", "情绪", "家庭需要", "其他"]
let REFLECT_FEELING   = ["值得", "一般", "后悔"]

struct Settings: Codable {
    var dailyBudget: Double
    var monthlyBudget: Double
    init(dailyBudget: Double = 0, monthlyBudget: Double = 0) {
        self.dailyBudget = dailyBudget
        self.monthlyBudget = monthlyBudget
    }
    enum CodingKeys: String, CodingKey { case dailyBudget, monthlyBudget }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        dailyBudget = (try? c.decode(Double.self, forKey: .dailyBudget)) ?? 0
        monthlyBudget = (try? c.decode(Double.self, forKey: .monthlyBudget)) ?? 0
    }
}

// A 省钱挑战 instance — matches the web app_state.challenges shape exactly.
struct ChallengeInstance: Codable, Identifiable {
    var id: String
    var defId: String
    var status: String          // active | done | abandoned
    var startDay: String?
    var checkDays: [String]
}

// The whole per-user app_state blob. The native app manages transactions +
// gameProgress + lessonProgress explicitly; EVERYTHING ELSE the web stores
// (settings, savingsGoals, challenges, userProfile, codex…) is preserved
// verbatim in `extras` so saving from the iOS app never wipes web data.
struct AppState: Codable {
    var transactions: [Transaction]
    var gameProgress: [String]
    var lessonProgress: [String]
    var challenges: [ChallengeInstance]
    var extras: [String: JSONValue]

    init(transactions: [Transaction] = [], gameProgress: [String] = [],
         lessonProgress: [String] = [], challenges: [ChallengeInstance] = [],
         extras: [String: JSONValue] = [:]) {
        self.transactions = transactions
        self.gameProgress = gameProgress
        self.lessonProgress = lessonProgress
        self.challenges = challenges
        self.extras = extras
    }

    private static let knownKeys: Set<String> = ["transactions", "gameProgress", "lessonProgress", "challenges"]

    init(from decoder: Decoder) throws {
        guard let c = try? decoder.container(keyedBy: DynamicKey.self) else {
            transactions = []; gameProgress = []; lessonProgress = []; challenges = []; extras = [:]
            return   // tolerate {} / non-object (brand-new user)
        }
        transactions   = (try? c.decode([Transaction].self, forKey: DynamicKey("transactions"))) ?? []
        gameProgress   = (try? c.decode([String].self, forKey: DynamicKey("gameProgress"))) ?? []
        lessonProgress = (try? c.decode([String].self, forKey: DynamicKey("lessonProgress"))) ?? []
        challenges     = (try? c.decode([ChallengeInstance].self, forKey: DynamicKey("challenges"))) ?? []
        var ex: [String: JSONValue] = [:]
        for key in c.allKeys where !AppState.knownKeys.contains(key.stringValue) {
            if let v = try? c.decode(JSONValue.self, forKey: key) { ex[key.stringValue] = v }
        }
        extras = ex
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: DynamicKey.self)
        try c.encode(transactions, forKey: DynamicKey("transactions"))
        try c.encode(gameProgress, forKey: DynamicKey("gameProgress"))
        try c.encode(lessonProgress, forKey: DynamicKey("lessonProgress"))
        try c.encode(challenges, forKey: DynamicKey("challenges"))
        for (k, v) in extras { try c.encode(v, forKey: DynamicKey(k)) }
    }
}

// A minimal JSON value — lets us round-trip arbitrary web-only app_state fields
// without modeling them, so the iOS app never clobbers data it doesn't manage.
enum JSONValue: Codable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null }
        else if let b = try? c.decode(Bool.self) { self = .bool(b) }
        else if let n = try? c.decode(Double.self) { self = .number(n) }
        else if let s = try? c.decode(String.self) { self = .string(s) }
        else if let a = try? c.decode([JSONValue].self) { self = .array(a) }
        else if let o = try? c.decode([String: JSONValue].self) { self = .object(o) }
        else { self = .null }
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let s): try c.encode(s)
        case .number(let n): try c.encode(n)
        case .bool(let b): try c.encode(b)
        case .object(let o): try c.encode(o)
        case .array(let a): try c.encode(a)
        case .null: try c.encodeNil()
        }
    }
}

struct DynamicKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    init(_ s: String) { stringValue = s; intValue = nil }
    init?(stringValue: String) { self.stringValue = stringValue; intValue = nil }
    init?(intValue: Int) { stringValue = String(intValue); self.intValue = intValue }
}

// MARK: - API response envelopes

struct UserResponse: Codable { let user: User? }
struct StateResponse: Codable { let appState: AppState }
struct AIResponse: Codable { let reply: String; let source: String }
struct SendCodeResult: Codable { let ok: Bool?; let channel: String?; let devCode: String?; let note: String? }
struct OkResponse: Codable { let ok: Bool? }

/// Password policy shared with the backend: ≥8 chars, both upper- and lower-case letters.
func bbPasswordOK(_ p: String) -> Bool {
    p.count >= 8
        && p.range(of: "[a-z]", options: .regularExpression) != nil
        && p.range(of: "[A-Z]", options: .regularExpression) != nil
}

/// Client-side mirror of the backend identifier rule: returns "email" | "phone" | nil.
func bbIdentifierType(_ s: String) -> String? {
    let t = s.trimmingCharacters(in: .whitespaces)
    if t.range(of: #"^1[3-9]\d{9}$"#, options: .regularExpression) != nil { return "phone" }
    if t.range(of: #"^[^@\s]+@[^@\s]+\.[^@\s]+$"#, options: .regularExpression) != nil { return "email" }
    return nil
}
struct APIErrorResponse: Codable {
    struct E: Codable { let code: String; let message: String }
    let error: E
}

// MARK: - Categories (zh label + SF Symbol)

let CATS: [String: (zh: String, icon: String)] = [
    "food":    ("餐饮", "fork.knife"),
    "transit": ("交通", "bus.fill"),
    "study":   ("学习", "book.fill"),
    "daily":   ("生活用品", "cart.fill"),
    "fun":     ("娱乐", "gamecontroller.fill"),
    "medical": ("医疗", "cross.case.fill"),
    "other":   ("其他", "ellipsis.circle.fill"),
    "income":  ("收入", "arrow.down.circle.fill")
]
let EXPENSE_CATS = ["food", "transit", "study", "daily", "fun", "medical", "other"]

// MARK: - Date helpers (ts is ISO-8601, sometimes with fractional seconds)

func parseTS(_ s: String) -> Date {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let d = f.date(from: s) { return d }
    f.formatOptions = [.withInternetDateTime]
    return f.date(from: s) ?? Date()
}

func isSameMonth(_ ts: String, _ now: Date) -> Bool {
    let cal = Calendar.current
    let d = parseTS(ts)
    return cal.component(.year, from: d) == cal.component(.year, from: now)
        && cal.component(.month, from: d) == cal.component(.month, from: now)
}

func isToday(_ ts: String) -> Bool {
    Calendar.current.isDateInToday(parseTS(ts))
}

func isThisWeek(_ ts: String) -> Bool {
    Calendar.current.isDate(parseTS(ts), equalTo: Date(), toGranularity: .weekOfYear)
}

// The AI returns lightweight markdown (**bold**, lists). Render it instead of showing raw asterisks.
func markdownText(_ s: String) -> AttributedString {
    (try? AttributedString(markdown: s,
        options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(s)
}
