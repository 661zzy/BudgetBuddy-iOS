import SwiftUI

// Real 隐私政策 / 用户协议 pages (replace the placeholder alerts; required for App Store).
// NOTE: 联系邮箱 = support@budgetbuddy.cn; 运营主体 = 陈明明（个人开发者）— both filled.
// Have the final text reviewed before submission. This is an honest draft, not legal advice.

struct LegalSectionItem: Identifiable {
    let id = UUID()
    let heading: String
    let body: String
}

struct LegalView: View {
    let title: String
    let updated: String
    let intro: String
    let sections: [LegalSectionItem]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("最近更新：\(updated)").font(.caption).foregroundColor(.bbInk2)
                Text(intro).font(.subheadline).foregroundColor(.bbInk).lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(Array(sections.enumerated()), id: \.offset) { i, s in
                    VStack(alignment: .leading, spacing: 7) {
                        Text("\(i + 1). \(s.heading)").font(.headline).foregroundColor(.bbInk)
                        Text(s.body).font(.subheadline).foregroundColor(.bbInk2).lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .bbPageWidth()
        }
        .background(Color.bbBg)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

enum Legal {
    static var privacy: LegalView {
        LegalView(
            title: "隐私政策",
            updated: "2026 年 6 月",
            intro: "省钱搭子（BudgetBuddy）由个人开发者陈明明开发并运营（以下统称「开发者」或「我们」）。开发者尊重并保护你的隐私。本政策说明我们收集哪些信息、如何使用和保护它们，以及你拥有的权利。请在使用前仔细阅读。",
            sections: [
                LegalSectionItem(heading: "我们收集的信息", body: "为提供服务，我们会收集：① 注册信息——你填写的手机号或邮箱（作为账号标识）、昵称、所选年龄段；② 你主动录入的内容——记账记录、消费反思（需要/想要、计划内/计划外等）、故事/课程/挑战的进度；③ 当你使用「AI 搭子」时，你输入的对话内容。我们不会在后台收集你的通讯录、地理位置、相册等与功能无关的信息。"),
                LegalSectionItem(heading: "我们如何使用信息", body: "你的信息仅用于：提供记账、学习与 AI 复盘功能；在你登录的不同设备之间同步你的数据；保障账号安全、防止滥用。"),
                LegalSectionItem(heading: "关于 AI 功能", body: "当你使用「AI 搭子」时，你发送的消息会通过我们的服务器转发给第三方人工智能服务以生成回复。请不要在对话中输入身份证号、银行卡号、密码等敏感个人信息。"),
                LegalSectionItem(heading: "信息的存储与安全", body: "你的数据保存在与你账号关联的服务器数据库中。密码以加密（哈希）方式存储，我们无法看到你的明文密码；数据通过 HTTPS 加密传输。"),
                LegalSectionItem(heading: "信息的共享", body: "我们不会出售你的个人信息，也不会将其用于与本服务无关的用途。除实现 AI 功能所必需的第三方 AI 服务外，我们不会主动向第三方提供你的个人信息，法律法规另有要求的除外。"),
                LegalSectionItem(heading: "你的权利", body: "你可以随时：在「我的 → 编辑昵称」修改昵称；在「导出数据」导出你的全部数据；在「恢复默认数据」清空你的记录；在「删除账号」永久删除你的账号及全部数据（该操作不可恢复）。"),
                LegalSectionItem(heading: "未成年人保护", body: "本应用面向 14 周岁及以上的学生。若你未满 14 周岁，请在征得监护人同意后使用。我们仅收集为提供服务所必需的信息。"),
                LegalSectionItem(heading: "政策更新", body: "我们可能不时更新本政策，并在应用内提示。继续使用即表示你接受更新后的政策。"),
                LegalSectionItem(heading: "联系我们", body: "如对本政策有任何疑问，请通过 support@budgetbuddy.cn 与我们联系。"),
            ]
        )
    }

    static var terms: LegalView {
        LegalView(
            title: "用户协议",
            updated: "2026 年 6 月",
            intro: "欢迎使用省钱搭子（BudgetBuddy）。本应用由个人开发者陈明明开发并运营（以下统称「开发者」或「我们」）。在使用本应用前，请仔细阅读并同意本协议。",
            sections: [
                LegalSectionItem(heading: "服务说明", body: "省钱搭子是一款面向学生的财商教育与记账工具，帮助你练习记账、了解理财知识并复盘消费决定。应用内故事中的金钱均为模拟，不涉及任何真实交易或资金。"),
                LegalSectionItem(heading: "账号与责任", body: "你需提供真实有效的注册信息，并妥善保管账号与密码。你对在你账号下进行的活动负责。如发现账号被盗用，请及时修改密码。"),
                LegalSectionItem(heading: "使用规范", body: "你同意不利用本服务从事任何违法或干扰服务正常运行的行为，包括但不限于攻击服务器、批量注册、上传恶意内容等。"),
                LegalSectionItem(heading: "内容与免责", body: "本应用提供的是财商教育内容与记账工具，不构成任何投资、理财或法律建议。「AI 搭子」的回复由人工智能生成，仅供参考，可能存在不准确之处，请勿作为决策的唯一依据。"),
                LegalSectionItem(heading: "数据与隐私", body: "我们如何收集和处理你的数据，请参见《隐私政策》。"),
                LegalSectionItem(heading: "知识产权", body: "本应用的界面、文案、故事与课程内容等知识产权归开发者所有，未经许可不得擅自复制或用于商业用途。"),
                LegalSectionItem(heading: "协议的变更与终止", body: "我们可能更新本协议并在应用内提示。你可随时停止使用并删除账号；若你违反本协议，我们也可能暂停或终止你的账号。"),
                LegalSectionItem(heading: "联系我们", body: "如有疑问，请通过 support@budgetbuddy.cn 与我们联系。"),
            ]
        )
    }
}
