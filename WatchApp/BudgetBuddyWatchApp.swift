import SwiftUI

// 省钱搭子 Apple Watch — 临时记账：金额 → 分类 → 存。
// Entries queue over WatchConnectivity and land in the iPhone app's ledger
// (guest data included — it migrates into the account on login, same as phone).
@main
struct BudgetBuddyWatchApp: App {
    init() { WatchSync.shared.activate() }
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WatchAddView()
            }
        }
    }
}
