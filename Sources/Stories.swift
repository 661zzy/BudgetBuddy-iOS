import SwiftUI

// MARK: - Story game models (decoded from bundled stories.json — the exact web GAMES data)

struct Story: Codable, Identifiable {
    let id: String
    let title: String
    let level: String?
    let time: String?
    let cat: String?
    let icon: String?
    let color: String?
    let tint: String?
    let desc: String?
    let intro: String?
    let moneyLabel: String?
    let goal: Double?
    let stats: [String: Double]
    let statBar: [String]
    let start: String
    let scenes: [String: StoryScene]
    let endings: [String: Ending]
}

struct StoryScene: Codable {
    let setting: String?
    let sceneTitle: String?
    let emoji: String?
    let npcName: String?
    let npcLine: String?
    let narrator: String
    let isFinal: Bool?
    let choices: [Choice]
    enum CodingKeys: String, CodingKey {
        case setting, sceneTitle, emoji, npcName, npcLine, narrator, choices
        case isFinal = "final"
    }
}

struct Choice: Codable, Identifiable {
    let label: String
    let hint: String?
    let effects: [String: Double]?
    let consequence: String?
    let tip: String?
    let score: Int?
    let next: String?
    let end: String?
    var id: String { label }   // labels are unique within a scene
}

struct Ending: Codable {
    let title: String
    let tone: String          // "good" | "caution"
    let did_well: String?
    let improve: String?
    let habit: String?
    let min: Int?
}

// MARK: - Lesson models (lessons.json) + Codex models (codex.json)

struct LessonVideo: Codable {
    let videoTitle: String?
    let videoProvider: String?
    let videoUrl: String?
    let thumbnailUrl: String?
    let author: String?
}

struct Lesson: Codable, Identifiable {
    let id: String
    let cat: String
    let title: String
    let level: String?
    let time: String?
    let desc: String?
    let explanation: String?
    let points: [String]?
    let example: String?
    let task: String?
    let actionLabel: String?
    let video: LessonVideo?
}

struct CodexEntry: Codable, Identifiable {
    let id: String
    let title: String
    let category: String
    let signs: [String]
    let defense: [String]
    let story: String?
    let storyTitle: String?
}

// MARK: - Loaders (read JSON extracted verbatim from the web app)

func loadBundleJSON<T: Decodable>(_ name: String, as type: T.Type) -> T? {
    guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
          let data = try? Data(contentsOf: url) else { return nil }
    return try? JSONDecoder().decode(T.self, from: data)
}

enum StoryStore {
    static let all: [Story] = loadBundleJSON("stories", as: [Story].self) ?? []
    static func find(_ id: String) -> Story? { all.first { $0.id == id } }
}

enum LessonStore {
    static let all: [Lesson] = loadBundleJSON("lessons", as: [Lesson].self) ?? []
    // grouped in the web's category order
    static let catOrder = ["budget", "habit", "save", "spend", "safety"]
    static func inCat(_ key: String) -> [Lesson] { all.filter { $0.cat == key } }
}

enum CodexStore {
    static let all: [CodexEntry] = loadBundleJSON("codex", as: [CodexEntry].self) ?? []
}

struct ChallengeDef: Codable, Identifiable {
    let id: String
    let title: String
    let desc: String?
    let days: Int
    let level: String?
    let est: Int?
    let cat: String?
    let icon: String?
    let tip: String?
}

enum ChallengeDefStore {
    static let all: [ChallengeDef] = loadBundleJSON("challenge_defs", as: [ChallengeDef].self) ?? []
    static func find(_ id: String) -> ChallengeDef? { all.first { $0.id == id } }
}

// MARK: - Display helpers

// Lesson category → (zh label, SF Symbol, tint, accent)
struct LearnCat { let zh: String; let icon: String; let tint: Color; let fg: Color }
let LEARN_CATS: [String: LearnCat] = [
    "budget": LearnCat(zh: "预算入门",   icon: "function",        tint: Color(hex: 0xE5EEF7), fg: Color(hex: 0x3A5A78)),
    "habit":  LearnCat(zh: "记账习惯",   icon: "square.and.pencil", tint: Color(hex: 0xE4EFE7), fg: Color(hex: 0x3E5F4D)),
    "save":   LearnCat(zh: "储蓄目标",   icon: "yensign.circle",  tint: Color(hex: 0xE4EFE7), fg: Color(hex: 0x3E5F4D)),
    "spend":  LearnCat(zh: "消费提醒",   icon: "hand.raised",     tint: Color(hex: 0xFFF4DF), fg: Color(hex: 0x8A5A2B)),
    "safety": LearnCat(zh: "基础金融安全", icon: "checkmark.shield", tint: Color(hex: 0xFBE9E7), fg: Color(hex: 0xC0564A)),
]

// Difficulty level → badge colors
func levelColors(_ level: String?) -> (bg: Color, fg: Color) {
    switch level ?? "" {
    case "简单": return (Color(hex: 0xE4EFE7), Color(hex: 0x35583F))
    case "重要": return (Color(hex: 0xFFF4DF), Color(hex: 0x7A4E1E))
    default:     return (Color(hex: 0xE5EEF7), Color(hex: 0x355A78))   // 入门 / 进阶
    }
}

// Map the web's lucide icon names to SF Symbols.
func storySymbol(_ name: String?) -> String {
    switch name ?? "" {
    case "wallet": return "wallet.pass.fill"
    case "scale": return "scalemass.fill"
    case "shield", "shield-check", "shield-alert": return "checkmark.shield.fill"
    case "piggy-bank": return "yensign.circle.fill"
    case "target": return "target"
    case "bike", "bicycle": return "bicycle"
    case "graduation-cap": return "graduationcap.fill"
    default: return "book.fill"
    }
}

func challengeSymbol(_ name: String?) -> String {
    switch name ?? "" {
    case "utensils": return "fork.knife"
    case "bus", "train-front", "transit": return "bus.fill"
    case "piggy-bank": return "yensign.circle.fill"
    case "notebook-pen", "pencil": return "square.and.pencil"
    case "shopping-bag", "shopping-cart": return "cart.fill"
    case "coffee", "cup-soda": return "cup.and.saucer.fill"
    case "footprints": return "figure.walk"
    default: return "flag.fill"
    }
}
