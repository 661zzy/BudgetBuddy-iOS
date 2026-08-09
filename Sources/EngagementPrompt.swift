import SwiftUI

// v1.5.1 engagement prompts (real-user feedback: "更新没人提醒、评价和反馈入口太深").
// One popup after ~3 minutes of cumulative foreground use, with two exits —
// a good experience goes to the App Store review sheet, a problem goes to the
// one-tap feedback page. Single shot per install, and the story-completion
// rating moment counts as that shot too, so users are never nagged twice.
// Pairs with the foreground update re-check in RootView.
enum BBEngage {
    static let usageKey = "bb.usage.seconds"
    static let promptedKey = "bb.engage.prompted.v1"
    static let threshold = 180   // seconds of real foreground use

    static var prompted: Bool {
        UserDefaults.standard.bool(forKey: promptedKey)
            || UserDefaults.standard.bool(forKey: "bb.review.prompted.v1")
    }
    static func markPrompted() { UserDefaults.standard.set(true, forKey: promptedKey) }

    static func tick(_ seconds: Int) -> Int {
        let total = UserDefaults.standard.integer(forKey: usageKey) + seconds
        UserDefaults.standard.set(total, forKey: usageKey)
        return total
    }
}

// The app already owns a language for asking someone to choose: the story
// engine — 📍setting card → narrator card → choice cards with a hint line.
// Players have read 33 scenes in that grammar, so the feedback ask is staged
// as one more scene (「现实场景」— the only non-fictional one in the app)
// rather than a stock rating dialog with a mascot emoji bolted on top.
struct EngagementSheet: View {
    let onDone: () -> Void
    @State private var showFeedback = false

    private var minutesHere: Int {
        max(3, UserDefaults.standard.integer(forKey: BBEngage.usageKey) / 60)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            // Story scenes open with a progress capsule. Here it reads full:
            // you already walked the distance that earned the question.
            Capsule().fill(Color.bbGreen).frame(height: 7).padding(.top, 4)

            sceneCard
            narratorCard

            choiceCard("去 App Store 打个分".tr, "让更多同学找得到它".tr) {
                // Consume the system-prompt shot too — one rating moment total.
                UserDefaults.standard.set(true, forKey: "bb.review.prompted.v1")
                BBRating.openWriteReview()
                onDone()
            }
            .accessibilityIdentifier("engage.rate")

            choiceCard("有问题，想吐槽".tr, "直接发给开发者，很快能看到".tr) { showFeedback = true }
                .accessibilityIdentifier("engage.feedback")

            Button { onDone() } label: {
                Text("先不了，继续用".tr)
                    .font(.subheadline.weight(.semibold)).foregroundColor(.bbInk2)
                    .padding(.vertical, 12).frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("engage.later")

            Spacer(minLength: 0)
        }
        .padding(16)
        .bbPageWidth(520)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.bbBg)
        .presentationDetents([.height(455)])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showFeedback, onDismiss: onDone) {
            NavigationView { FeedbackView() }
        }
    }

    private var sceneCard: some View {
        HStack(spacing: 12) {
            Text("💬").font(.system(size: 26))
                .frame(width: 50, height: 50).background(Color.bbBg).cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.bbLine))
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 3) { Image(systemName: "mappin"); Text("现实场景".tr) }
                    .font(.caption.weight(.semibold)).foregroundColor(.bbInk)
                Text("搭子想问你一句".tr).font(.headline).foregroundColor(.bbInk)
            }
            Spacer()
        }
        .padding(13).background(Color.bbSurface)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.bbLine)).cornerRadius(10)
    }

    // Normally fires at exactly 3 minutes, so the number is concrete and true.
    // Past half an hour, quoting it back reads like surveillance — drop it.
    private var narratorLine: String {
        minutesHere <= 30
            ? String(format: "你已经在这儿待了 %d 分钟。花 10 秒，让它对下一个人更好用？".tr, minutesHere)
            : "你已经用了好一阵了。花 10 秒，让它对下一个人更好用？".tr
    }

    private var narratorCard: some View {
        Text(narratorLine)
            .font(.body).foregroundColor(.bbInk).lineSpacing(5)
            .frame(maxWidth: .infinity, alignment: .leading).padding(16)
            .background(Color.bbSurface)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine)).cornerRadius(12)
    }

    // Same shape as StoryView.choiceButton: bold label, quiet hint underneath.
    private func choiceCard(_ label: String, _ hint: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(label).font(.body.weight(.medium)).foregroundColor(.bbInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(hint).font(.caption).foregroundColor(.bbInk2)
            }
            .padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.bbSurface)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.bbLine)).cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// Attached to MainTabView: counts foreground seconds and raises the one-time sheet.
struct EngagementPromptModifier: ViewModifier {
    @EnvironmentObject var store: AppStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var show = false
    private let heartbeat = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    func body(content: Content) -> some View {
        content
            .onReceive(heartbeat) { _ in
                guard scenePhase == .active, !show, !BBEngage.prompted, store.update == nil else { return }
                if BBEngage.tick(5) >= BBEngage.threshold { show = true }
            }
            .sheet(isPresented: $show, onDismiss: { BBEngage.markPrompted() }) {
                EngagementSheet { show = false }
            }
    }
}
