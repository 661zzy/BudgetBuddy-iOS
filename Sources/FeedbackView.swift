import SwiftUI
import UIKit
import PhotosUI

struct FeedbackView: View {
    @EnvironmentObject var store: AppStore
    @ObservedObject private var inbox = FeedbackInbox.shared
    @State private var note = ""
    @State private var copied = false
    @State private var sending = false
    @State private var sent = false
    @State private var sendError = ""
    @State private var picks: [PhotosPickerItem] = []
    @State private var shots: [UIImage] = []

    private static let maxShots = 3

    private var hasCrash: Bool { Diagnostics.lastCrash() != nil }

    // 用户反馈：发送太麻烦（要走分享→邮件）。现在一键直达服务器，
    // 分享/邮件降级为后备通道（服务端接口未就绪或断网时仍可用）。
    private func submit() {
        guard !sending, !sent else { return }
        sending = true; sendError = ""
        let payload = shots.compactMap { $0.bbFeedbackJPEGBase64() }
        Task {
            do {
                try await APIClient.shared.sendFeedback(message: note, diagnostics: report, images: payload)
                sent = true
                await inbox.didSubmit(signedInAs: store.user?.id)
            } catch {
                sendError = bbAPIMessage(error) ?? "没发出去，试试下面的分享或邮件方式".tr
            }
            sending = false
        }
    }

    // Screenshots arrive from Photos at full resolution; downscale before they
    // ever reach memory twice or the request body.
    private func loadPicks(_ items: [PhotosPickerItem]) {
        Task {
            var loaded: [UIImage] = []
            for item in items.prefix(Self.maxShots) {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    loaded.append(img)
                }
            }
            await MainActor.run { shots = loaded }
        }
    }

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
                FeedbackThreadsSection()

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

                Text("截图（选填，最多 3 张）".tr)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold)).foregroundColor(.bbInk)
                HStack(spacing: 10) {
                    ForEach(Array(shots.enumerated()), id: \.offset) { idx, img in
                        Image(uiImage: img).resizable().aspectRatio(contentMode: .fill)
                            .frame(width: 74, height: 74).clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine))
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    shots.remove(at: idx)
                                    if idx < picks.count { picks.remove(at: idx) }
                                } label: {
                                    Image(systemName: "xmark.circle.fill").font(.system(size: 19))
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, Color.bbInk.opacity(0.75))
                                }
                                .offset(x: 6, y: -6)
                            }
                    }
                    if shots.count < Self.maxShots {
                        PhotosPicker(selection: $picks, maxSelectionCount: Self.maxShots, matching: .images) {
                            VStack(spacing: 3) {
                                Image(systemName: "photo.badge.plus").font(.system(size: 20))
                                Text("添加".tr).font(.caption2)
                            }
                            .foregroundColor(.bbInk2)
                            .frame(width: 74, height: 74)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.bbSurface))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                                .foregroundColor(.bbLine))
                        }
                        .accessibilityIdentifier("feedback.addshot")
                    }
                    Spacer(minLength: 0)
                }
                .onChange(of: picks) { loadPicks($0) }

                Text("诊断信息（会一起发送）".tr).font(.system(.subheadline, design: .rounded).weight(.semibold)).foregroundColor(.bbInk)
                Text(report)
                    .font(.system(.caption, design: .monospaced)).foregroundColor(.bbInk2)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.bbSurface))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine))

                Button { submit() } label: {
                    HStack(spacing: 8) {
                        if sending { ProgressView().tint(.white) }
                        Text(sent ? "已发送，谢谢反馈 ✓".tr : (sending ? "发送中…".tr : "直接发送".tr))
                            .font(.system(.headline, design: .rounded).weight(.bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                    .duo(sent ? Color(hex: 0x2C4537) : .bbGreen, duoGreenEdge)
                }
                .disabled(sending || sent)
                .accessibilityIdentifier("feedback.submit")

                if sent && !inbox.unavailable {
                    Text("我们回复后，会显示在这一页上方的「我的反馈」里。".tr)
                        .font(.footnote).foregroundColor(.bbInk2)
                }

                if !shots.isEmpty {
                    Text(String(format: "%d 张截图会跟着一起发出".tr, shots.count))
                        .font(.footnote).foregroundColor(.bbInk2)
                }

                if !sendError.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle")
                        Text(sendError)
                    }
                    .font(.footnote).foregroundColor(.bbRed)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                ShareLink(item: report) {
                    Text("或通过分享 / 邮件发送".tr).font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(.bbGreen)
                        .frame(maxWidth: .infinity).padding(.vertical, 4)
                }
                Button {
                    UIPasteboard.general.string = report
                    copied = true
                } label: {
                    Text(copied ? "已复制 ✓".tr : "复制诊断信息".tr)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold)).foregroundColor(.bbInk2)
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
        .task { await inbox.refresh(signedInAs: store.user?.id, force: true) }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成".tr) { bbHideKeyboard() }.font(.system(.body, design: .rounded).weight(.semibold))
            }
        }
    }
}

extension UIImage {
    /// Long edge capped at 1280pt and JPEG-encoded — a phone screenshot goes
    /// from several MB to ~150KB, so three of them fit in one JSON request.
    func bbFeedbackJPEGBase64(maxEdge: CGFloat = 1280, quality: CGFloat = 0.7) -> String? {
        let longest = max(size.width, size.height)
        let scale = longest > maxEdge ? maxEdge / longest : 1
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let img: UIImage = scale < 1
            ? UIGraphicsImageRenderer(size: target).image { _ in
                  draw(in: CGRect(origin: .zero, size: target))
              }
            : self
        return img.jpegData(compressionQuality: quality)?.base64EncodedString()
    }
}
