import SwiftUI

struct MainTabView: View {
    @State private var tab = 0
    var body: some View {
        TabView(selection: $tab) {
            HomeView(tab: $tab).tabItem { Label("首页", systemImage: "house.fill") }.tag(0)
            TrackerView().tabItem { Label("记账", systemImage: "list.bullet.rectangle.fill") }.tag(1)
            StoryView().tabItem { Label("故事", systemImage: "book.fill") }.tag(2)
            AIView().tabItem { Label("AI搭子", systemImage: "bubble.left.fill") }.tag(3)
            ProfileView(tab: $tab).tabItem { Label("我的", systemImage: "person.fill") }.tag(4)
        }
        .tint(.bbGreen)
    }
}

// MARK: - 首页

struct HomeView: View {
    @EnvironmentObject var store: AppStore
    @Binding var tab: Int
    @State private var showAdd = false

    private var choicesThisWeek: Int {
        store.state.transactions.filter { isThisWeek($0.ts) }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // 1 — wordmark
                    VStack(spacing: 9) {
                        Text("省钱搭子").font(.system(size: 23, weight: .semibold)).tracking(5).foregroundColor(.bbInk)
                        Text("BUDGETBUDDY").font(.system(size: 10)).tracking(6).foregroundColor(.bbInk2)
                    }
                    .padding(.top, 22).padding(.bottom, 20)

                    // 2 — 今日故事
                    sectionHeader("今 日 故 事", trailing: "全部故事") { tab = 2 }
                    storyHero.padding(.top, 14)

                    // 3 — 记录一次选择
                    Button { showAdd = true } label: {
                        HStack(spacing: 14) {
                            RoundedRectangle(cornerRadius: 8).stroke(Color.bbLine).frame(width: 38, height: 38)
                                .overlay(Image(systemName: "plus").foregroundColor(.bbInk))
                            VStack(alignment: .leading, spacing: 3) {
                                Text("记录一次选择").font(.headline).foregroundColor(.bbInk)
                                Text("每一笔消费，都是一次决定").font(.caption).foregroundColor(.bbInk2)
                            }
                            Spacer()
                            Image(systemName: "arrow.right").foregroundColor(.bbInk2)
                        }
                        .padding(16)
                        .background(Color.bbSurface)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.bbLine))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain).padding(.top, 14)

                    // 4 — 本周概览
                    sectionHeader("本 周 概 览", trailing: nil) {}.padding(.top, 26)
                    weekGrid.padding(.top, 2)

                    // 5 — 搭子说
                    sectionHeader("搭 子 说", trailing: nil) {}.padding(.top, 26)
                    Button { tab = 3 } label: {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("做选择前，先停三秒").font(.headline).foregroundColor(.bbInk)
                            Text("想要还是需要？这一笔花完，未来的你会感谢现在的决定吗？")
                                .font(.body).foregroundColor(.bbInk2).fixedSize(horizontal: false, vertical: true)
                            HStack(spacing: 5) {
                                Text("找搭子复盘一下"); Image(systemName: "arrow.right")
                            }
                            .font(.caption).foregroundColor(.bbInk).padding(.top, 6)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .background(Color.bbSurface)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.bbLine))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain).padding(.top, 2)

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
            }
            .background(Color.bbBg)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showAdd) { AddSheet().environmentObject(store) }
        }
    }

    private func sectionHeader(_ title: String, trailing: String?, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title).font(.caption).tracking(2).foregroundColor(.bbInk2)
            Spacer()
            if let trailing = trailing {
                Button(action: action) {
                    HStack(spacing: 2) { Text(trailing); Image(systemName: "chevron.right").font(.caption2) }
                        .font(.caption).foregroundColor(.bbInk2)
                }
            }
        }
        .padding(.bottom, 10)
        .overlay(Rectangle().fill(Color.bbLine).frame(height: 1), alignment: .bottom)
    }

    // Hero card (cream "scene" header + featured story). Story content is ported
    // later; this shows the first scenario, matching the web layout.
    private var storyHero: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Color(hex: 0xFFF4DF)
                Image("scene_month_life_s1").resizable().aspectRatio(contentMode: .fill)
            }
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay(alignment: .topLeading) {
                HStack(spacing: 4) { Image(systemName: "mappin"); Text("今天") }
                    .font(.caption2).foregroundColor(Color(hex: 0x8A5A2B)).padding(12)
            }
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text("消费观念").font(.caption2)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(Color(hex: 0xFFF4DF))).foregroundColor(Color(hex: 0x8A5A2B))
                    HStack(spacing: 4) { Image(systemName: "clock"); Text("3分钟") }.font(.caption2).foregroundColor(.bbInk2)
                }
                Text("一个月生活费大作战").font(.system(size: 20, weight: .semibold)).foregroundColor(.bbInk)
                Text("这个月有 ¥1000，看看你能不能稳稳花到月底。")
                    .font(.body).foregroundColor(.bbInk2).fixedSize(horizontal: false, vertical: true)
                Button { tab = 2 } label: {
                    Text("进入故事").font(.system(.headline, design: .rounded).weight(.bold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .duoPrimary()
                }
                .padding(.top, 8)
            }
            .padding(18)
        }
        .background(Color.bbSurface)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.bbLine))
        .cornerRadius(8)
    }

    private var weekGrid: some View {
        let stats: [(String, Int)] = [
            ("完成故事", store.storiesCompleted),
            ("记录选择", choicesThisWeek),
            ("解锁图鉴", store.codexUnlocked),
            ("学完课程", store.lessonsCompleted)
        ]
        return HStack(spacing: 0) {
            ForEach(Array(stats.enumerated()), id: \.offset) { i, s in
                VStack(spacing: 8) {
                    Text("\(s.1)").font(.system(size: 24, weight: .semibold)).foregroundColor(.bbInk)
                    Text(s.0).font(.caption).foregroundColor(.bbInk2)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 18)
                .overlay(alignment: .trailing) { if i < 3 { Rectangle().fill(Color.bbLine).frame(width: 1) } }
            }
        }
        .overlay(Rectangle().fill(Color.bbLine).frame(height: 1), alignment: .bottom)
    }
}

// MARK: - AI搭子

struct AIView: View {
    struct Message: Identifiable { let id = UUID(); let me: Bool; let text: String }
    @State private var messages: [Message] = [Message(me: false, text: "我是你的决策复盘搭子，想聊聊哪一笔消费？")]
    @State private var input = ""
    @State private var busy = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(messages) { m in
                            Text(markdownText(m.text))
                                .padding(10)
                                .background(m.me ? Color.bbGreen.opacity(0.16) : Color.bbBlue)
                                .foregroundColor(.bbInk)
                                .cornerRadius(12)
                                .frame(maxWidth: .infinity, alignment: m.me ? .trailing : .leading)
                        }
                    }
                    .padding()
                }
                HStack(spacing: 8) {
                    TextField("说说你的一次选择…", text: $input).textFieldStyle(.roundedBorder)
                    Button(action: send) {
                        Image(systemName: "arrow.up.circle.fill").font(.title2).foregroundColor(.bbGreen)
                    }
                    .disabled(busy || input.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
            }
            .background(Color.bbBg)
            .navigationTitle("AI搭子")
        }
    }

    private func send() {
        let q = input.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }
        input = ""; busy = true
        messages.append(Message(me: true, text: q))
        Task {
            do {
                let reply = try await APIClient.shared.aiChat(q)
                messages.append(Message(me: false, text: reply))
            } catch {
                messages.append(Message(me: false, text: "哎呀，我这会儿没连上网 😅 把刚才的问题再发一次试试？"))
            }
            busy = false
        }
    }
}

// MARK: - 我的

struct ProfileView: View {
    @EnvironmentObject var store: AppStore
    @Binding var tab: Int
    @State private var showEditNick = false
    @State private var showSyncInfo = false
    @State private var showResetConfirm = false
    @State private var showDeleteSheet = false

    private var identitySub: String {
        let ag = store.user?.ageGroup ?? ""
        return "\(ag.isEmpty ? "学生" : ag) · 已记账 \(store.recordDays) 天"
    }
    private var exportJSON: String {
        guard let data = try? JSONEncoder().encode(store.state),
              let s = String(data: data, encoding: .utf8) else { return "{}" }
        return s
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // identity (tap to edit nickname)
                    Button { showEditNick = true } label: {
                        HStack(spacing: 14) {
                            RoundedRectangle(cornerRadius: 10).stroke(Color.bbLine).frame(width: 52, height: 52)
                                .overlay(Image(systemName: "person").font(.title2).foregroundColor(.bbInk))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(store.displayName).font(.title3.bold()).foregroundColor(.bbInk)
                                Text(identitySub).font(.caption).foregroundColor(.bbInk2)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "pencil").font(.caption).foregroundColor(.bbInk2)
                        }
                        .padding(.vertical, 14).contentShape(Rectangle())
                        .overlay(Rectangle().fill(Color.bbLine).frame(height: 1), alignment: .bottom)
                    }
                    .buttonStyle(.plain)

                    // summary cards (real, persisted counts)
                    HStack(spacing: 10) {
                        summaryCard("完成故事", store.storiesCompleted, Color(hex: 0xE4EFE7), Color(hex: 0x35583F))
                        summaryCard("解锁图鉴", store.codexUnlocked, Color.bbBlue, Color(hex: 0x3A5A78))
                        summaryCard("记账天数", store.recordDays, Color(hex: 0xFFF4DF), Color(hex: 0x8A5A2B))
                    }
                    .padding(.top, 16)

                    profileSection("故 事 与 学 习") {
                        Button { tab = 2 } label: { rowLabel("book", "已通关故事", right: "\(store.storiesCompleted) / \(StoryStore.all.count)") }.buttonStyle(.plain)
                        NavigationLink { CodexView() } label: { rowLabel("rectangle.stack", "已解锁图鉴", right: "\(store.codexUnlocked) / \(CodexStore.all.count)") }.buttonStyle(.plain)
                        Button { tab = 2 } label: { rowLabel("play.circle", "理财课程", right: "已完成 \(store.lessonsCompleted)/\(LessonStore.all.count)") }.buttonStyle(.plain)
                        NavigationLink { ChallengesView() } label: { rowLabel("flag", "我的挑战", right: store.activeChallengeCount > 0 ? "\(store.activeChallengeCount) 个进行中" : "去看看") }.buttonStyle(.plain)
                    }

                    profileSection("我 的 记 录") {
                        Button { tab = 1 } label: { rowLabel("square.and.pencil", "消费选择记录", right: "\(store.outCount) 次") }.buttonStyle(.plain)
                    }

                    profileSection("账 户") {
                        Button { showSyncInfo = true } label: { rowLabel("cloud", "云端同步", right: "已开启") }.buttonStyle(.plain)
                        Button { showEditNick = true } label: { rowLabel("pencil", "编辑昵称") }.buttonStyle(.plain)
                        ShareLink(item: exportJSON) { rowLabel("square.and.arrow.up", "导出数据") }
                        NavigationLink { FeedbackView() } label: { rowLabel("ladybug", "问题反馈") }.buttonStyle(.plain)
                        Button { showResetConfirm = true } label: { rowLabel("arrow.counterclockwise", "恢复默认数据") }.buttonStyle(.plain)
                        Button { Task { await store.logout() } } label: { rowLabel("rectangle.portrait.and.arrow.right", "退出登录", tint: .bbRed) }.buttonStyle(.plain)
                        Button { showDeleteSheet = true } label: { rowLabel("trash", "删除账号", tint: .bbRed) }.buttonStyle(.plain)
                    }

                    HStack(spacing: 6) {
                        NavigationLink { Legal.terms } label: { Text("用户协议") }.foregroundColor(.bbInk)
                        Text("·").foregroundColor(.bbInk2)
                        NavigationLink { Legal.privacy } label: { Text("隐私政策") }.foregroundColor(.bbInk)
                    }
                    .font(.caption).padding(.top, 24)

                    VStack(spacing: 3) {
                        Text("省钱搭子 BudgetBuddy").font(.caption.weight(.semibold)).foregroundColor(.bbInk2)
                        Text("陪你把每一次选择，变成更好的决定").font(.caption2).foregroundColor(.bbInk2)
                    }
                    .padding(.top, 12)
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
            }
            .background(Color.bbBg)
            .navigationTitle("我的")
            .sheet(isPresented: $showEditNick) {
                EditNicknameSheet(current: store.displayName) { store.updateNickname($0) }
            }
            .sheet(isPresented: $showDeleteSheet) {
                DeleteAccountSheet()
                    .environmentObject(store)
            }
            .alert("云端同步", isPresented: $showSyncInfo) {
                Button("好的", role: .cancel) {}
            } message: { Text("你的数据已安全保存到你的账号，换个设备登录也能看到自己的记录。") }
            .alert("恢复默认数据？", isPresented: $showResetConfirm) {
                Button("取消", role: .cancel) {}
                Button("恢复", role: .destructive) { store.resetData() }
            } message: { Text("你记的账和故事进度会被清空。") }
        }
    }

    private func summaryCard(_ label: String, _ value: Int, _ bg: Color, _ ink: Color) -> some View {
        VStack(spacing: 7) {
            Text("\(value)").font(.system(size: 24, weight: .semibold)).foregroundColor(ink)
            Text(label).font(.caption).foregroundColor(ink.opacity(0.85))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .background(bg).cornerRadius(12)
    }

    @ViewBuilder
    private func profileSection<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        Text(title).font(.caption).tracking(2).foregroundColor(.bbInk2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 24).padding(.bottom, 2).padding(.horizontal, 2)
        VStack(spacing: 0) { content() }
    }

    private func rowLabel(_ icon: String, _ title: String, right: String? = nil, tint: Color = .bbInk) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon).font(.system(size: 18)).foregroundColor(tint == .bbRed ? .bbRed : .bbInk2).frame(width: 24)
            Text(title).foregroundColor(tint)
            Spacer(minLength: 0)
            if let right { Text(right).font(.caption).foregroundColor(.bbInk2) }
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.bbInk2.opacity(0.6))
        }
        .padding(.vertical, 15).padding(.horizontal, 2).contentShape(Rectangle())
        .overlay(Rectangle().fill(Color.bbLine).frame(height: 1), alignment: .bottom)
    }
}

struct EditNicknameSheet: View {
    let current: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("昵称", text: $name)
            }
            .navigationTitle("编辑昵称")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { onSave(name); dismiss() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { name = current }
        }
        .presentationDetents([.height(190)])
    }
}

struct DeleteAccountSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var password = ""
    @State private var busy = false
    @State private var err = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("这将永久删除你的账号和所有数据（记账、故事进度、挑战），且无法恢复。")
                        .foregroundColor(.bbInk2)
                    SecureField("当前密码", text: $password)
                        .textContentType(.password)
                        .accessibilityIdentifier("delete.account.password")
                }
                if !err.isEmpty {
                    Section {
                        Label(err, systemImage: "exclamationmark.circle")
                            .font(.footnote)
                            .foregroundColor(.bbRed)
                    }
                }
            }
            .navigationTitle("永久删除账号")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .disabled(busy)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(busy ? "删除中" : "删除", role: .destructive) {
                        Task { await submit() }
                    }
                    .disabled(busy || password.isEmpty)
                    .accessibilityIdentifier("delete.account.confirm")
                }
            }
        }
        .presentationDetents([.height(310)])
    }

    @MainActor
    private func submit() async {
        guard !busy, !password.isEmpty else { return }
        busy = true
        err = ""
        let ok = await store.deleteAccount(password: password)
        if ok {
            dismiss()
        } else {
            err = store.errorMessage ?? "删除失败，请重试"
            busy = false
        }
    }
}
