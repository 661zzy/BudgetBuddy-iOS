import SwiftUI

struct TrackerView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAdd = false
    @State private var showAuth = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bbBg.ignoresSafeArea()
                if store.isGuest {
                    // 记账是账号功能：数据云端同步，需要登录。进入本页自动弹登录。
                    loginGate
                } else if store.state.transactions.isEmpty {
                    emptyState
                } else {
                    List {
                        Section {
                            NavigationLink { TrackerSummaryView() } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("本月结余".tr).font(.caption).foregroundColor(.bbInk2)
                                        Text("\(store.monthNet >= 0 ? "" : "−")¥\(abs(Int(store.monthNet)))")
                                            .font(.system(.title2, design: .rounded).weight(.bold))
                                            .foregroundColor(store.monthNet >= 0 ? .bbGreen : .bbRed)
                                    }
                                    Spacer()
                                    HStack(spacing: 5) { Image(systemName: "sparkles"); Text("总结与建议".tr) }
                                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                        .foregroundColor(.bbGreen)
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(Color.bbSurface)
                        } footer: {
                            Text("本月支出".tr + " ¥\(Int(store.monthOut)) · \(store.state.transactions.count) " + "笔".tr)
                                .font(.caption).foregroundColor(.bbInk2)
                        }
                        // Grouped by day — every entry auto-records its time (ts),
                        // shown per row; day headers carry the day's spend total.
                        ForEach(dayGroups, id: \.key) { grp in
                            Section {
                                ForEach(grp.items) { t in
                                    row(t)
                                }
                                .onDelete { offsets in
                                    let ids = offsets.map { grp.items[$0].id }
                                    Task { for id in ids { await store.deleteTransaction(id) } }
                                }
                            } header: {
                                HStack {
                                    Text(grp.label)
                                    Spacer()
                                    if grp.out > 0 { Text("支出".tr + " ¥\(Int(grp.out))") }
                                }
                                .font(.caption).foregroundColor(.bbInk2)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("记账".tr)
            .toolbar {
                if !store.isGuest {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button { showAdd = true } label: { Image(systemName: "plus") }
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddSheet().environmentObject(store)
            }
            .sheet(isPresented: $showAuth) {
                AuthView().environmentObject(store)
            }
            .onAppear {
                if store.isGuest { showAuth = true }   // 自动跳出登录
            }
        }
    }

    // Guests see why login is needed here (cloud-synced ledger = account feature)
    // and can reopen the sheet any time after dismissing the automatic one.
    private var loginGate: some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 28).fill(Color(hex: 0xE4EFE7)).frame(width: 120, height: 120)
                Image(systemName: "lock.shield").font(.system(size: 52)).foregroundColor(Color(hex: 0x3E5F4D))
            }
            .padding(.bottom, 6)
            Text("登录后开始记账".tr).font(.title3.bold()).foregroundColor(.bbInk)
            Text("你的每一笔记账都会安全同步到自己的账号，换设备登录也不会丢。".tr)
                .font(.subheadline).foregroundColor(.bbInk2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Button { showAuth = true } label: {
                Text("登录 / 注册".tr).font(.system(.headline, design: .rounded).weight(.bold)).foregroundColor(.white)
                    .padding(.horizontal, 44).padding(.vertical, 14)
                    .duoPrimary()
            }
            .padding(.top, 8)
        }
        .padding()
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray").font(.system(size: 40)).foregroundColor(.bbInk2)
            Text("还没有记录".tr).font(.headline).foregroundColor(.bbInk)
            Text("从今天开始，记录一次真实的消费选择。".tr)
                .font(.subheadline).foregroundColor(.bbInk2)
                .multilineTextAlignment(.center)
            Button { showAdd = true } label: {
                Label("记录第一次选择".tr, systemImage: "plus")
                    .foregroundColor(.white)
                    .padding(.horizontal, 18).padding(.vertical, 12)
                    .background(Color.bbGreen).cornerRadius(12)
            }
        }
        .padding()
    }

    // Newest day first; within a day newest entry first.
    private var dayGroups: [(key: String, label: String, out: Double, items: [Transaction])] {
        let grouped = Dictionary(grouping: store.state.transactions) { bbDayKey($0.ts) }
        return grouped.keys.sorted(by: >).map { k in
            let items = (grouped[k] ?? []).sorted { $0.ts > $1.ts }
            let out = items.filter { $0.kind == "out" }.reduce(0) { $0 + $1.amount }
            return (k, bbDayLabel(items.first?.ts ?? ""), out, items)
        }
    }

    private func row(_ t: Transaction) -> some View {
        HStack(spacing: 12) {
            Image(systemName: CATS[t.cat]?.icon ?? "circle.fill")
                .foregroundColor(.bbGreen).frame(width: 26)
            VStack(alignment: .leading, spacing: 3) {
                Text(t.note.isEmpty ? (CATS[t.cat]?.zh.tr ?? t.cat) : t.note).foregroundColor(.bbInk)
                HStack(spacing: 6) {
                    Text(bbTimeLabel(t.ts)).font(.caption2).foregroundColor(.bbInk2.opacity(0.8))
                    Text(CATS[t.cat]?.zh.tr ?? t.cat).font(.caption).foregroundColor(.bbInk2)
                    if let need = t.reflect?.need {
                        Text(need.tr).font(.caption2)
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(Capsule().fill(Color.bbGreen.opacity(0.12)))
                            .foregroundColor(.bbGreen)
                    }
                }
            }
            Spacer()
            Text("\(t.kind == "in" ? "+" : "−")¥\(Int(t.amount))")
                .font(.system(.body, design: .rounded))
                .foregroundColor(t.kind == "in" ? .bbGreen : .bbInk)
        }
        .listRowBackground(Color.bbBg)
    }
}

// MARK: - 记一笔 (keypad + category chips)

struct AddSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var amount = ""
    @State private var cat = "food"
    @State private var note = ""
    @State private var kind = "out"
    @State private var showReflect = false
    @State private var pendingId = ""

    private var canSave: Bool { (Double(amount) ?? 0) > 0 }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    toggle("支出".tr, "out")
                    toggle("收入".tr, "in")
                }
                .padding(.horizontal, 16).padding(.top, 12)

                Text("¥\(amount.isEmpty ? "0" : amount)")
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .foregroundColor(kind == "in" ? .bbGreen : .bbInk)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)

                if kind == "out" {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(EXPENSE_CATS, id: \.self) { c in catChip(c) }
                        }
                        .padding(.horizontal, 16).padding(.bottom, 6)
                    }
                }

                TextField("发生了什么？（选填）".tr, text: $note)
                    .font(.system(.body, design: .rounded))
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.bbSurface))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.bbLine))
                    .padding(.horizontal, 16).padding(.top, 10)

                Spacer(minLength: 10)
                keypad
                Button { save() } label: {
                    Text(kind == "in" ? "保存这一笔".tr : "记一笔".tr)
                        .font(.system(.title3, design: .rounded).weight(.bold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .duo(canSave ? Color.bbGreen : Color.bbLine, canSave ? duoGreenEdge : duoEdge)
                }
                .disabled(!canSave)
                .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 14)
            }
            .background(Color.bbBg)
            .navigationTitle("记一笔".tr)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消".tr) { dismiss() }.font(.system(.body, design: .rounded))
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成".tr) { bbHideKeyboard() }.font(.system(.body, design: .rounded).weight(.semibold))
                }
            }
            .sheet(isPresented: $showReflect) { ReflectSheet(onDone: handleReflect) }
        }
    }

    private func toggle(_ label: String, _ k: String) -> some View {
        let on = kind == k
        return Button { kind = k } label: {
            Text(label).font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundColor(on ? .white : .bbInk2)
                .frame(maxWidth: .infinity).padding(.vertical, 13)
                .duo(on ? Color.bbGreen : Color.bbSurface, on ? duoGreenEdge : duoEdge, radius: 14)
        }
        .buttonStyle(.plain)
    }

    private func catChip(_ c: String) -> some View {
        let on = cat == c
        return Button { cat = c } label: {
            VStack(spacing: 6) {
                Image(systemName: CATS[c]?.icon ?? "circle.fill").font(.system(size: 22))
                Text(CATS[c]?.zh.tr ?? c).font(.system(.subheadline, design: .rounded).weight(.semibold))
            }
            .foregroundColor(on ? .white : .bbInk)
            .frame(width: 76, height: 72)
            .duo(on ? Color.bbGreen : Color.bbSurface, on ? duoGreenEdge : duoEdge, radius: 16)
        }
        .buttonStyle(.plain)
    }

    private var keypad: some View {
        let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "0", "⌫"]
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(keys, id: \.self) { k in
                Button { tapKey(k) } label: {
                    Group {
                        if k == "⌫" { Image(systemName: "delete.left").font(.system(size: 22, weight: .bold)) }
                        else { Text(k).font(.system(size: 27, weight: .bold, design: .rounded)) }
                    }
                    .foregroundColor(.bbInk)
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .duo(Color.bbSurface, duoEdge, radius: 16)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }

    private func tapKey(_ k: String) {
        switch k {
        case "⌫": if !amount.isEmpty { amount.removeLast() }
        case ".": if !amount.contains(".") && !amount.isEmpty { amount += "." }
        default:
            if let dot = amount.firstIndex(of: "."), amount.distance(from: dot, to: amount.endIndex) > 2 { return }
            if amount.count >= 7 { return }
            amount = (amount == "0") ? k : amount + k
        }
    }

    private func save() {
        let amt = Double(amount) ?? 0
        guard amt > 0 else { return }
        let c = kind == "in" ? "income" : cat
        Task {
            let id = await store.addTransaction(amount: amt, cat: c, note: note, kind: kind)
            if kind == "out" { pendingId = id; showReflect = true } else { dismiss() }
        }
    }

    private func handleReflect(_ r: Reflect?) {
        if let r = r { store.setReflect(pendingId, r) }
        dismiss()
    }
}

// MARK: - Optional "记一次选择".tr prompt (after saving an expense)

struct ReflectSheet: View {
    let onDone: (Reflect?) -> Void
    @State private var need: String?
    @State private var plan: String?
    @State private var influence: String?
    @State private var feeling: String?
    private var anyPicked: Bool { need != nil || plan != nil || influence != nil || feeling != nil }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        Text("花完之后，停三秒回顾一下——想记就记，跳过也没关系。".tr)
                            .font(.system(.body, design: .rounded)).foregroundColor(.bbInk2)
                        reflectRow("这是需要，还是想要？".tr, REFLECT_NEED, $need)
                        reflectRow("提前想好的，还是临时决定？".tr, REFLECT_PLAN, $plan)
                        reflectRow("是什么影响了你？".tr, REFLECT_INFLUENCE, $influence)
                        reflectRow("花完之后感觉怎么样？".tr, REFLECT_FEELING, $feeling)
                    }
                    .padding(18)
                }
                VStack(spacing: 10) {
                    Button { onDone(Reflect(need: need, plan: plan, influence: influence, feeling: feeling)) } label: {
                        Text("记录这次选择".tr).font(.system(.title3, design: .rounded).weight(.bold)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .duo(anyPicked ? Color.bbGreen : Color.bbLine, anyPicked ? duoGreenEdge : duoEdge)
                    }
                    .disabled(!anyPicked)
                    Button { onDone(nil) } label: {
                        Text("跳过".tr).font(.system(.subheadline, design: .rounded).weight(.semibold)).foregroundColor(.bbInk2)
                    }
                }
                .padding(.horizontal, 18).padding(.top, 8).padding(.bottom, 14)
            }
            .background(Color.bbBg)
            .navigationTitle("记一次选择".tr)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
    }

    private func reflectRow(_ label: String, _ options: [String], _ sel: Binding<String?>) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(label).font(.system(.headline, design: .rounded).weight(.bold)).foregroundColor(.bbInk)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 78), spacing: 10)], alignment: .leading, spacing: 10) {
                ForEach(options, id: \.self) { opt in
                    let on = sel.wrappedValue == opt
                    Button { sel.wrappedValue = on ? nil : opt } label: {
                        Text(opt.tr).font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .frame(maxWidth: .infinity).padding(.vertical, 11)
                            .foregroundColor(on ? .white : .bbInk)
                            .duo(on ? Color.bbGreen : Color.bbSurface, on ? duoGreenEdge : duoEdge, radius: 14)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - 记账总结 (balance analysis + auto AI advice)

struct TrackerSummaryView: View {
    @EnvironmentObject var store: AppStore

    // 周/月 double-cycle summary (v1.3): each scope keeps its own auto-loaded
    // AI advice; switching scopes re-analyzes that window automatically.
    enum Scope: String, CaseIterable { case week = "本周", month = "本月" }
    @State private var scope: Scope = .month
    @State private var advice: [Scope: String] = [:]
    @State private var loadingAdvice = true

    private func inScope(_ ts: String) -> Bool {
        scope == .week ? isThisWeek(ts) : isSameMonth(ts, Date())
    }
    private var scoped: [Transaction] { store.state.transactions.filter { inScope($0.ts) } }
    private var scopeOut: Double { scoped.filter { $0.kind == "out" }.reduce(0) { $0 + $1.amount } }
    private var scopeIn: Double { scoped.filter { $0.kind == "in" }.reduce(0) { $0 + $1.amount } }
    private var scopeNet: Double { scopeIn - scopeOut }
    private var scopeDays: Int { Set(scoped.map { bbDayKey($0.ts) }).count }

    private var catTotals: [(cat: String, amount: Double)] {
        var m: [String: Double] = [:]
        for t in scoped where t.kind == "out" { m[t.cat, default: 0] += t.amount }
        return m.sorted { $0.value > $1.value }.map { (cat: $0.key, amount: $0.value) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Picker("", selection: $scope) {
                    ForEach(Scope.allCases, id: \.self) { Text($0.rawValue.tr) }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("summary.scope")

                VStack(spacing: 6) {
                    Text((scope == .week ? "本周结余" : "本月结余").tr)
                        .font(.system(.subheadline, design: .rounded)).foregroundColor(.bbInk2)
                    Text("\(scopeNet >= 0 ? "" : "−")¥\(abs(Int(scopeNet)))")
                        .font(.system(size: 46, weight: .heavy, design: .rounded))
                        .foregroundColor(scopeNet >= 0 ? .bbGreen : .bbRed)
                    HStack(spacing: 26) {
                        stat((scope == .week ? "本周支出" : "本月支出").tr, scopeOut, .bbInk)
                        Rectangle().fill(Color.bbLine).frame(width: 1, height: 30)
                        stat((scope == .week ? "本周收入" : "本月收入").tr, scopeIn, .bbGreen)
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity).padding(20)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color.bbSurface))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.bbLine))

                if !catTotals.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("钱花在哪儿".tr).font(.system(.headline, design: .rounded).weight(.bold)).foregroundColor(.bbInk)
                        ForEach(catTotals.prefix(5), id: \.cat) { item in
                            catBar(item.cat, item.amount, top: catTotals.first?.amount ?? 1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(18)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color.bbSurface))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.bbLine))
                }

                HStack(spacing: 10) {
                    miniStat("\(scoped.count)", (scope == .week ? "本周笔数" : "本月笔数").tr)
                    miniStat("\(scopeDays)", "记账天数".tr)
                    miniStat("¥\(Int(store.totalNet))", "累计结余".tr)
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("搭子帮你看看".tr).font(.system(.headline, design: .rounded).weight(.bold))
                    }
                    .foregroundColor(.bbGreen)
                    if loadingAdvice {
                        HStack(spacing: 8) {
                            ProgressView().tint(.bbGreen)
                            Text("正在分析你的花销…".tr).font(.system(.subheadline, design: .rounded)).foregroundColor(.bbInk2)
                        }
                        .padding(.vertical, 4)
                    } else {
                        Text(markdownText(advice[scope] ?? "")).font(.system(.body, design: .rounded)).foregroundColor(.bbInk)
                            .fixedSize(horizontal: false, vertical: true).lineSpacing(4)
                    }
                    Button { loadAdvice(force: true) } label: {
                        Label("再分析一次".tr, systemImage: "arrow.clockwise")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold)).foregroundColor(.bbGreen)
                    }
                    .disabled(loadingAdvice).padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading).padding(18)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color(hex: 0xE9F1EA)))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.bbGreen.opacity(0.25)))
            }
            .padding(16)
            .bbPageWidth()
        }
        .background(Color.bbBg)
        .navigationTitle("记账总结".tr)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadAdvice() }
        .onChange(of: scope) { _ in loadAdvice() }
    }

    private func stat(_ label: String, _ v: Double, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text("¥\(Int(v))").font(.system(.title3, design: .rounded).weight(.bold)).foregroundColor(color)
            Text(label).font(.system(.caption, design: .rounded)).foregroundColor(.bbInk2)
        }
    }

    private func miniStat(_ v: String, _ label: String) -> some View {
        VStack(spacing: 5) {
            Text(v).font(.system(.title3, design: .rounded).weight(.bold)).foregroundColor(.bbInk)
            Text(label).font(.system(.caption2, design: .rounded)).foregroundColor(.bbInk2)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.bbSurface))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.bbLine))
    }

    private func catBar(_ cat: String, _ amount: Double, top: Double) -> some View {
        let frac = top > 0 ? CGFloat(amount / top) : 0
        return HStack(spacing: 10) {
            Image(systemName: CATS[cat]?.icon ?? "circle.fill").foregroundColor(.bbGreen).frame(width: 22)
            Text(CATS[cat]?.zh.tr ?? cat).font(.system(.subheadline, design: .rounded)).foregroundColor(.bbInk)
                .frame(width: 64, alignment: .leading)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.bbLine.opacity(0.5)).frame(height: 10)
                    Capsule().fill(Color.bbGreen).frame(width: max(8, g.size.width * frac), height: 10)
                }
            }
            .frame(height: 10)
            Text("¥\(Int(amount))").font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundColor(.bbInk).frame(width: 56, alignment: .trailing)
        }
    }

    // Advice is cached per scope; opening the page or flipping 周/月 analyzes
    // that window automatically, 再分析一次 forces a refresh.
    private func loadAdvice(force: Bool = false) {
        let target = scope
        if !force, let cached = advice[target], !cached.isEmpty { loadingAdvice = false; return }
        loadingAdvice = true
        Task {
            let window = target == .week ? "本周" : "本月"
            let prompt = BBLang.isEN
                ? "Please review my spending records for THIS \(target == .week ? "WEEK" : "MONTH") and reply IN ENGLISH with 2-3 friendly, specific, doable money-saving tips based on where the money went in that window. Encouraging tone, no lecturing."
                : "请根据我的记账数据，重点分析我【\(window)】的花销结构和变化，用轻松鼓励的语气给我 2-3 条具体、可执行的省钱小建议，不要说教。"
            do {
                let reply = try await APIClient.shared.aiChat(prompt)
                advice[target] = reply
            } catch {
                advice[target] = "哎呀，刚才没连上 AI 😅 点下方「再分析一次」我再帮你看看。".tr
            }
            if target == scope { loadingAdvice = false }
        }
    }
}
