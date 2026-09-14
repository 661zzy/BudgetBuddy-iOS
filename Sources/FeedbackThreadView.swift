import SwiftUI

// MARK: - 我的反馈 (v1.6.2)

/// The "我的反馈" card at the top of the feedback page: newest threads first,
/// with the reply state at a glance.
struct FeedbackThreadsSection: View {
    @EnvironmentObject var store: AppStore
    @ObservedObject var inbox = FeedbackInbox.shared
    private let maxRows = 3

    var body: some View {
        if !inbox.threads.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("我的反馈".tr).font(.system(.subheadline, design: .rounded).weight(.semibold)).foregroundColor(.bbInk)
                    if inbox.unread > 0 {
                        Text(String(format: "%d 条新回复".tr, inbox.unread))
                            .font(.caption.weight(.semibold)).foregroundColor(.white)
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(Capsule().fill(Color.bbRed))
                    }
                    Spacer()
                    if inbox.threads.count > maxRows {
                        NavigationLink { FeedbackThreadListView() } label: {
                            Text(String(format: "全部 %d 条".tr, inbox.threads.count)).font(.caption).foregroundColor(.bbGreen)
                        }
                        .accessibilityIdentifier("feedback.threads.all")
                    }
                }
                .padding(.bottom, 8)
                VStack(spacing: 0) {
                    ForEach(inbox.threads.prefix(maxRows)) { t in
                        NavigationLink { FeedbackThreadView(threadID: t.id) } label: { FeedbackThreadRow(thread: t) }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("feedback.thread.\(t.id)")
                    }
                }
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.bbSurface))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine))
                if store.isGuest {
                    Text("没登录时，回复只会显示在这台设备上。".tr)
                        .font(.caption).foregroundColor(.bbInk2).padding(.top, 6)
                }
            }
        }
    }
}

struct FeedbackThreadListView: View {
    @ObservedObject var inbox = FeedbackInbox.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(inbox.threads) { t in
                    NavigationLink { FeedbackThreadView(threadID: t.id) } label: { FeedbackThreadRow(thread: t) }
                        .buttonStyle(.plain)
                }
            }
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.bbSurface))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine))
            .padding(16)
            .bbPageWidth()
        }
        .background(Color.bbBg)
        .navigationTitle("我的反馈".tr)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeedbackThreadRow: View {
    let thread: FeedbackThread

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle().fill(thread.unread > 0 ? Color.bbRed : Color.clear).frame(width: 8, height: 8).padding(.top, 6)
            VStack(alignment: .leading, spacing: 3) {
                Text(thread.message.isEmpty ? "（只发送了诊断信息）".tr : thread.message)
                    .font(.system(.subheadline, design: .rounded).weight(thread.unread > 0 ? .semibold : .regular))
                    .foregroundColor(.bbInk).lineLimit(1)
                if let last = thread.messages.last {
                    Text((last.isTeam ? "省钱搭子：".tr : "我：".tr) + last.body)
                        .font(.caption).foregroundColor(.bbInk2).lineLimit(2)
                }
            }
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: 3) {
                Text(thread.statusLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(thread.status == "replied" ? .bbGreen : .bbInk2)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(thread.status == "replied" ? Color(hex: 0xDDEBDD) : Color.bbLine.opacity(0.6)))
                Text(bbFeedbackTime(thread.updatedAt)).font(.caption2).foregroundColor(.bbInk2)
            }
        }
        .padding(.vertical, 11).padding(.horizontal, 12)
        .contentShape(Rectangle())
        .overlay(Rectangle().fill(Color.bbLine).frame(height: 1), alignment: .bottom)
    }
}

/// One conversation: the original feedback, the team's replies, and a composer.
struct FeedbackThreadView: View {
    let threadID: Int
    @ObservedObject var inbox = FeedbackInbox.shared
    @State private var draft = ""
    @State private var sending = false
    @State private var error = ""
    @FocusState private var composerFocused: Bool

    private var thread: FeedbackThread? { inbox.thread(threadID) }
    private static let maxChars = 1000

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if let t = thread {
                    VStack(alignment: .leading, spacing: 10) {
                        bubble(text: t.message.isEmpty ? "（只发送了诊断信息）".tr : t.message,
                               team: false, time: t.createdAt,
                               note: t.imageCount > 0 ? String(format: "附 %d 张截图".tr, t.imageCount) : nil)
                        if t.messages.isEmpty {
                            Text("已经收到了，我们看过后会在这里回复你。".tr)
                                .font(.footnote).foregroundColor(.bbInk2)
                                .frame(maxWidth: .infinity).padding(.vertical, 8)
                        }
                        ForEach(t.messages) { m in
                            bubble(text: m.body, team: m.isTeam, time: m.createdAt, note: nil)
                                .id(m.id)
                        }
                        if t.status == "closed" {
                            Text("这条反馈已处理完。还有问题可以直接接着说。".tr)
                                .font(.footnote).foregroundColor(.bbInk2)
                                .frame(maxWidth: .infinity).padding(.vertical, 6)
                        }
                    }
                    .padding(16)
                    .bbPageWidth()
                    .onAppear { if let last = t.messages.last { proxy.scrollTo(last.id, anchor: .bottom) } }
                } else {
                    Text("找不到这条反馈".tr).foregroundColor(.bbInk2).padding(.top, 60)
                }
            }
            .onChange(of: thread?.messages.count ?? 0) { _ in
                if let last = thread?.messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
            }
        }
        .background(Color.bbBg)
        .safeAreaInset(edge: .bottom) { if thread != nil { composer } }
        .navigationTitle("反馈对话".tr)
        .navigationBarTitleDisplayMode(.inline)
        .task { await inbox.markRead(threadID) }
    }

    private func bubble(text: String, team: Bool, time: TimeInterval, note: String?) -> some View {
        HStack {
            if !team { Spacer(minLength: 40) }
            VStack(alignment: team ? .leading : .trailing, spacing: 4) {
                if team {
                    Label("省钱搭子团队".tr, systemImage: "bubble.left.and.bubble.right.fill")
                        .font(.caption.weight(.semibold)).foregroundColor(.bbGreen)
                }
                Text(text)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(team ? .bbInk : .white)
                    .textSelection(.enabled)
                    .padding(.horizontal, 13).padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(team ? Color.bbSurface : Color.bbGreen)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(team ? Color.bbLine : Color.clear))
                    )
                HStack(spacing: 6) {
                    if let note { Text(note) }
                    Text(bbFeedbackTime(time))
                }
                .font(.caption2).foregroundColor(.bbInk2)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(team ? "feedback.bubble.team" : "feedback.bubble.user")
            if team { Spacer(minLength: 40) }
        }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !error.isEmpty {
                Text(error).font(.footnote).foregroundColor(.bbRed)
            }
            HStack(alignment: .bottom, spacing: 8) {
                TextField("接着说点什么…".tr, text: $draft, axis: .vertical)
                    .lineLimit(1...5)
                    .font(.system(.body, design: .rounded))
                    .focused($composerFocused)
                    .padding(.horizontal, 12).padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color.bbSurface))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.bbLine))
                    .accessibilityIdentifier("feedback.composer")
                Button { send() } label: {
                    Group {
                        if sending { ProgressView().tint(.white) } else { Image(systemName: "arrow.up") }
                    }
                    .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(canSend ? Color.bbGreen : Color.bbInk2.opacity(0.35)))
                }
                .disabled(!canSend)
                .accessibilityLabel("发送".tr)
                .accessibilityIdentifier("feedback.composer.send")
            }
            if draft.count > Self.maxChars - 100 {
                Text("\(draft.count)/\(Self.maxChars)").font(.caption2)
                    .foregroundColor(draft.count > Self.maxChars ? .bbRed : .bbInk2)
            }
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 8)
        .background(Color.bbBg.opacity(0.97).ignoresSafeArea(edges: .bottom))
        .overlay(Rectangle().fill(Color.bbLine).frame(height: 1), alignment: .top)
    }

    private var canSend: Bool {
        let n = draft.trimmingCharacters(in: .whitespacesAndNewlines).count
        return !sending && n > 0 && draft.count <= Self.maxChars
    }

    private func send() {
        guard canSend else { return }
        sending = true; error = ""
        let text = draft
        Task {
            do {
                try await inbox.sendFollowUp(text, to: threadID)
                draft = ""
            } catch {
                self.error = bbAPIMessage(error) ?? "没发出去，请检查网络后再试".tr
            }
            sending = false
        }
    }
}

/// Home banner when the team has replied and the user hasn't opened it yet.
struct FeedbackReplyBanner: View {
    @ObservedObject var inbox = FeedbackInbox.shared
    var bottomPadding: CGFloat = 0
    let open: (FeedbackThread) -> Void

    var body: some View {
        if let t = inbox.firstUnread {
            Button { open(t) } label: {
                HStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 17)).foregroundColor(.bbGreen)
                        .frame(width: 38, height: 38)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: 0xDDEBDD)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("你的反馈有新回复".tr).font(.headline).foregroundColor(.bbInk)
                        Text(t.messages.last(where: { $0.isTeam })?.body ?? "")
                            .font(.caption).foregroundColor(.bbInk2).lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.right").foregroundColor(.bbInk2)
                }
                .padding(14)
                .background(Color.bbSurface)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.bbGreen.opacity(0.45)))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("feedback.banner")
            .padding(.bottom, bottomPadding)
        }
    }
}
