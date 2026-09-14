import SwiftUI

// Lightweight runtime i18n. The CHINESE literal is the key; `.tr` swaps in the
// idiomatic English when the app language is "en". Unknown keys fall back to the
// Chinese original, so not-yet-translated content (stories/lessons/codex JSON)
// renders unchanged instead of breaking. RootView carries `.id(bb.lang)` so a
// switch rebuilds the whole tree instantly — no app restart needed.
enum BBLang {
    static let key = "bb.lang"
    static var current: String { UserDefaults.standard.string(forKey: key) ?? "zh" }
    static var isEN: Bool { current == "en" }
    static func set(_ lang: String) { UserDefaults.standard.set(lang, forKey: key) }
    static var chosen: Bool { UserDefaults.standard.string(forKey: key) != nil }
}

extension String {
    var tr: String {
        guard BBLang.isEN else { return self }
        return L10n.en[self] ?? L10n.contentEN[self] ?? self
    }
}

/// Map an APIError to an English message by its machine code (falls back to the
/// server's Chinese text; returns nil for non-API errors so callers keep their default).
func bbAPIMessage(_ error: Error) -> String? {
    guard let e = error as? APIError else { return nil }
    return L10n.apiMessage(code: e.code, fallback: e.message)
}

enum L10n {
    /// Bundled zh→en map for CONTENT (stories/lessons/codex), generated from the
    /// Chinese source of truth. Loaded once; missing keys fall back to Chinese.
    static let contentEN: [String: String] = {
        guard let url = Bundle.main.url(forResource: "content_en", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let d = try? JSONDecoder().decode([String: String].self, from: data) else { return [:] }
        return d
    }()

    static let en: [String: String] = [
        // v1.6.1 自定义记账分类
        "分类": "Category",
        "自定义": "Custom",
        "新建分类": "New category",
        "编辑分类": "Edit category",
        "新分类": "New category",
        "分类名称": "Category name",
        "比如：水电、房租": "e.g. Utilities, Rent",
        "选个图标": "Pick an icon",
        "重命名": "Rename",
        "长按自定义分类可以改名或删除": "Long-press a custom category to rename or delete it",
        "已经记下的账会保留这个名字，只是以后不会出现在分类里。": "Entries you've already logged keep this name. It just won't show up as a choice anymore.",
        "分类跟着账号保存，换手机或重装后登录也还在。": "Categories are saved to your account, so they come back when you sign in on a new phone.",
        "给分类起个名字吧": "Give the category a name",
        "这个名字和系统分类重复了": "That name is already a built-in category",
        "已经有这个分类了": "You already have that category",
        "保存失败，请重试": "Couldn't save. Try again.",
        // v1.6 财商快答 (Money Blitz)
        "5 道题 · 约 2 分钟": "5 questions · 2 min",
        "上次的你": "You, last time",
        "下一题": "Next question",
        "为 什 么": "WHY",
        "今 日 快 答": "DAILY BLITZ",
        "今日快答": "Daily Blitz",
        "你": "You",
        "你拿了第一！": "You came first!",
        "先看题…": "Read the question…",
        "全部答对，这一包你已经会了。": "All correct. You've got this pack.",
        "全部题包": "All packs",
        "再来一局": "Play again",
        "对": "True",
        "已加入错题本": "Saved for review",
        "幽灵": "Ghost",
        "快答挑战": "Money Blitz",
        "排 行": "STANDINGS",
        "排名": "Rank",
        "新纪录": "New best",
        "首次挑战完成": "First run done",
        "时间到": "Time's up",
        "最高连对": "Best streak",
        "本 局 对 手": "YOUR RIVALS",
        "看成绩单": "See my results",
        "看结果": "See results",
        "确定": "Lock it in",
        "答对": "Correct",
        "答对了": "Correct",
        "答错了": "Not quite",
        "继续答题": "Keep playing",
        "还没挑战": "Not played yet",
        "这一局的分数不会保存。": "This round's score won't be saved.",
        "连续天数": "Day streak",
        "退出": "Quit",
        "退出这一局？": "Quit this round?",
        "错": "False",
        "错 题 回 顾": "MISTAKES",
        "错题本是空的，没有要复习的题。": "Nothing to review. Your mistake list is empty.",
        "错题重练": "Review mistakes",
        "限时作答，越快分越高；连对有奖励。每道题答完，都会告诉你为什么。": "Answer against the clock: faster means more points, and streaks earn a bonus. After every question you'll see why.",
        "限时抢答，答得越快分越高": "Beat the clock. Faster answers score more",
        "颁 奖 台": "PODIUM",
        "题 包": "PACKS",
        "（没作答）": "(no answer)",
        // v1.5.3 — daily reminder, update skip, age at sign-up
        "今天的故事等你来选": "Today's story is waiting for you",
        "三分钟，做一个不花真钱的选择。": "Three minutes, one choice — and no real money on the line.",
        "每日故事提醒": "Daily story reminder",
        "每天 20:00": "Every day at 8 pm",
        "通知权限已关闭，请到系统设置里允许": "Notifications are off — allow them in Settings",
        "每天提醒我来玩一个故事": "Remind me to play a story every day",
        "晚上 8 点一条提醒，随时可在「我的」里关掉": "One nudge at 8 pm. Switch it off any time in Me.",
        "已开启，每天 20:00 见": "On — see you at 8 pm",
        "这个版本不再提醒": "Skip this version",
        "年龄": "Age",
        "14 岁及以上": "14 or older",
        "未满 14 岁": "Under 14",
        "我的监护人已同意我注册并使用": "My parent or guardian has agreed to this",
        "未满 14 岁需要监护人同意后才能注册": "Under 14, a parent or guardian needs to agree before you can sign up",
        "面向 14 岁及以上的学生。未满 14 岁，请在监护人同意和陪同下使用。": "For students 13 and up (14 in mainland China). Younger? Use it with a parent or guardian's consent.",
        // ---- tabs ----
        "首页": "Home", "记账": "Track", "故事": "Stories", "AI搭子": "AI Buddy", "我的": "Me",
        // ---- home ----
        "今 日 故 事": "TODAY'S STORY", "全部故事": "All stories",
        "记录一次选择": "Log a choice", "每一笔消费，都是一次决定": "Every purchase is a decision",
        "本 周 概 览": "THIS WEEK", "搭 子 说": "BUDDY'S TIP",
        "做选择前，先停三秒": "Pause three seconds before you choose",
        "想要还是需要？这一笔花完，未来的你会感谢现在的决定吗？": "Want or need? Will future-you thank you for this one?",
        "找搭子复盘一下": "Talk it over with your buddy",
        "进入故事": "Start the story", "这个月有 ¥1000，看看你能不能稳稳花到月底。": "¥1000 for the month — see if you can cruise to the end without crashing", "今天": "Today", "消费观念": "Money mindset", "3分钟": "3 min",
        "完成故事": "Stories done", "记录选择": "Choices logged", "解锁图鉴": "Cards unlocked", "学完课程": "Lessons done",
        // ---- AI buddy ----
        "我是你的决策复盘搭子，想聊聊哪一笔消费？": "I'm your money buddy. Which purchase shall we talk about?",
        "说说你的一次选择…": "Tell me about a choice…", "搭子正在想…": "Buddy is thinking…",
        "哎呀，我这会儿没连上网 😅 把刚才的问题再发一次试试？": "Oops, I lost my connection 😅 Mind sending that again?",
        // ---- profile ----
        "学生": "Student", "大学生": "College student", "14岁以下": "Under 14", "14–17岁": "14–17", "18–22岁": "18–22", "23岁以上": "23+", "已记账": "logging for", "天": "days",
        // ---- guest mode (optional login) ----
        "未登录": "Not signed in", "登录 / 注册": "Sign in / Sign up",
        "游客模式 · 数据保存在本机": "Guest mode · data stays on this device",
        "同步与找回数据": "Sync & restore data", "未开启": "Off",
        "登录后，你的记账和故事进度会自动同步到云端，换设备也不会丢。现在的数据只保存在这台手机上。":
            "Sign in and your logs and story progress sync to the cloud, safe across devices. Right now your data lives only on this phone.",
        "暂不登录，先逛逛": "Not now, just browsing",
        "登录后开始记账": "Sign in to start tracking",
        "你的每一笔记账都会安全同步到自己的账号，换设备登录也不会丢。":
            "Every entry syncs safely to your own account — nothing gets lost when you switch devices.",
        "记账天数": "Days logged", "故 事 与 学 习": "STORIES & LEARNING", "我 的 记 录": "MY RECORDS", "账 户": "ACCOUNT",
        "已通关故事": "Stories completed", "已解锁图鉴": "Codex cards", "理财课程": "Money lessons",
        "已完成": "Done", "我的挑战": "My challenges", "个进行中": "active", "去看看": "Take a look",
        "消费选择记录": "Choice log", "次": "times", "云端同步": "Cloud sync", "已开启": "On",
        "编辑昵称": "Edit nickname", "导出数据": "Export data", "问题反馈": "Feedback",
        "去 App Store 评分": "Rate on the App Store",
        // ---- engagement funnel (v1.5.x), staged as a story scene ----
        "现实场景": "Real life", "搭子想问你一句": "Your buddy has a question",
        "你已经在这儿待了 %d 分钟。花 10 秒，让它对下一个人更好用？":
            "You've spent %d minutes here. Got ten seconds to make it better for whoever comes next?",
        "你已经用了好一阵了。花 10 秒，让它对下一个人更好用？":
            "You've been using this a while. Got ten seconds to make it better for whoever comes next?",
        "去 App Store 打个分": "Rate it on the App Store",
        "让更多同学找得到它": "Helps more people find it",
        "有问题，想吐槽": "Something's off — tell us",
        "直接发给开发者，很快能看到": "Goes straight to the developer",
        "先不了，继续用": "Not now, keep going",
        // ---- one-tap feedback (v1.5.x) ----
        "直接发送": "Send now", "发送中…": "Sending…", "已发送，谢谢反馈 ✓": "Sent — thank you ✓",
        "没发出去，试试下面的分享或邮件方式": "Couldn't send — try share or email below",
        "或通过分享 / 邮件发送": "Or send via share / email",
        "截图（选填，最多 3 张）": "Screenshots (optional, up to 3)", "添加": "Add",
        "%d 张截图会跟着一起发出": "%d screenshot(s) will be sent along",
        "推荐给朋友": "Share with friends",
        "我在用省钱搭子练财商，故事挺好玩的，推荐你试试！": "I'm using BudgetBuddy to practice money skills — the stories are fun. Give it a try!",
        "恢复默认数据": "Reset my data", "退出登录": "Log out", "删除账号": "Delete account",
        "用户协议": "Terms of Service", "隐私政策": "Privacy Policy", "语言": "Language",
        // ---- auth ----
        "欢迎回来": "Welcome back", "创建账号": "Create account",
        "记好每一笔，存下每一分": "Know your spending, grow your savings",
        "登录": "Log in", "注册": "Sign up", "手机号或邮箱": "Phone or email",
        "密码": "Password", "密码（≥8位，含大小写字母）": "Password (8+ chars, upper & lower case)",
        "昵称": "Nickname", "验证码": "Code", "发送验证码": "Send code", "发送中": "Sending…",
        "注册并登录": "Sign up & log in", "请稍候…": "One sec…", "忘记密码？": "Forgot password?",
        "登录即代表同意《用户协议》和《隐私政策》": "By continuing, you agree to our Terms of Service and Privacy Policy",
        "请输入有效的手机号或邮箱": "Enter a valid phone number or email",
        "密码至少 8 位，且需同时包含大写和小写字母": "Password needs 8+ characters, with both UPPER and lower case letters",
        "请填写昵称": "Pick a nickname first", "请先获取并填写验证码": "Get and enter the code first",
        "出错了，请重试": "Something went wrong — try again", "验证码发送失败": "Couldn't send the code",
        "测试模式：验证码已自动填入": "Test mode: code auto-filled",
        "验证码短信已发送，请查收": "Code sent by SMS — check your messages",
        "验证码邮件已发送，请查收": "Code sent — check your inbox",
        // ---- forgot password ----
        "用注册时的手机号或邮箱接收验证码，设置新密码。": "Get a code via the phone or email you signed up with, then set a new password.",
        "新密码（≥8位，含大小写字母）": "New password (8+ chars, upper & lower case)",
        "重置密码并登录": "Reset & log in", "找回密码": "Reset password", "取消": "Cancel",
        "请填写验证码": "Enter the code", "重置失败，请重试": "Reset failed — try again",
        // ---- onboarding ----
        "跳过": "Skip", "下一步": "Next", "开始体验": "Get started",
        "在真实情境里，练习每一次用钱选择": "Practice money choices in real-life stories",
        "花了钱就记一下，三秒搞定，慢慢来就好": "Spent something? Log it in three seconds. No pressure.",
        "存钱目标看得见": "Watch your savings goals grow",
        "设个小目标，进度条一点点涨，存钱也有成就感": "Set a small goal and enjoy the progress bar filling up.",
        "省钱搭子帮你出主意": "Your buddy has your back",
        "哪里花多了、怎么省下来，搭子用大白话告诉你": "Where the money leaks and how to plug it — in plain words.",
        // ---- story hub / codex / lessons ----
        "互 动 故 事": "INTERACTIVE STORIES", "更 多": "MORE", "已通关": "Cleared",
        "故事里的钱都是模拟的，放心大胆做选择，做错了也只是长经验。": "All money in stories is pretend — choose boldly, mistakes only earn you experience.",
        "认知图鉴": "Codex", "还没有解锁图鉴": "No cards unlocked yet",
        "去玩一个互动故事，通关后就能解锁对应的认知图鉴。": "Play a story to the end to unlock its codex card.",
        "未 解 锁": "LOCKED", "已解锁": "Unlocked", "相关故事": "Related story",
        "通关": "Clear", "解锁": "to unlock", "再玩一次": "Play again", "完成": "Done",
        "互动故事": "Interactive stories", "情景里做决定": "Decide in real scenarios", "跟着课程学": "Learn step by step",
        "标记完成": "Mark as done",
        "冲动消费": "Impulse buying",
        "看到「限时」「打折」就心跳加速": "Your heart races when you see “limited time” or “discount”",
        "明明能用却想换新的": "You want a replacement even when the old one still works",
        "买完很快就后悔": "You regret the purchase soon after buying it",
        "想买非必需品先等 24 小时": "Wait 24 hours before buying anything non-essential",
        "买前问一句：没有它会怎样": "Ask first: what happens if I don’t buy it?",
        "购物前列清单，只买清单上的": "Make a shopping list and buy only what’s on it",
        "小额高频陷阱": "The small-but-often trap",
        "单笔不贵，次数很多": "Each purchase is cheap, but it happens often",
        "奶茶、外卖、零食随手就买": "Boba, takeout, and snacks become automatic buys",
        "月底想不起钱花哪了": "By month-end, you can’t remember where the money went",
        "用「次数」给自己定上限": "Set a limit by number of times, not just by amount",
        "先存后花，省下的立刻存起来": "Save first, then spend — move savings away immediately",
        "稳赚骗局": "Guaranteed-profit scams",
        "承诺「稳赚不赔」「一个月翻倍」": "It promises “guaranteed profit” or “double your money in a month”",
        "陌生人热情拉你「一起赚钱」": "A stranger eagerly invites you to “make money together”",
        "要先交钱 / 发红包才有好处": "You must pay upfront or send a red packet to get the reward",
        "凡是「稳赚」一律不信": "Treat every “guaranteed profit” claim as suspicious",
        "不点陌生链接、不给验证码": "Don’t tap unknown links or share verification codes",
        "拿不准先问信任的人": "If you’re unsure, ask someone you trust first",
        "先花后存": "Spend first, save later",
        "想着「月底有剩再存」": "You plan to save whatever is left at month-end",
        "一分都剩不下": "Nothing is left to save",
        "存钱目标总是停在原地": "Your savings goal never moves",
        "发钱当天先存一小笔": "Save a small amount the day money arrives",
        "金额不用大，能坚持最重要": "The amount can be small — consistency matters most",
        "把存的钱放到不易动的地方": "Put saved money somewhere harder to touch",
        "应急借款的代价": "The cost of emergency borrowing",
        "「0 利息」「借钱秒到」很诱人": "“0% interest” and “instant cash” look tempting",
        "只看今天能不能解决": "You only focus on whether it solves today’s problem",
        "没算清要还多少": "You haven’t calculated the full repayment",
        "借钱前先算清要还的总数": "Before borrowing, calculate the total you must repay",
        "先比较有没有更省的办法": "Compare whether there is a cheaper option first",
        "平时攒一笔小应急金": "Build a small emergency fund ahead of time",
        // ---- tracker ----
        "本月结余": "Net this month", "总结与建议": "Summary & advice",
        "本月支出": "Spent", "本月收入": "Income", "共": "·", "笔": "entries",
        // ---- weekly/monthly summary (v1.3) ----
        "昨天": "Yesterday", "本周": "Week", "本月": "Month",
        "本周结余": "Net this week", "本周支出": "Spent", "本周收入": "Income",
        "本周笔数": "Entries", "周记账天数": "Days logged",
        // ---- iPad layout (v1.3) ----
        "记 一 笔": "QUICK ADD", "可以这样开场": "Ways to start",
        "这周奶茶花多了怎么办？": "I spent too much on bubble tea this week — help?",
        "帮我复盘昨天一笔冲动消费": "Help me review an impulse buy from yesterday",
        "给我一个这周能做到的省钱小目标": "Give me a small savings goal I can hit this week",
        "还没有记录": "Nothing logged yet", "从今天开始，记录一次真实的消费选择。": "Start today — log one real spending choice.",
        "发生了什么？（选填）": "What happened? (optional)", "记一笔": "Add entry",
        "花完之后，停三秒回顾一下——想记就记，跳过也没关系。": "Take three seconds to reflect — log it if you like, skipping is fine too.",
        "记录这次选择": "Log this choice", "记一次选择": "Reflect",
        "钱花在哪儿": "Where it went", "搭子帮你看看": "Buddy's take",
        "正在分析你的花销…": "Crunching your numbers…", "记账总结": "Summary", "再分析一次": "Analyze again",
        "本月笔数": "Entries", "保存这一笔": "Save this entry", "记录第一次选择": "Log your first choice", "累计结余": "All-time net", "保存": "Save", "支出": "Expense", "收入": "Income",
        // ---- categories ----
        "餐饮": "Food", "交通": "Transit", "学习": "Study", "生活用品": "Daily", "娱乐": "Fun", "医疗": "Health", "其他": "Other",
        // ---- sweep-2: challenges / feedback / dialogs / reflect / story player ----
        "正在连接…": "Connecting…", "来自": "From", "请求失败": "Request failed", "注册失败，请重试": "Sign-up failed — try again", "登录失败，请重试": "Login failed — try again",
        "删除失败，请重试": "Couldn't delete — try again", "陪你把每一次选择，变成更好的决定": "Turning every choice into a better decision, together",
        "好的": "OK", "你的数据已安全保存到你的账号，换个设备登录也能看到自己的记录。": "Your data is saved to your account — log in on any device and pick up right where you left off.",
        "恢复默认数据？": "Reset your data?", "恢复": "Reset", "你记的账和故事进度会被清空。": "Your entries and story progress will be wiped.",
        "这将永久删除你的账号和所有数据（记账、故事进度、挑战），且无法恢复。": "This permanently deletes your account and all your data (entries, story progress, challenges). It cannot be undone.",
        "当前密码": "Current password", "永久删除账号": "Permanently delete account", "删除中": "Deleting…", "删除": "Delete",
        "进行中": "Active", "累计省下": "Total saved", "还没有进行中的挑战，下面挑一个开始吧": "No active challenges yet — pick one below to get started",
        "推荐挑战": "Recommended", "还没有完成的挑战，坚持打卡就能拿到第一个": "None finished yet — keep checking in and your first badge will come",
        "挑战完成": "Challenge complete", "今天已打卡": "Checked in today", "挑战": "Challenge", "今日打卡": "Check in today", "开始": "Start",
        "（未填写）": "(not filled in)", "用着出问题了？在这里写一句话说明，然后把下面的诊断信息发给开发者，方便定位。": "Something not working? Jot a quick note, then send the diagnostics below so the developer can track it down.",
        "有任何使用问题，也可邮件 support@budgetbuddy.cn": "Questions? Email support@budgetbuddy.cn any time",
        "检测到上次有一次崩溃，已包含在报告里。": "We noticed a crash last time — it's included in this report.",
        "描述一下问题（选填）": "Describe the problem (optional)", "诊断信息（会一起发送）": "Diagnostics (sent along with it)",
        "发送诊断报告": "Send report", "已复制 ✓": "Copied ✓", "复制诊断信息": "Copy diagnostics", "清除崩溃记录": "Clear crash record",
        "练习沙盘": "Practice arena", "反复练「想要还是需要」的冷静一秒": "Drill that one-second pause: want or need?",
        "配套视频": "Video", "视频": "video", "识别信号": "Warning signs", "应对动作": "What to do", "重点": "Key points",
        "学生例子": "Student example", "今天的小任务": "Today's mini-task", "已完成 · 取消标记": "Done · tap to unmark",
        "开始游戏": "Start", "看看结果": "See the results", "继续": "Continue",
        "做得好": "What went well", "可以更好": "Could be better", "养成习惯": "Habit to build",
        "余额": "Balance", "心情": "Mood", "健康": "Health", "信用": "Credit", "风险": "Risk",
        "好": "Good", "一般": "OK", "低落": "Low", "低": "Low", "中": "Mid", "高": "High",
        "这是需要，还是想要？": "Need, or want?", "提前想好的，还是临时决定？": "Planned, or spur of the moment?",
        "是什么影响了你？": "What nudged you?", "花完之后感觉怎么样？": "How did it feel afterwards?",
        "需要": "Need", "想要": "Want", "不确定": "Not sure", "计划内": "Planned", "计划外": "Unplanned",
        "同学": "Friends", "平台广告": "Ads", "限时优惠": "Flash deal", "情绪": "Mood swing", "家庭需要": "Family need",
        "值得": "Worth it", "后悔": "Regret",
        "哎呀，刚才没连上 AI 😅 点下方「再分析一次」我再帮你看看。": "Oops, couldn't reach the AI 😅 Tap \"Analyze again\" below and I'll take another look.",
        "预算入门": "Budgeting 101", "记账习惯": "Logging habits", "储蓄目标": "Saving goals", "消费提醒": "Smart spending", "基础金融安全": "Money safety basics",
        // ---- challenge content (7 defs) ----
        "简单": "Easy", "中等": "Medium", "入门": "Starter", "进阶": "Advanced",
        "3 天不点外卖": "3 days, no takeout", "连续 3 天自己吃食堂，省下外卖钱": "Eat at the canteen 3 days straight and bank the delivery money",
        "中午去食堂，晚上煮个面，省下的外卖钱当天就存进目标。": "Canteen at noon, noodles at night — bank the savings the same day.",
        "3 天不买奶茶": "3 days, no bubble tea", "馋的时候先喝口水等十分钟": "When the craving hits, sip some water and wait ten minutes",
        "把奶茶换成自带水或便利店饮料，省下的钱看得见。": "Swap bubble tea for your own bottle — you'll see the savings add up.",
        "7 天记账挑战": "7-day logging streak", "连续 7 天，每天至少记一笔": "Log at least one entry a day, 7 days running",
        "付完款马上记，三秒搞定，别等晚上才回忆。": "Log right after you pay — three seconds now beats guessing tonight.",
        "交通省钱挑战": "Cheap commute challenge", "5 天用走路 / 骑车 / 公交代替打车": "Walk, bike or bus instead of ride-hailing for 5 days",
        "3 公里内走路或骑共享单车，远的坐公交地铁，不打车。": "Under 3 km, walk or grab a shared bike; farther, bus or metro — no taxis.",
        "零食预算挑战": "Snack budget challenge", "一周零食花费控制在 ¥30 内": "Keep a week of snacks under ¥30",
        "给零食定个一周上限，买之前先看看还剩多少额度。": "Set a weekly snack cap and check what's left before you buy.",
        "本周娱乐 ¥50 挑战": "¥50 fun-budget week", "这一周娱乐花费不超过 ¥50": "Keep this week's fun spending under ¥50",
        "把娱乐花费记下来，到 ¥50 就停，剩下的留到下周。": "Track your fun spending, stop at ¥50, and roll the rest into next week.",
        "7 天不冲动消费": "7 days, no impulse buys", "想买非必需品先等一天再决定": "Want a non-essential? Sleep on it for a day first",
        "想买的非必需品先放购物车，等 24 小时再决定。": "Park non-essentials in the cart and decide after 24 hours.",
        // ---- update sheet ----
        "重要": "Must-know", "预算管理": "Budgeting", "金融安全": "Money safety", "应急与借款": "Emergencies & borrowing", "隐藏规则": "Hidden rules", "人情与消费": "Social spending", "人情与信用": "Friends & credit", "借贷与利息": "Loans & interest", "收入与规划": "Income & planning", "消费决策": "Spending decisions", "自我投资": "Investing in yourself", "2分钟": "2 min", "4分钟": "4 min", "5分钟": "5 min", "已存": "Saved", "在手": "In hand", "饭卡": "Meal card", "需要更新": "Update required", "有新版本": "Update available", "去更新": "Update now", "稍后再说": "Later",
        "发现新版本，建议更新以获得更好体验。": "A new version is available — update for the best experience.",
        "请更新到最新版本后继续使用。": "Please update to the latest version to continue.",
    ]

    /// Server errors arrive in Chinese; map the machine `code` to English when needed.
    static func apiMessage(code: String, fallback: String) -> String {
        guard BBLang.isEN else { return fallback }
        return enErrors[code] ?? fallback
    }
    static let enErrors: [String: String] = [
        "BAD_CREDENTIALS": "Wrong account or password",
        "RATE_LIMITED": "Too many attempts — try again later",
        "VALIDATION_ERROR": "Please check what you entered",
        "CONFLICT": "This account already exists — just log in",
        "SEND_FAILED": "Couldn't send the code — try again later",
        "NETWORK": "Can't reach the server — check your connection",
        "AI_BUSY": "The AI is busy — try again in a moment",
        "AI_FALLBACK": "The AI is busy — try again in a moment",
        "INTERNAL_ERROR": "Server hiccup — try again later",
    ]
}
