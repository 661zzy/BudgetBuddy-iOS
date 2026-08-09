import SwiftUI

// v1.5.1 engagement prompts (real-user feedback round 2: "更新没人提醒、
// 评价和反馈入口太深"). One popup after ~3 minutes of cumulative foreground
// use, with two exits — good experience goes to the App Store review sheet,
// problems go to the one-tap feedback page. Single shot per install, and the
// story-completion rating moment counts as that shot too, so users are never
// nagged twice. Pairs with the foreground update re-check in RootView.
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

struct EngagementSheet: View {
    let onDone: () -> Void
    @State private var showFeedback = false

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Text("💚").font(.system(size: 56))
            Text("用得还顺手吗？".tr)
                .font(.system(.title2, design: .rounded).weight(.bold)).foregroundColor(.bbInk)
            Text("你已经用了一小会儿。一句好评或一条吐槽，都特别有用。".tr)
                .font(.system(.body, design: .rounded)).foregroundColor(.bbInk2)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button {
                // Consume the system-prompt shot as well — one rating moment total.
                UserDefaults.standard.set(true, forKey: "bb.review.prompted.v1")
                BBRating.openWriteReview()
                onDone()
            } label: {
                Text("去 App Store 好评".tr).font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16).duoPrimary()
            }
            .accessibilityIdentifier("engage.rate")
            Button { showFeedback = true } label: {
                Text("有问题，直接反馈".tr).font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundColor(.bbInk).frame(maxWidth: .infinity).padding(.vertical, 15)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.bbSurface))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.bbLine))
            }
            .accessibilityIdentifier("engage.feedback")
            Button { onDone() } label: {
                Text("下次再说".tr).font(.system(.subheadline, design: .rounded).weight(.semibold)).foregroundColor(.bbInk2)
            }
            .accessibilityIdentifier("engage.later")
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bbBg)
        .sheet(isPresented: $showFeedback, onDismiss: onDone) {
            NavigationView { FeedbackView() }
        }
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
