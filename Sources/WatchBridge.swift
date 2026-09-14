import Combine
import Foundation
import WatchConnectivity

// Receives quick-add entries queued by the Apple Watch app and lands them in
// the ledger through the normal addTransaction path (guest state included —
// watch entries migrate into the account on login exactly like phone entries).
final class WatchBridge: NSObject, WCSessionDelegate {
    static let shared = WatchBridge()
    private weak var store: AppStore?
    private var catsSub: AnyCancellable?
    private var pendingCats: [CustomCategory]?

    @MainActor
    func activate(store: AppStore) {
        self.store = store
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
        // v1.6.1: custom categories follow the account, and the wrist picker
        // should offer the same list. Application context keeps only the
        // latest value, so a burst of edits collapses into one delivery.
        catsSub = store.$state
            .map(\.customCats)
            .removeDuplicates()
            .sink { [weak self] cats in self?.pushCustomCats(cats) }
    }

    private func pushCustomCats(_ cats: [CustomCategory]) {
        let s = WCSession.default
        guard s.activationState == .activated else { pendingCats = cats; return }
        guard s.isPaired, s.isWatchAppInstalled else { return }
        pendingCats = nil
        let payload: [[String: String]] = cats.map { ["name": $0.name, "icon": $0.icon] }
        try? s.updateApplicationContext(["bb.customCats": payload])
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard userInfo["type"] as? String == "bb.tx",
              let amount = userInfo["amount"] as? Double, amount > 0,
              let cat = userInfo["cat"] as? String else { return }
        let kind = (userInfo["kind"] as? String) == "in" ? "in" : "out"
        let note = userInfo["note"] as? String ?? ""
        let ts = userInfo["ts"] as? String
        Task { @MainActor in
            _ = await store?.addTransaction(amount: amount, cat: cat, note: note, kind: kind, ts: ts)
            DiagLog.shared.log("watch tx received ¥\(amount) \(cat)")
        }
    }

    // MARK: required WCSessionDelegate plumbing
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        guard activationState == .activated, let cats = pendingCats else { return }
        DispatchQueue.main.async { self.pushCustomCats(cats) }
    }
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
}
