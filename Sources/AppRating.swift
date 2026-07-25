import SwiftUI
import UIKit

// App Store identity + review helpers (v1.1). Early users had no way to leave a
// review from inside the app — this adds a direct write-review jump (我的 →
// 去 App Store 评分) plus a one-time system rating prompt after a story ends well.
enum BBRating {
    static let appID = "6785993334"

    /// Public listing page — what "推荐给朋友" shares (v1.2 feature).
    static var listingURL: URL { URL(string: "https://apps.apple.com/cn/app/id\(appID)")! }

    /// Open the App Store review composer. https apps.apple.com is a universal
    /// link owned by the App Store app, so real devices open the native review
    /// sheet (Safari is never involved). /cn/ because the listing exists only in
    /// the China storefront — in any web fallback the storefront-less URL 404s.
    /// Deliberately NOT itms-apps:// — open() can hand that scheme to Safari and
    /// still report success, so no fallback fires and the user sees "address is
    /// invalid" (found by independent test on build 17). Simulators show that
    /// same alert for ANY store link (no native store app) — environment, not app.
    static func openWriteReview() {
        let web = URL(string: "https://apps.apple.com/cn/app/id\(appID)?action=write-review")!
        UIApplication.shared.open(web)
    }

    private static let promptedKey = "bb.review.prompted.v1"
    /// The system rating prompt may only be asked for sparingly (Apple shows it at
    /// most 3×/year) — consume our one shot only the first time this returns true.
    static func consumeStoryDonePrompt() -> Bool {
        guard !UserDefaults.standard.bool(forKey: promptedKey) else { return false }
        UserDefaults.standard.set(true, forKey: promptedKey)
        return true
    }
}
