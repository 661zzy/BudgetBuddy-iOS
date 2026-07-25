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
    var body: some View {
        Group {
            switch store.phase {
            case .loading:
                ZStack {
                    Color.bbBg.ignoresSafeArea()
                    VStack(spacing: 12) {
                        Text("省钱搭子").font(.title2.bold()).foregroundColor(.bbInk)
                        ProgressView().tint(.bbGreen)
                        Text("正在连接…").font(.caption).foregroundColor(.bbInk2)
                    }
                }
            case .auth:
                if store.onboarded { AuthView() } else { OnboardingView() }
            case .app:
                MainTabView()
            }
        }
        .task {
            if case .loading = store.phase { await store.boot() }
        }
        .sheet(item: $store.update) { UpdateSheet(prompt: $0) }
    }
}
