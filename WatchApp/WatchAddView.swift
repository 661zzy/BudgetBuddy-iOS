import SwiftUI

// 手表端配色与手机同一套语义（cream/ink/green）。
private let wBg = Color(red: 0.06, green: 0.06, blue: 0.05)
private let wGreen = Color(red: 0.35, green: 0.55, blue: 0.44)
private let wInk2 = Color(white: 0.62)

// 分类与手机 CATS 一致（key 直接落库，图标用 SF Symbol）。
private let WATCH_CATS: [(key: String, zh: String, icon: String)] = [
    ("food", "餐饮", "fork.knife"),
    ("transit", "交通", "bus.fill"),
    ("study", "学习", "book.fill"),
    ("daily", "生活用品", "cart.fill"),
    ("fun", "娱乐", "gamecontroller.fill"),
    ("medical", "医疗", "cross.case.fill"),
    ("other", "其他", "ellipsis.circle.fill"),
]

struct WatchAddView: View {
    @State private var amount: String
    @State private var saved = false

    init() {
        // UI-test seam: "-bb.uitest.prefill 15" pre-fills the amount so tests can
        // exercise save→sync without fighting the sim's synthetic-tap offset bug.
        let args = ProcessInfo.processInfo.arguments
        // UI-test seam: "-bb.uitest.customCats <json>" stands in for the phone's
        // application-context push, which the simulator can't deliver on its own.
        if let j = args.firstIndex(of: "-bb.uitest.customCats"), j + 1 < args.count {
            UserDefaults.standard.set(args[j + 1], forKey: WatchSync.customCatsKey)
        }
        if let i = args.firstIndex(of: "-bb.uitest.prefill"), i + 1 < args.count {
            _amount = State(initialValue: args[i + 1])
        } else {
            _amount = State(initialValue: "")
        }
    }

    private var amountValue: Double { Double(amount) ?? 0 }

    var body: some View {
        Group {
            if saved {
                savedView.navigationTitle("记一笔")
            } else {
                // watchOS 26 的大标题要占掉约 76pt——40mm 上那点高度全用来
                // 显示「记一笔」太奢侈了：键盘页把标题栏收起来，空间留给金额。
                keypad.toolbar(.hidden, for: .navigationBar)
            }
        }
    }

    // MARK: amount keypad

    // One screen, no scrolling — and the supported watches range from 40mm
    // (SE, ~171pt of content) to 49mm Ultra (~215pt). A fixed font that reads
    // well on the Ultra overflows the SE, so sizes are derived from the actual
    // height: keys and the action button take a fixed share, and the amount
    // gets whatever is left. That way it cannot overflow, and the number comes
    // out as large as the watch allows (was a flat 20pt, too small to glance at).
    private var keypad: some View {
        GeometryReader { geo in
            let gap: CGFloat = 3
            let gaps = gap * 5                       // 6 rows → 5 gaps
            let keyH = min(32, max(23, (geo.size.height - gaps) * 0.155))
            let btnH = min(30, max(23, (geo.size.height - gaps) * 0.145))
            let amountH = max(26, geo.size.height - gaps - keyH * 4 - btnH)
            let amountFont = min(44, max(24, amountH * 0.80))
            let keyFont = min(19, max(14, keyH * 0.55))

            VStack(spacing: gap) {
                Text("¥" + (amount.isEmpty ? "0" : amount))
                    .font(.system(size: amountFont, weight: .heavy, design: .rounded))
                    .foregroundColor(wGreen)
                    .frame(maxWidth: .infinity)
                    .frame(height: amountH)
                    .lineLimit(1).minimumScaleFactor(0.4)   // 六位数也不截断
                    .accessibilityIdentifier("watch.amount")

                let keys = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], [".", "0", "⌫"]]
                ForEach(keys, id: \.self) { row in
                    HStack(spacing: gap) {
                        ForEach(row, id: \.self) { k in
                            Button { tap(k) } label: {
                                Text(k)
                                    .font(.system(size: keyFont, weight: .semibold, design: .rounded))
                                    .foregroundColor(k == "⌫" ? .red : .white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: keyH)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.14)))
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                NavigationLink {
                    CategoryPickerView(amount: amountValue) { saved = true }
                } label: {
                    Text("选分类")
                        .font(.system(size: keyFont, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: btnH)
                        .background(RoundedRectangle(cornerRadius: 8).fill(amountValue > 0 ? wGreen : Color.gray.opacity(0.3)))
                }
                .buttonStyle(.plain)
                .disabled(amountValue <= 0)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func tap(_ k: String) {
        switch k {
        case "⌫": if !amount.isEmpty { amount.removeLast() }
        case ".": if !amount.contains(".") && !amount.isEmpty { amount += "." }
        default:
            if let dot = amount.firstIndex(of: "."), amount.distance(from: dot, to: amount.endIndex) > 2 { return }
            if amount.count >= 6 { return }
            amount = (amount == "0") ? k : amount + k
        }
    }

    private var savedView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44)).foregroundColor(wGreen)
            Text("已记下").font(.system(size: 16, weight: .bold))
            Text("打开 iPhone 后自动同步")
                .font(.system(size: 12)).foregroundColor(wInk2)
                .multilineTextAlignment(.center)
            Button("再记一笔") {
                amount = ""
                saved = false
            }
            .buttonStyle(.borderedProminent).tint(wGreen)
            .font(.system(size: 14, weight: .semibold))
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                if saved { amount = ""; saved = false }
            }
        }
    }
}

// Pushed page; saving must both queue the entry AND pop back to the root so
// the confirmation isn't hidden underneath the navigation stack.
private struct CategoryPickerView: View {
    let amount: Double
    let onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @AppStorage(WatchSync.customCatsKey) private var customCatsJSON = "[]"

    // Custom categories from the phone; the name itself is what gets logged.
    private var customCats: [(name: String, icon: String)] {
        guard let data = customCatsJSON.data(using: .utf8),
              let list = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] else { return [] }
        return list.compactMap { d in
            guard let n = d["name"], !n.isEmpty else { return nil }
            return (n, d["icon"] ?? "tag.fill")
        }
    }

    var body: some View {
        List {
            ForEach(WATCH_CATS, id: \.key) { c in
                Button {
                    WatchSync.shared.queueExpense(amount: amount, cat: c.key)
                    onSaved()
                    dismiss()
                } label: {
                    Label(c.zh, systemImage: c.icon)
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            ForEach(customCats, id: \.name) { c in
                Button {
                    WatchSync.shared.queueExpense(amount: amount, cat: c.name)
                    onSaved()
                    dismiss()
                } label: {
                    Label(c.name, systemImage: c.icon)
                        .font(.system(size: 15, weight: .semibold))
                }
                .accessibilityIdentifier("watch.cat.\(c.name)")
            }
        }
        .navigationTitle("¥\(amount == amount.rounded() ? String(Int(amount)) : String(amount))")
    }
}
