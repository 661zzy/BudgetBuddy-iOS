import Foundation
import WatchConnectivity

// Receives quick-add entries queued by the Apple Watch app and lands them in
// the ledger through the normal addTransaction path (guest state included —
// watch entries migrate into the account on login exactly like phone entries).
final class WatchBridge: NSObject, WCSessionDelegate {
    static let shared = WatchBridge()
    private weak var store: AppStore?

    func activate(store: AppStore) {
        self.store = store
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
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
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
}
