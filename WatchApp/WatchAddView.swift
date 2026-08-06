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
        if let i = args.firstIndex(of: "-bb.uitest.prefill"), i + 1 < args.count {
            _amount = State(initialValue: args[i + 1])
        } else {
            _amount = State(initialValue: "")
        }
    }

    private var amountValue: Double { Double(amount) ?? 0 }

    var body: some View {
        Group {
            if saved { savedView } else { keypad }
        }
        .navigationTitle("记一笔")
    }

    // MARK: amount keypad

    // Everything must fit one 46mm screen (~248pt incl. nav bar) — the default
    // .bordered buttons are ~52pt tall and overflow, so keys are drawn plain
    // with a fixed compact height.
    private var keypad: some View {
        VStack(spacing: 3) {
            Text("¥" + (amount.isEmpty ? "0" : amount))
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(wGreen)
                .frame(maxWidth: .infinity)
                .lineLimit(1).minimumScaleFactor(0.5)
                .accessibilityIdentifier("watch.amount")

            let keys = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], [".", "0", "⌫"]]
            ForEach(keys, id: \.self) { row in
                HStack(spacing: 3) {
                    ForEach(row, id: \.self) { k in
                        Button { tap(k) } label: {
                            Text(k)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(k == "⌫" ? .red : .white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 30)
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
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 30)
                    .background(RoundedRectangle(cornerRadius: 8).fill(amountValue > 0 ? wGreen : Color.gray.opacity(0.3)))
            }
            .buttonStyle(.plain)
            .disabled(amountValue <= 0)
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
        }
        .navigationTitle("¥\(amount == amount.rounded() ? String(Int(amount)) : String(amount))")
    }
}
