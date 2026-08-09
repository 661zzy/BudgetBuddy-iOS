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
        VStack(spacing: 0) {
            // Mascot band — the cream page needs a colored anchor at the top,
            // otherwise the emoji floats alone in a field of beige.
            ZStack {
                Circle().fill(Color.bbGreen.opacity(0.10)).frame(width: 96, height: 96)
                Circle().fill(Color.bbSurface).frame(width: 74, height: 74)
                    .overlay(Circle().stroke(Color.bbLine))
                Text("💚").font(.system(size: 38))
            }
            .padding(.top, 26)

            Text("用得还顺手吗？".tr)
                .font(.system(.title3, design: .rounded).weight(.bold)).foregroundColor(.bbInk)
                .padding(.top, 14)
            Text("你已经用了一小会儿。一句好评或一条吐槽，都特别有用。".tr)
                .font(.system(.subheadline, design: .rounded)).foregroundColor(.bbInk2)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 26).padding(.top, 6)

            VStack(spacing: 10) {
                Button {
                    // Consume the system-prompt shot as well — one rating moment total.
                    UserDefaults.standard.set(true, forKey: "bb.review.prompted.v1")
                    BBRating.openWriteReview()
                    onDone()
                } label: {
                    optionRow("star.fill", "去 App Store 好评".tr, "喜欢的话，给个五星".tr, primary: true)
                }
                .accessibilityIdentifier("engage.rate")

                Button { showFeedback = true } label: {
                    optionRow("ladybug.fill", "有问题，直接反馈".tr, "一句话发给我们，秒到".tr, primary: false)
                }
                .accessibilityIdentifier("engage.feedback")
            }
            .padding(.horizontal, 20).padding(.top, 22)

            Button { onDone() } label: {
                Text("下次再说".tr)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold)).foregroundColor(.bbInk2)
                    .padding(.vertical, 14).frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("engage.later")
            .padding(.top, 4)

            Spacer(minLength: 0)
        }
        .bbPageWidth(520)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bbBg)
        .presentationDetents([.height(430)])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showFeedback, onDismiss: onDone) {
            NavigationView { FeedbackView() }
        }
    }

    // Card row: icon tile + title + one line of why-bother, chevron on the end.
    private func optionRow(_ icon: String, _ title: String, _ sub: String, primary: Bool) -> some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 11)
                    .fill(primary ? Color.white.opacity(0.18) : Color.bbBg)
                    .frame(width: 42, height: 42)
                Image(systemName: icon).font(.system(size: 18, weight: .semibold))
                    .foregroundColor(primary ? .white : .bbGreen)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(primary ? .white : .bbInk)
                Text(sub).font(.caption).foregroundColor(primary ? Color.white.opacity(0.75) : .bbInk2)
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold))
                .foregroundColor(primary ? Color.white.opacity(0.65) : .bbInk2.opacity(0.5))
        }
        .padding(.horizontal, 14).padding(.top, 13)
        // duo() paints a 4pt bottom edge behind the fill — pad for it so the
        // pressable lip stays visible instead of being covered by the content.
        .padding(.bottom, primary ? 17 : 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(OptionRowSkin(primary: primary))
    }
}

// Primary = chunky green duo card; secondary = plain surface card.
private struct OptionRowSkin: ViewModifier {
    let primary: Bool
    func body(content: Content) -> some View {
        if primary {
            content.duo(.bbGreen, duoGreenEdge, radius: 15)
        } else {
            content
                .background(RoundedRectangle(cornerRadius: 15).fill(Color.bbSurface))
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.bbLine))
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
