import Foundation

// MARK: - 自定义记账分类 (v1.6.1)
//
// Real-user feedback: 「其他」is too vague — let people name their own
// categories (水电、房租…) and keep them.
//
// Storage, chosen so every client that is already on people's phones keeps
// working without an update:
//   • A transaction's `cat` holds the custom category's NAME ("水电").
//     iOS 1.6 and Android 5.6 both fall back to showing `cat` verbatim when
//     it isn't a built-in key, so old versions display 水电 correctly and
//     group it separately in their totals.
//   • The list of custom categories (name + icon, in order) lives in the
//     account's app_state under `customCats`. iOS and Android already keep
//     unknown app_state keys verbatim, so neither drops it when saving.
// The web app needs a one-line guard (it indexes CATS[cat].zh directly);
// that ships separately.

struct CustomCategory: Codable, Hashable, Identifiable {
    var name: String
    var icon: String
    var id: String { name }
}

enum BBCategory {
    static let maxCustom = 20
    static let maxNameLength = 8
    static let defaultIcon = "tag.fill"
    static let icons = [
        "tag.fill", "bolt.fill", "house.fill", "drop.fill",
        "wifi", "iphone", "car.fill", "tshirt.fill",
        "gift.fill", "heart.fill", "pawprint.fill", "cup.and.saucer.fill",
        "dumbbell.fill", "airplane", "music.note", "star.fill",
    ]

    enum NameError: Error, Equatable {
        case empty, tooLong, builtin, duplicate, limit

        var message: String {
            switch self {
            case .empty:     return "给分类起个名字吧".tr
            case .tooLong:   return BBLang.isEN ? "Up to \(BBCategory.maxNameLength) characters" : "最多 \(BBCategory.maxNameLength) 个字"
            case .builtin:   return "这个名字和系统分类重复了".tr
            case .duplicate: return "已经有这个分类了".tr
            case .limit:     return BBLang.isEN ? "Up to \(BBCategory.maxCustom) custom categories" : "最多 \(BBCategory.maxCustom) 个自定义分类"
            }
        }
    }

    /// Trim, and collapse runs of whitespace to one space.
    static func normalize(_ raw: String) -> String {
        raw.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).joined(separator: " ")
    }

    /// Names a user can't take: built-in keys and their Chinese and English labels.
    static let reserved: Set<String> = {
        var s = Set<String>()
        for (key, v) in CATS {
            s.insert(key.lowercased())
            s.insert(v.zh.lowercased())
            if let en = L10n.en[v.zh] { s.insert(en.lowercased()) }
        }
        return s
    }()

    /// Validates a new name (or a rename when `renaming` is the current name).
    static func validate(_ raw: String, existing: [CustomCategory], renaming: String? = nil) -> Result<String, NameError> {
        let name = normalize(raw)
        if name.isEmpty { return .failure(.empty) }
        if name.count > maxNameLength { return .failure(.tooLong) }
        if reserved.contains(name.lowercased()) { return .failure(.builtin) }
        let others = existing.filter { $0.name != renaming }
        if others.contains(where: { $0.name.lowercased() == name.lowercased() }) { return .failure(.duplicate) }
        if renaming == nil && existing.count >= maxCustom { return .failure(.limit) }
        return .success(name)
    }

    /// Display name for any `cat` value: built-ins are translated, custom names shown as typed.
    static func label(_ key: String) -> String { CATS[key]?.zh.tr ?? key }

    static func icon(_ key: String, custom: [CustomCategory]) -> String {
        CATS[key]?.icon ?? custom.first(where: { $0.name == key })?.icon ?? defaultIcon
    }

    /// Union of two lists: `primary` order first, then anything only `secondary` has.
    /// Case-insensitive on name; capped at `maxCustom`.
    static func merged(_ primary: [CustomCategory], _ secondary: [CustomCategory]) -> [CustomCategory] {
        var out: [CustomCategory] = []
        var seen = Set<String>()
        for c in primary + secondary where !seen.contains(c.name.lowercased()) {
            seen.insert(c.name.lowercased())
            out.append(c)
        }
        return Array(out.prefix(maxCustom))
    }

    /// Lenient decode for the stored list: skips malformed entries, bad names and
    /// unknown icons instead of throwing, so one bad write can't wipe the rest.
    static func decodeList(_ values: [JSONValue]) -> [CustomCategory] {
        var out: [CustomCategory] = []
        for v in values {
            guard case let .object(o) = v, case let .string(rawName)? = o["name"] else { continue }
            let name = normalize(rawName)
            guard !name.isEmpty, name.count <= maxNameLength, !reserved.contains(name.lowercased()) else { continue }
            var icon = defaultIcon
            if case let .string(i)? = o["icon"], icons.contains(i) { icon = i }
            out.append(CustomCategory(name: name, icon: icon))
        }
        return merged(out, [])
    }
}

extension AppState {
    /// Adds a category and returns its normalized name.
    @discardableResult
    mutating func addCustomCategory(name raw: String, icon: String) throws -> String {
        let name = try BBCategory.validate(raw, existing: customCats).get()
        customCats.append(CustomCategory(name: name, icon: BBCategory.icons.contains(icon) ? icon : BBCategory.defaultIcon))
        return name
    }

    /// Renames (and/or re-icons) a category. Past entries move with it, so the
    /// totals for that category stay in one place.
    @discardableResult
    mutating func renameCustomCategory(_ old: String, to raw: String, icon: String) throws -> String {
        guard let i = customCats.firstIndex(where: { $0.name == old }) else { return old }
        let name = try BBCategory.validate(raw, existing: customCats, renaming: old).get()
        customCats[i] = CustomCategory(name: name, icon: BBCategory.icons.contains(icon) ? icon : BBCategory.defaultIcon)
        if name != old {
            for j in transactions.indices where transactions[j].cat == old && transactions[j].kind == "out" {
                transactions[j].cat = name
            }
        }
        return name
    }

    /// Removes a category from the picker. Entries already logged under it keep
    /// the name, so nothing in the history changes.
    mutating func deleteCustomCategory(_ name: String) {
        customCats.removeAll { $0.name == name }
    }
}
