import SwiftUI

struct MainTabView: View {
    @State private var tab = 0
    @ObservedObject private var inbox = FeedbackInbox.shared
    var body: some View {
        TabView(selection: $tab) {
            HomeView(tab: $tab).tabItem { Label("首页".tr, systemImage: "house.fill") }.tag(0)
            TrackerView().tabItem { Label("记账".tr, systemImage: "list.bullet.rectangle.fill") }.tag(1)
            StoryView().tabItem { Label("故事".tr, systemImage: "book.fill") }.tag(2)
            AIView().tabItem { Label("AI搭子".tr, systemImage: "bubble.left.fill") }.tag(3)
            ProfileView(tab: $tab).tabItem { Label("我的".tr, systemImage: "person.fill") }.tag(4)
                .badge(inbox.unread)
        }
        .tint(.bbGreen)
    }
}

// MARK: - 首页

struct HomeView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.horizontalSizeClass) private var hSize
    @Binding var tab: Int
    @State private var showAdd = false
    @State private var showAuthForAdd = false
    @State private var blitz: BlitzLaunch?          // v1.6 财商快答
    @State private var showBlitzHub = false
    @State private var blitzRefresh = 0
    @State private var replyThreadID: Int?          // v1.6.2 反馈回复

    private var choicesThisWeek: Int {
        store.state.transactions.filter { isThisWeek($0.ts) }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if hSize == .regular { padLayout } else { phoneLayout }
            }
            .background(Color.bbBg)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showAdd) { AddSheet().environmentObject(store) }
            .sheet(isPresented: $showAuthForAdd) { AuthView().environmentObject(store) }
            .fullScreenCover(item: $blitz, onDismiss: { blitzRefresh += 1 }) { BlitzGameContainer(mode: $0.mode) }
            .navigationDestination(isPresented: $showBlitzHub) { BlitzHubView() }
            .navigationDestination(isPresented: Binding(get: { replyThreadID != nil },
                                                        set: { if !$0 { replyThreadID = nil } })) {
                if let id = replyThreadID { FeedbackThreadView(threadID: id) }
            }
        }
    }

    private var replyBanner: some View {
        FeedbackReplyBanner(bottomPadding: 14) { replyThreadID = $0.id }
    }

    private var blitzSection: some View {
        VStack(spacing: 0) {
            sectionHeader("今 日 快 答".tr, trailing: "全部题包".tr) { showBlitzHub = true }
            BlitzDailyCard { blitz = BlitzLaunch(mode: .daily) }.id(blitzRefresh).padding(.top, 14)
        }
    }

    // iPhone — unchanged single column.
    private var phoneLayout: some View {
        VStack(spacing: 0) {
            wordmark.padding(.top, 22).padding(.bottom, 20)
            replyBanner
            sectionHeader("今 日 故 事".tr, trailing: "全部故事".tr) { tab = 2 }
            storyHero(imageHeight: 160).padding(.top, 14)
            quickAddCard.padding(.top, 14)
            blitzSection.padding(.top, 26)
            sectionHeader("本 周 概 览".tr, trailing: nil) {}.padding(.top, 26)
            weekGrid.padding(.top, 2)
            sectionHeader("搭 子 说".tr, trailing: nil) {}.padding(.top, 26)
            buddyTipCard.padding(.top, 2)
            Spacer(minLength: 24)
        }
        .padding(.horizontal, 16)
        .bbPageWidth()
    }

    // iPad — two balanced columns fill the canvas: the hero story carries the
    // left; quick-add, week stats and the buddy tip stack on the right.
    private var padLayout: some View {
        VStack(spacing: 0) {
            wordmark.padding(.top, 30).padding(.bottom, 26)
            replyBanner.frame(maxWidth: 640)
            HStack(alignment: .top, spacing: 28) {
                VStack(spacing: 0) {
                    sectionHeader("今 日 故 事".tr, trailing: "全部故事".tr) { tab = 2 }
                    storyHero(imageHeight: 280).padding(.top, 14)
                }
                VStack(spacing: 0) {
                    sectionHeader("记 一 笔".tr, trailing: nil) {}
                    quickAddCard.padding(.top, 14)
                    blitzSection.padding(.top, 28)
                    sectionHeader("本 周 概 览".tr, trailing: nil) {}.padding(.top, 28)
                    weekGrid.padding(.top, 2)
                    sectionHeader("搭 子 说".tr, trailing: nil) {}.padding(.top, 28)
                    buddyTipCard.padding(.top, 14)
                }
            }
            Spacer(minLength: 32)
        }
        .padding(.horizontal, 32)
        .bbPageWidth(1080)
    }

    private var wordmark: some View {
        VStack(spacing: 9) {
            Text("省钱搭子").font(.system(size: 23, weight: .semibold)).tracking(5).foregroundColor(.bbInk)
            Text("BUDGETBUDDY").font(.system(size: 10)).tracking(6).foregroundColor(.bbInk2)
        }
    }

    // 记账 = 账号功能，游客先登录
    private var quickAddCard: some View {
        Button { if store.isGuest { showAuthForAdd = true } else { showAdd = true } } label: {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 8).stroke(Color.bbLine).frame(width: 38, height: 38)
                    .overlay(Image(systemName: "plus").foregroundColor(.bbInk))
                VStack(alignment: .leading, spacing: 3) {
                    Text("记录一次选择".tr).font(.headline).foregroundColor(.bbInk)
                    Text("每一笔消费，都是一次决定".tr).font(.caption).foregroundColor(.bbInk2)
                }
                Spacer()
                Image(systemName: "arrow.right").foregroundColor(.bbInk2)
            }
            .padding(16)
            .background(Color.bbSurface)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.bbLine))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private var buddyTipCard: some View {
        Button { tab = 3 } label: {
            VStack(alignment: .leading, spacing: 7) {
                Text("做选择前，先停三秒".tr).font(.headline).foregroundColor(.bbInk)
                Text("想要还是需要？这一笔花完，未来的你会感谢现在的决定吗？".tr)
                    .font(.body).foregroundColor(.bbInk2).fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 5) {
                    Text("找搭子复盘一下".tr); Image(systemName: "arrow.right")
                }
                .font(.caption).foregroundColor(.bbInk).padding(.top, 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Color.bbSurface)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.bbLine))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
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

    // Hero card (cream "scene" header + featured story). Taller artwork on iPad.
    private func storyHero(imageHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Color(hex: 0xFFF4DF)
                Image("scene_month_life_s1").resizable().aspectRatio(contentMode: .fill)
            }
            .frame(height: imageHeight)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay(alignment: .topLeading) {
                HStack(spacing: 4) { Image(systemName: "mappin"); Text("今天".tr) }
                    .font(.caption2).foregroundColor(Color(hex: 0x8A5A2B)).padding(12)
            }
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text("消费观念".tr).font(.caption2)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(Color(hex: 0xFFF4DF))).foregroundColor(Color(hex: 0x8A5A2B))
                    HStack(spacing: 4) { Image(systemName: "clock"); Text("3分钟".tr) }.font(.caption2).foregroundColor(.bbInk2)
                }
                Text("一个月生活费大作战".tr).font(.title3.weight(.semibold)).foregroundColor(.bbInk)
                Text("这个月有 ¥1000，看看你能不能稳稳花到月底。".tr)
                    .font(.body).foregroundColor(.bbInk2).fixedSize(horizontal: false, vertical: true)
                Button { tab = 2 } label: {
                    Text("进入故事".tr).font(.system(.headline, design: .rounded).weight(.bold)).foregroundColor(.white)
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
            ("完成故事".tr, store.storiesCompleted),
            ("记录选择".tr, choicesThisWeek),
            ("解锁图鉴".tr, store.codexUnlocked),
            ("学完课程".tr, store.lessonsCompleted)
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
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var messages: [Message] = [Message(me: false, text: "我是你的决策复盘搭子，想聊聊哪一笔消费？".tr)]
    @State private var input = ""
    @State private var busy = false

    private let starterPrompts = ["这周奶茶花多了怎么办？", "帮我复盘昨天一笔冲动消费", "给我一个这周能做到的省钱小目标"]

    private var promptChips: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("可以这样开场".tr).font(.caption).tracking(2).foregroundColor(.bbInk2)
            ForEach(starterPrompts, id: \.self) { p in
                Button {
                    input = p.tr
                    send()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bubble.left").font(.caption).foregroundColor(.bbGreen)
                        Text(p.tr).font(.subheadline).foregroundColor(.bbInk)
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.up.right").font(.caption2).foregroundColor(.bbInk2)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(Color.bbSurface)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.bbLine))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(messages) { m in
                                Text(markdownText(m.text))
                                    .padding(10)
                                    .background(m.me ? Color.bbGreen.opacity(0.16) : Color.bbBlue)
                                    .foregroundColor(.bbInk)
                                    .cornerRadius(12)
                                    .frame(maxWidth: .infinity, alignment: m.me ? .trailing : .leading)
                                    .id(m.id)
                            }
                            if busy {
                                HStack(spacing: 8) {
                                    ProgressView().tint(.bbGreen)
                                    Text("搭子正在想…".tr).font(.subheadline).foregroundColor(.bbInk2)
                                }
                                .padding(10).background(Color.bbBlue).cornerRadius(12)
                                .id("thinking")
                            }
                            // iPad: the fresh-chat screen is a big empty canvas —
                            // fill it with tappable conversation starters.
                            if hSize == .regular && messages.count <= 1 && !busy {
                                promptChips.padding(.top, 16)
                            }
                        }
                        .padding()
                        .bbPageWidth(hSize == .regular ? 760 : 640)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onTapGesture { bbHideKeyboard() }
                    .onChange(of: messages.count) { _ in
                        withAnimation { proxy.scrollTo(messages.last?.id, anchor: .bottom) }
                    }
                    .onChange(of: busy) { b in
                        if b { withAnimation { proxy.scrollTo("thinking", anchor: .bottom) } }
                    }
                }
                HStack(spacing: 8) {
                    TextField("说说你的一次选择…".tr, text: $input).textFieldStyle(.roundedBorder)
                    Button(action: send) {
                        Image(systemName: "arrow.up.circle.fill").font(.title2).foregroundColor(.bbGreen)
                    }
                    .disabled(busy || input.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
                .bbPageWidth(hSize == .regular ? 760 : 640)
            }
            .background(Color.bbBg)
            .navigationTitle("AI搭子".tr)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成".tr) { bbHideKeyboard() }.font(.system(.body, design: .rounded).weight(.semibold))
                }
            }
        }
    }

    private func send() {
        let q = input.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }
        input = ""; busy = true
        bbHideKeyboard()
        messages.append(Message(me: true, text: q))
        Task {
            do {
                let apiQuestion = BBLang.isEN
                    ? """
                    You are BudgetBuddy's AI Buddy inside an English UI.
                    Reply in English only, in 1-3 short friendly sentences.
                    Do not use Chinese unless the user explicitly asks for Chinese.

                    User message: \(q)
                    """
                    : q
                let reply = try await APIClient.shared.aiChat(apiQuestion)
                messages.append(Message(me: false, text: reply))
            } catch {
                messages.append(Message(me: false, text: "哎呀，我这会儿没连上网 😅 把刚才的问题再发一次试试？".tr))
            }
            busy = false
        }
    }
}

// MARK: - 我的

struct ProfileView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.horizontalSizeClass) private var hSize
    @Binding var tab: Int
    @State private var showEditNick = false
    @State private var showSyncInfo = false
    @State private var showResetConfirm = false
    @State private var showDeleteSheet = false
    @State private var showAuth = false
    @ObservedObject private var inbox = FeedbackInbox.shared

    // iPhone — unchanged single column.
    private var phoneLayout: some View {
        VStack(spacing: 0) {
            identityRow
            summaryCards.padding(.top, 16)
            storiesSection
            recordsSection
            accountSection
            footer
            Spacer(minLength: 24)
        }
        .padding(.horizontal, 16)
        .bbPageWidth()
    }

    // iPad — identity + stat cards span the top; progress lives left,
    // account settings right, so the width actually gets used.
    private var padLayout: some View {
        VStack(spacing: 0) {
            identityRow
            summaryCards.padding(.top, 18)
            HStack(alignment: .top, spacing: 28) {
                VStack(spacing: 0) {
                    storiesSection
                    recordsSection
                }
                VStack(spacing: 0) {
                    accountSection
                }
            }
            footer
            Spacer(minLength: 32)
        }
        .padding(.horizontal, 32)
        .bbPageWidth(1080)
    }

    // identity — guest: tap to log in; logged-in: tap to edit nickname
    private var identityRow: some View {
        Button { if store.isGuest { showAuth = true } else { showEditNick = true } } label: {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 10).stroke(Color.bbLine).frame(width: 52, height: 52)
                    .overlay(Image(systemName: "person").font(.title2).foregroundColor(.bbInk))
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.isGuest ? "未登录".tr : store.displayName).font(.title3.bold()).foregroundColor(.bbInk)
                    Text(identitySub).font(.caption).foregroundColor(.bbInk2)
                }
                Spacer(minLength: 0)
                if store.isGuest {
                    Text("登录 / 注册".tr).font(.caption.weight(.semibold)).foregroundColor(.bbGreen)
                    Image(systemName: "chevron.right").font(.caption).foregroundColor(.bbInk2)
                } else {
                    Image(systemName: "pencil").font(.caption).foregroundColor(.bbInk2)
                }
            }
            .padding(.vertical, 14).contentShape(Rectangle())
            .overlay(Rectangle().fill(Color.bbLine).frame(height: 1), alignment: .bottom)
        }
        .buttonStyle(.plain)
    }

    // summary cards (real, persisted counts)
    private var summaryCards: some View {
        HStack(spacing: 10) {
            summaryCard("完成故事".tr, store.storiesCompleted, Color(hex: 0xE4EFE7), Color(hex: 0x35583F))
            summaryCard("解锁图鉴".tr, store.codexUnlocked, Color.bbBlue, Color(hex: 0x3A5A78))
            summaryCard("记账天数".tr, store.recordDays, Color(hex: 0xFFF4DF), Color(hex: 0x8A5A2B))
        }
    }

    @ViewBuilder
    private var storiesSection: some View {
        profileSection("故 事 与 学 习".tr) {
            Button { tab = 2 } label: { rowLabel("book", "已通关故事".tr, right: "\(store.storiesCompleted) / \(StoryStore.all.count)") }.buttonStyle(.plain)
            NavigationLink { CodexView() } label: { rowLabel("rectangle.stack", "已解锁图鉴".tr, right: "\(store.codexUnlocked) / \(CodexStore.all.count)") }.buttonStyle(.plain)
            Button { tab = 2 } label: { rowLabel("play.circle", "理财课程".tr, right: "已完成".tr + " \(store.lessonsCompleted)/\(LessonStore.all.count)") }.buttonStyle(.plain)
            NavigationLink { ChallengesView() } label: { rowLabel("flag", "我的挑战".tr, right: store.activeChallengeCount > 0 ? "\(store.activeChallengeCount) " + "个进行中".tr : "去看看".tr) }.buttonStyle(.plain)
            ReminderToggleRow()
        }
    }

    @ViewBuilder
    private var recordsSection: some View {
        profileSection("我 的 记 录".tr) {
            Button { tab = 1 } label: { rowLabel("square.and.pencil", "消费选择记录".tr, right: "\(store.outCount) " + "次".tr) }.buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var accountSection: some View {
        profileSection("账 户".tr) {
            if store.isGuest {
                Button { showAuth = true } label: { rowLabel("person.badge.plus", "登录 / 注册".tr, right: "同步与找回数据".tr) }.buttonStyle(.plain)
                Button { showSyncInfo = true } label: { rowLabel("cloud", "云端同步".tr, right: "未开启".tr) }.buttonStyle(.plain)
            } else {
                Button { showSyncInfo = true } label: { rowLabel("cloud", "云端同步".tr, right: "已开启".tr) }.buttonStyle(.plain)
            }
            Button { showEditNick = true } label: { rowLabel("pencil", "编辑昵称".tr) }.buttonStyle(.plain)
            ShareLink(item: exportJSON) { rowLabel("square.and.arrow.up", "导出数据".tr) }
            NavigationLink { FeedbackView() } label: {
                rowLabel("ladybug", "问题反馈".tr,
                         right: inbox.unread > 0 ? String(format: "%d 条新回复".tr, inbox.unread) : nil,
                         rightTint: .bbRed)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("profile.feedback")
            Button { BBRating.openWriteReview() } label: { rowLabel("star", "去 App Store 评分".tr) }
                .buttonStyle(.plain)
                .accessibilityIdentifier("profile.rate.app")
            ShareLink(item: BBRating.listingURL,
                      message: Text("我在用省钱搭子练财商，故事挺好玩的，推荐你试试！".tr)) {
                rowLabel("gift", "推荐给朋友".tr)
            }
            .accessibilityIdentifier("profile.share.app")
            Menu {
                Button("中文") { BBLang.set("zh") }
                Button("English") { BBLang.set("en") }
            } label: { rowLabel("globe", "语言".tr, right: BBLang.isEN ? "English" : "中文") }
            Button { showResetConfirm = true } label: { rowLabel("arrow.counterclockwise", "恢复默认数据".tr) }.buttonStyle(.plain)
            if !store.isGuest {
                Button { Task { await store.logout() } } label: { rowLabel("rectangle.portrait.and.arrow.right", "退出登录".tr, tint: .bbRed) }.buttonStyle(.plain)
                Button { showDeleteSheet = true } label: { rowLabel("trash", "删除账号".tr, tint: .bbRed) }.buttonStyle(.plain)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                NavigationLink { Legal.terms } label: { Text("用户协议".tr) }.foregroundColor(.bbInk)
                Text("·").foregroundColor(.bbInk2)
                NavigationLink { Legal.privacy } label: { Text("隐私政策".tr) }.foregroundColor(.bbInk)
            }
            .font(.caption).padding(.top, 24)

            VStack(spacing: 3) {
                Text("省钱搭子 BudgetBuddy").font(.caption.weight(.semibold)).foregroundColor(.bbInk2)
                Text("陪你把每一次选择，变成更好的决定".tr).font(.caption2).foregroundColor(.bbInk2)
            }
            .padding(.top, 12)
        }
    }

    private var identitySub: String {
        if store.isGuest {
            return "游客模式 · 数据保存在本机".tr + " · " + "已记账".tr + " \(store.recordDays) " + "天".tr
        }
        let ag = store.user?.ageGroup ?? ""
        return (ag.isEmpty ? "学生".tr : ag.tr) + " · " + "已记账".tr + " \(store.recordDays) " + "天".tr
    }
    private var exportJSON: String {
        guard let data = try? JSONEncoder().encode(store.state),
              let s = String(data: data, encoding: .utf8) else { return "{}" }
        return s
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if hSize == .regular { padLayout } else { phoneLayout }
            }
            .background(Color.bbBg)
            .navigationTitle("我的".tr)
            .sheet(isPresented: $showEditNick) {
                EditNicknameSheet(current: store.displayName) { store.updateNickname($0) }
            }
            .sheet(isPresented: $showDeleteSheet) {
                DeleteAccountSheet()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showAuth) {
                AuthView().environmentObject(store)
            }
            .alert("云端同步".tr, isPresented: $showSyncInfo) {
                Button("好的".tr, role: .cancel) {}
            } message: {
                Text(store.isGuest
                    ? "登录后，你的记账和故事进度会自动同步到云端，换设备也不会丢。现在的数据只保存在这台手机上。".tr
                    : "你的数据已安全保存到你的账号，换个设备登录也能看到自己的记录。".tr)
            }
            .alert("恢复默认数据？".tr, isPresented: $showResetConfirm) {
                Button("取消".tr, role: .cancel) {}
                Button("恢复".tr, role: .destructive) { store.resetData() }
            } message: { Text("你记的账和故事进度会被清空。".tr) }
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

    private func rowLabel(_ icon: String, _ title: String, right: String? = nil, tint: Color = .bbInk, rightTint: Color = .bbInk2) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon).font(.system(size: 18)).foregroundColor(tint == .bbRed ? .bbRed : .bbInk2).frame(width: 24)
            Text(title).foregroundColor(tint)
            Spacer(minLength: 0)
            if let right { Text(right).font(.caption).foregroundColor(rightTint) }
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
                TextField("昵称".tr, text: $name)
            }
            .navigationTitle("编辑昵称".tr)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消".tr) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存".tr) { onSave(name); dismiss() }
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
                    Text("这将永久删除你的账号和所有数据（记账、故事进度、挑战），且无法恢复。".tr)
                        .foregroundColor(.bbInk2)
                    SecureField("当前密码".tr, text: $password)
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
            .navigationTitle("永久删除账号".tr)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消".tr) { dismiss() }
                        .disabled(busy)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(busy ? "删除中".tr : "删除".tr, role: .destructive) {
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
            err = store.errorMessage ?? "删除失败，请重试".tr
            busy = false
        }
    }
}
