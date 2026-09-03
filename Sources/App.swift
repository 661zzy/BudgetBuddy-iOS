import SwiftUI

@main
struct BudgetBuddyApp: App {
    @StateObject private var store = AppStore()
    init() { Diagnostics.start() }
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(store)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.scenePhase) private var scenePhase
    // Language switch rebuilds the whole tree so every .tr re-evaluates instantly.
    @AppStorage("bb.lang") private var bbLang = "zh"
    var body: some View {
        Group {
            switch store.phase {
            case .loading:
                ZStack {
                    Color.bbBg.ignoresSafeArea()
                    VStack(spacing: 12) {
                        Text("省钱搭子").font(.title2.bold()).foregroundColor(.bbInk)
                        ProgressView().tint(.bbGreen)
                        Text("正在连接…".tr).font(.caption).foregroundColor(.bbInk2)
                    }
                }
            case .auth:
                // First launch only: language + onboarding. There is NO login wall —
                // guests go straight into the app (App Store Guideline 5.1.1(v));
                // login/register lives in 我的 as an optional sheet.
                OnboardingView()
            case .app:
                MainTabView().modifier(EngagementPromptModifier())
            }
        }
        .task {
            WatchBridge.shared.activate(store: store)
            if case .loading = store.phase { await store.boot() }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                BBReminder.resync()
                Task { await store.foregroundUpdateCheck() }
            }
        }
        .sheet(item: $store.update) { UpdateSheet(prompt: $0) }
        .id(bbLang)   // rebuild everything when the language changes
        .preferredColorScheme(.light)   // custom cream theme — always render light
    }
}
