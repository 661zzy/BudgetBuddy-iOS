import SwiftUI
import UIKit

struct FeedbackView: View {
    @EnvironmentObject var store: AppStore
    @State private var note = ""
    @State private var copied = false

    private var hasCrash: Bool { Diagnostics.lastCrash() != nil }

    private var report: String {
        var s = "省钱搭子 BudgetBuddy · 诊断报告\n"
        s += "App: v\(Diagnostics.appVersion())\n"
        s += "设备: \(Diagnostics.deviceLine())\n"
        if let u = store.user { s += "账号: \(u.identifier) (id \(u.id))\n" }
        s += "数据: 记账 \(store.state.transactions.count) 笔 · 故事完成 \(store.storiesCompleted)"
        s += " · 课程 \(store.lessonsCompleted) · 挑战 \(store.activeChallengeCount) 进行中\n"
        s += "\n用户描述:\n\(note.isEmpty ? "（未填写）".tr : note)\n"
        if let crash = Diagnostics.lastCrash() {
            s += "\n=== ⚠️ 上次崩溃 ===\n\(crash)\n"
        }
        s += "\n=== 最近操作 / 网络日志 ===\n\(DiagLog.shared.recent())\n"
        return s
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("用着出问题了？在这里写一句话说明，然后把下面的诊断信息发给开发者，方便定位。".tr)
                    .font(.system(.subheadline, design: .rounded)).foregroundColor(.bbInk2)

                if let mail = URL(string: "mailto:support@budgetbuddy.cn") {
                    Link(destination: mail) {
                        HStack(spacing: 6) {
                            Image(systemName: "envelope")
                            Text("有任何使用问题，也可邮件 support@budgetbuddy.cn".tr)
                        }
                        .font(.system(.subheadline, design: .rounded).weight(.semibold)).foregroundColor(.bbGreen)
                    }
                }

                if hasCrash {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("检测到上次有一次崩溃，已包含在报告里。".tr)
                    }
                    .font(.system(.subheadline, design: .rounded)).foregroundColor(.bbRed)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.bbRed.opacity(0.10)))
                }

                Text("描述一下问题（选填）".tr).font(.system(.subheadline, design: .rounded).weight(.semibold)).foregroundColor(.bbInk)
                TextEditor(text: $note)
                    .font(.system(.body, design: .rounded))
                    .frame(height: 96).padding(8)
                    .scrollContentBackground(.hidden)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.bbSurface))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine))

                Text("诊断信息（会一起发送）".tr).font(.system(.subheadline, design: .rounded).weight(.semibold)).foregroundColor(.bbInk)
                Text(report)
                    .font(.system(.caption, design: .monospaced)).foregroundColor(.bbInk2)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.bbSurface))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine))

                ShareLink(item: report) {
                    Text("发送诊断报告".tr).font(.system(.headline, design: .rounded).weight(.bold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 15).duoPrimary()
                }
                Button {
                    UIPasteboard.general.string = report
                    copied = true
                } label: {
                    Text(copied ? "已复制 ✓".tr : "复制诊断信息".tr)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold)).foregroundColor(.bbGreen)
                        .frame(maxWidth: .infinity).padding(.vertical, 4)
                }
                if hasCrash {
                    Button { Diagnostics.clearLastCrash() } label: {
                        Text("清除崩溃记录".tr).font(.system(.caption, design: .rounded)).foregroundColor(.bbInk2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(16)
            .bbPageWidth()
        }
        .background(Color.bbBg)
        .navigationTitle("问题反馈".tr)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成".tr) { bbHideKeyboard() }.font(.system(.body, design: .rounded).weight(.semibold))
            }
        }
    }
}
