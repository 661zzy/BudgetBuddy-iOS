import XCTest

final class SceneArtUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-bb.engage.prompted.v1", "YES"]   // keep the 3-min engagement sheet out of automation
        app.launchArguments = ["--scene-art-ui-test"]
        app.launch()
        prepareMainApp()
    }

    func testStorySceneBanners() throws {
        openStoryTab()

        playLinearStory(
            story: "一个月生活费大作战",
            key: "month_life",
            scenes: [
                ("s1", "开学第一周", "顿顿食堂，偶尔加个鸡腿"),
                ("s2", "周末的邀约", "在学校打球、散步"),
                ("s3", "打折的诱惑", "不需要，先不买"),
                ("s4", "话费用完了", "充 ¥30，够用就好"),
                ("s5", "月底了", "稳住，把余额存进储蓄目标"),
            ]
        )

        playLinearStory(
            story: "想要还是需要？",
            key: "want_need",
            scenes: [
                ("s1", "饭后的零食", "走开，现在不需要"),
                ("s2", "出了新款", "继续穿旧的"),
                ("s3", "同学都买了", "不跟风，我不需要"),
                ("s4", "笔芯用完了", "买一支笔芯"),
                ("s5", "电池不太耐", "先换个电池"),
            ]
        )

        playLinearStory(
            story: "防骗大作战",
            key: "anti_scam",
            scenes: [
                ("s1", "可疑的赔偿", "不点，去官方 App 自己查"),
                ("s2", "稳赚的邀请", "直接拒绝"),
                ("s3", "0 利息借钱", "关掉，我不需要借钱"),
                ("s4", "免费送装备？", "不理会"),
                ("s5", "假客服来电", "拒绝，挂掉电话"),
            ]
        )

        playLinearStory(
            story: "攒钱买耳机",
            key: "save_plan",
            scenes: [
                ("s1", "第 1 周 · 零花钱到账", "先存 ¥40，剩下再花"),
                ("s2", "第 2 周 · 奶茶诱惑", "戒掉奶茶，省 ¥30 存起来"),
                ("s3", "第 3 周 · 收到红包", "全部存进目标"),
                ("s4", "第 4 周 · 最后一点点", "卖掉闲置旧书，凑 ¥35"),
            ]
        )

        playFlatTireBranches()
    }

    private func prepareMainApp() {
        if app.buttons["跳过"].waitForExistence(timeout: 3) {
            app.buttons["跳过"].tap()
        }

        if app.staticTexts["欢迎回来"].waitForExistence(timeout: 3) || app.buttons["登录"].exists {
            let identifier = "__iostest_1782407190@budgetbuddy.local"
            let password = ProcessInfo.processInfo.environment["BB_TEST_PASSWORD"] ?? ""

            let idField = app.textFields["手机号或邮箱"].exists ? app.textFields["手机号或邮箱"] : app.textFields.element(boundBy: 0)
            XCTAssertTrue(idField.waitForExistence(timeout: 5), "Missing identifier field")
            idField.tap()
            idField.typeText(identifier)

            let passwordField = app.secureTextFields["密码（至少 6 位）"].exists ? app.secureTextFields["密码（至少 6 位）"] : app.secureTextFields.element(boundBy: 0)
            XCTAssertTrue(passwordField.waitForExistence(timeout: 5), "Missing password field")
            passwordField.tap()
            passwordField.typeText(password)

            tapButton(containing: "登录")
            XCTAssertTrue(waitForText("首页", timeout: 15) || waitForText("故事", timeout: 15), "Login did not reach the main app")
        }
    }

    private func openStoryTab() {
        if app.tabBars.buttons["故事"].waitForExistence(timeout: 5) {
            app.tabBars.buttons["故事"].tap()
        } else {
            tapButton(containing: "故事")
        }
        XCTAssertTrue(waitForText("互 动 故 事", timeout: 5) || waitForText("故事", timeout: 5))
    }

    private func playLinearStory(story: String, key: String, scenes: [(String, String, String)]) {
        openStory(story)
        for (sceneId, sceneTitle, choice) in scenes {
            scrollToTop()
            XCTAssertTrue(waitForText(sceneTitle, timeout: 8), "Missing scene \(key)_\(sceneId): \(sceneTitle)")
            capture("\(key)_\(sceneId)")
            tapButton(containing: choice)
            tapContinueOrResult()
        }
        finishIfNeeded()
    }

    private func playFlatTireBranches() {
        openStory("爆胎的自行车")
        captureFlatScene("s1", "车胎爆了")
        tapButton(containing: "推车去前面的修车铺问问")
        tapContinueOrResult()
        captureFlatScene("s2", "修车铺报价")
        tapButton(containing: "跟老板坦白，问有没有更省的办法")
        tapContinueOrResult()
        captureFlatScene("s5", "当天结束")
        tapButton(containing: "决定以后每周存 ¥5 当应急金")
        tapContinueOrResult()
        captureFlatScene("s6", "第二天选择")
        tapButton(containing: "把「每周存一点应急金」坚持下去")
        tapContinueOrResult()
        finishIfNeeded()

        openStory("爆胎的自行车")
        tapButton(containing: "先给兼职老板打个电话说明情况")
        tapContinueOrResult()
        captureFlatScene("s3", "快迟到了")
        tapButton(containing: "坐公交过去，车明天再修")
        tapContinueOrResult()
        captureFlatScene("s5_branch_from_s3", "当天结束")
        tapButton(containing: "决定以后每周存 ¥5 当应急金")
        tapContinueOrResult()
        captureFlatScene("s6_branch_from_s3", "第二天选择")
        tapButton(containing: "把「每周存一点应急金」坚持下去")
        tapContinueOrResult()
        finishIfNeeded()

        openStory("爆胎的自行车")
        tapButton(containing: "不管车了，锁好直接赶路")
        tapContinueOrResult()
        captureFlatScene("s4", "交通选择")
        tapButton(containing: "坐公交，¥2")
        tapContinueOrResult()
        captureFlatScene("s5_branch_from_s4", "当天结束")
        tapButton(containing: "决定以后每周存 ¥5 当应急金")
        tapContinueOrResult()
        captureFlatScene("s6_branch_from_s4", "第二天选择")
        tapButton(containing: "把「每周存一点应急金」坚持下去")
        tapContinueOrResult()
        finishIfNeeded()
    }

    private func captureFlatScene(_ sceneId: String, _ title: String) {
        scrollToTop()
        XCTAssertTrue(waitForText(title, timeout: 8), "Missing flat_tire_\(sceneId): \(title)")
        capture("flat_tire_\(sceneId)")
    }

    private func openStory(_ title: String) {
        openStoryTab()
        scrollToText(title)
        tapText(containing: title)
        XCTAssertTrue(waitForText("开始游戏", timeout: 8), "Missing start button for \(title)")
        tapButton(containing: "开始游戏")
    }

    private func finishIfNeeded() {
        if waitForText("完成", timeout: 8) {
            tapButton(containing: "完成")
        } else if app.navigationBars.buttons.element(boundBy: 0).exists {
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
        openStoryTab()
    }

    private func tapContinueOrResult() {
        let continueButton = app.buttons["继续"]
        if continueButton.waitForExistence(timeout: 2) {
            continueButton.tap()
            return
        }
        let resultButton = app.buttons["看看结果"]
        XCTAssertTrue(resultButton.waitForExistence(timeout: 5), "Missing 继续 / 看看结果 button")
        resultButton.tap()
    }

    private func waitForText(_ text: String, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        return app.staticTexts.matching(predicate).firstMatch.waitForExistence(timeout: timeout)
            || app.buttons.matching(predicate).firstMatch.waitForExistence(timeout: 0.2)
    }

    private func scrollToText(_ text: String) {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let target = app.staticTexts.matching(predicate).firstMatch
        for _ in 0..<8 where !target.exists || !target.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(target.exists, "Could not find text \(text)")
    }

    private func tapText(containing text: String) {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let target = app.staticTexts.matching(predicate).firstMatch
        XCTAssertTrue(target.waitForExistence(timeout: 5), "Could not tap text \(text)")
        target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    private func tapButton(containing text: String) {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let target = app.buttons.matching(predicate).firstMatch
        for _ in 0..<8 {
            if target.exists && target.isHittable {
                target.tap()
                return
            }
            app.swipeUp()
        }
        if target.exists {
            target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            return
        }
        XCTFail("Could not tap button containing \(text)")
    }

    private func scrollToTop() {
        for _ in 0..<4 { app.swipeDown() }
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
