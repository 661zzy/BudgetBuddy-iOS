import Foundation
import WatchConnectivity

// Fire-and-forget delivery to the phone. transferUserInfo queues on-device and
// survives launches/offline stretches, so a wrist entry is never lost — it
// arrives whenever the iPhone is next reachable.
final class WatchSync: NSObject, WCSessionDelegate {
    static let shared = WatchSync()

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func queueExpense(amount: Double, cat: String) {
        let ts = ISO8601DateFormatter().string(from: Date())
        WCSession.default.transferUserInfo([
            "type": "bb.tx",
            "kind": "out",
            "amount": amount,
            "cat": cat,
            "note": "",
            "ts": ts,
        ])
    }

    var queuedCount: Int { WCSession.default.outstandingUserInfoTransfers.count }

    // MARK: WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}
