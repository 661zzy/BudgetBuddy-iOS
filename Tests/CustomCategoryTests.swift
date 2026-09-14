import XCTest
@testable import BudgetBuddy

final class CustomCategoryTests: XCTestCase {

    private func tx(_ id: String, _ cat: String, kind: String = "out") -> Transaction {
        Transaction(id: id, kind: kind, cat: cat, note: "", amount: 10, ts: "2026-09-14T08:00:00Z")
    }

    // MARK: validation

    func testValidationRules() {
        let existing = [CustomCategory(name: "房租", icon: "house.fill"), CustomCategory(name: "Gym", icon: "dumbbell.fill")]
        func check(_ raw: String, renaming: String? = nil) -> Result<String, BBCategory.NameError> {
            BBCategory.validate(raw, existing: existing, renaming: renaming)
        }
        XCTAssertEqual(check("  水电  "), .success("水电"), "trims")
        XCTAssertEqual(check("宠物   用品"), .success("宠物 用品"), "collapses inner spaces")
        XCTAssertEqual(check("   "), .failure(.empty))
        XCTAssertEqual(check("一二三四五六七八"), .success("一二三四五六七八"), "8 is allowed")
        XCTAssertEqual(check("一二三四五六七八九"), .failure(.tooLong))
        XCTAssertEqual(check("餐饮"), .failure(.builtin), "built-in Chinese label")
        XCTAssertEqual(check("food"), .failure(.builtin), "built-in key")
        XCTAssertEqual(check("Transit"), .failure(.builtin), "built-in English label, any case")
        XCTAssertEqual(check("收入"), .failure(.builtin))
        XCTAssertEqual(check("房租"), .failure(.duplicate))
        XCTAssertEqual(check("gym"), .failure(.duplicate), "duplicate check ignores case")
        XCTAssertEqual(check("房租", renaming: "房租"), .success("房租"), "keeping the same name while changing the icon")
        XCTAssertEqual(check("Gym", renaming: "房租"), .failure(.duplicate), "can't rename onto another category")
        let full = (0..<BBCategory.maxCustom).map { CustomCategory(name: "c\($0)", icon: "tag.fill") }
        XCTAssertEqual(BBCategory.validate("新的", existing: full), .failure(.limit))
        XCTAssertEqual(BBCategory.validate("c0改", existing: full, renaming: "c0"), .success("c0改"), "limit doesn't block renames")
    }

    // MARK: add / rename / delete on the account state

    func testRenameMovesHistoryAndDeleteKeepsIt() throws {
        var s = AppState(transactions: [tx("a", "水电"), tx("b", "food"), tx("c", "水电"), tx("d", "水电", kind: "in")])
        try s.addCustomCategory(name: "水电", icon: "bolt.fill")
        XCTAssertThrowsError(try s.addCustomCategory(name: "水电", icon: "drop.fill"))

        let renamed = try s.renameCustomCategory("水电", to: "水电燃气", icon: "drop.fill")
        XCTAssertEqual(renamed, "水电燃气")
        XCTAssertEqual(s.customCats, [CustomCategory(name: "水电燃气", icon: "drop.fill")])
        XCTAssertEqual(s.transactions.map(\.cat), ["水电燃气", "food", "水电燃气", "水电"],
                       "expenses move with the rename; built-ins and income untouched")

        s.deleteCustomCategory("水电燃气")
        XCTAssertTrue(s.customCats.isEmpty)
        XCTAssertEqual(s.transactions.filter { $0.cat == "水电燃气" }.count, 2, "history keeps the name after delete")
        XCTAssertEqual(BBCategory.label("水电燃气"), "水电燃气", "and still displays it")
    }

    func testUnknownIconFallsBack() throws {
        var s = AppState()
        try s.addCustomCategory(name: "房租", icon: "not.a.real.symbol")
        XCTAssertEqual(s.customCats.first?.icon, BBCategory.defaultIcon)
        XCTAssertEqual(BBCategory.icon("房租", custom: s.customCats), BBCategory.defaultIcon)
        XCTAssertEqual(BBCategory.icon("food", custom: s.customCats), "fork.knife")
        XCTAssertEqual(BBCategory.icon("历史里删掉的分类", custom: s.customCats), BBCategory.defaultIcon)
    }

    // MARK: persistence — the stored app_state

    func testStateRoundTripKeepsCategoriesAndOtherClientsFields() throws {
        let json = """
        {"transactions":[{"id":"t1","kind":"out","cat":"水电","note":"","amount":88,"ts":"2026-09-14T08:00:00Z"}],
         "gameProgress":["month-life"],"lessonProgress":[],"challenges":[],
         "customCats":[{"name":"水电","icon":"bolt.fill"},{"name":"房租","icon":"house.fill"}],
         "savingsGoals":[{"id":"g1","target":600}],"settings":{"dailyBudget":30}}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AppState.self, from: json)
        XCTAssertEqual(decoded.customCats.map(\.name), ["水电", "房租"])
        XCTAssertNil(decoded.extras["customCats"], "known key, not an extra")
        XCTAssertNotNil(decoded.extras["savingsGoals"])

        let again = try JSONDecoder().decode(AppState.self, from: JSONEncoder().encode(decoded))
        XCTAssertEqual(again.customCats, decoded.customCats)
        XCTAssertEqual(again.transactions.first?.cat, "水电")
        XCTAssertNotNil(again.extras["savingsGoals"], "web-only fields survive")
        XCTAssertNotNil(again.extras["settings"])
    }

    func testOldStateWithoutCategoriesAndBadEntries() throws {
        let old = try JSONDecoder().decode(AppState.self, from: #"{"transactions":[],"gameProgress":[]}"#.data(using: .utf8)!)
        XCTAssertTrue(old.customCats.isEmpty)

        let messy = """
        {"customCats":[{"name":1},"x",{"name":"  水电 ","icon":"bolt.fill"},{"name":"餐饮","icon":"tag.fill"},
                       {"name":"水电","icon":"drop.fill"},{"name":"太长太长太长太长太长","icon":"tag.fill"},{"name":"房租"}]}
        """.data(using: .utf8)!
        let s = try JSONDecoder().decode(AppState.self, from: messy)
        XCTAssertEqual(s.customCats, [CustomCategory(name: "水电", icon: "bolt.fill"),
                                      CustomCategory(name: "房租", icon: BBCategory.defaultIcon)],
                       "skip malformed, built-in, duplicate and over-long entries; keep the rest")
    }

    // MARK: merging (guest → account, and the load-before-save merge)

    func testMergeUnionKeepsOrderAndCap() {
        let server = [CustomCategory(name: "房租", icon: "house.fill"), CustomCategory(name: "水电", icon: "bolt.fill")]
        let guest = [CustomCategory(name: "水电", icon: "drop.fill"), CustomCategory(name: "宠物", icon: "pawprint.fill")]
        let m = BBCategory.merged(server, guest)
        XCTAssertEqual(m.map(\.name), ["房租", "水电", "宠物"])
        XCTAssertEqual(m[1].icon, "bolt.fill", "the primary list wins on a clash")
        let many = (0..<30).map { CustomCategory(name: "k\($0)", icon: "tag.fill") }
        XCTAssertEqual(BBCategory.merged(many, []).count, BBCategory.maxCustom)
    }

    func testCategoriesAloneCountAsContent() {
        var s = AppState()
        XCTAssertTrue(s.bbIsEmptyContent)
        s.customCats = [CustomCategory(name: "水电", icon: "bolt.fill")]
        XCTAssertFalse(s.bbIsEmptyContent, "a guest who only named categories still gets them adopted on sign-up")
    }
}
