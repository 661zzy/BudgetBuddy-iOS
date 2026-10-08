import Foundation
import Combine
import Security

// MARK: - 反馈回复 (v1.6.2)
//
// Feedback used to be one-way: it landed in the database and an email to
// support, and the person who sent it never heard back. Now every feedback is a
// small conversation: the team replies from the ops page, the reply shows up
// here, and the user can answer in the same thread.
//
// Who owns a thread (server side, backend 4.9):
//   • signed in  → the account (user_id), on any device
//   • guest      → this device, via a random 64-hex key kept in the Keychain
//                  (the server stores only its sha256; it travels in the POST
//                  body, never in a URL)
// Signed-in users also see threads this device sent as a guest.

struct FeedbackMessage: Codable, Identifiable, Equatable {
    let id: Int
    let author: String          // "team" | "user"
    let body: String
    let createdAt: TimeInterval
    var isTeam: Bool { author == "team" }
}

struct FeedbackThread: Codable, Identifiable, Equatable {
    let id: Int
    let message: String
    let imageCount: Int
    var status: String          // open | replied | closed
    let createdAt: TimeInterval
    var updatedAt: TimeInterval
    var unread: Int
    var messages: [FeedbackMessage]

    var hasTeamReply: Bool { messages.contains { $0.isTeam } }
    /// What the list row shows: the newest message, or the original text.
    var preview: String {
        if let last = messages.last { return last.body }
        return message.isEmpty ? "（只发送了诊断信息）".tr : message
    }
    var statusLabel: String {
        switch status {
        case "closed": return "已处理".tr
        case "replied": return "已回复".tr
        default: return "等待回复".tr
        }
    }
}

struct FeedbackThreadsResponse: Codable {
    let threads: [FeedbackThread]
    let unread: Int
}

struct FeedbackReplyResponse: Codable {
    let thread: FeedbackThread
}

struct FeedbackSubmitResponse: Codable {
    let ok: Bool?
    let id: Int?
}

/// The device's feedback key. Created the first time this device sends feedback.
enum FeedbackKey {
    static let account = "bb_feedback_key"

    static var current: String? {
        guard let k = Keychain.get(account), isValid(k) else { return nil }
        return k
    }

    static func ensure() -> String {
        if let k = current { return k }
        var bytes = [UInt8](repeating: 0, count: 32)
        if SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) != errSecSuccess {
            bytes = (0..<32).map { _ in UInt8.random(in: .min ... .max) }
        }
        let k = bytes.map { String(format: "%02x", $0) }.joined()
        Keychain.set(k, for: account)
        return k
    }

    static func isValid(_ k: String) -> Bool {
        k.count == 64 && k.allSatisfy { ("0"..."9").contains($0) || ("a"..."f").contains($0) }
    }
}

@MainActor
final class FeedbackInbox: ObservableObject {
    static let shared = FeedbackInbox()

    @Published private(set) var threads: [FeedbackThread] = []
    @Published private(set) var loading = false
    /// The server doesn't have the reply endpoints (old backend) — hide the feature quietly.
    @Published private(set) var unavailable = false

    var unread: Int { threads.reduce(0) { $0 + $1.unread } }
    var firstUnread: FeedbackThread? { threads.first { $0.unread > 0 } }
    func thread(_ id: Int) -> FeedbackThread? { threads.first { $0.id == id } }

    private var lastFetch: Date?
    private var lastOwner: String?
    private static let throttle: TimeInterval = 10 * 60

    // UI-test seam: `-bb.uitest.feedbackThreads '<FeedbackThreadsResponse JSON>'`
    // serves canned threads and keeps reads / follow-ups local.
    static let stubKey = "bb.uitest.feedbackThreads"
    private var stub: Bool

    init(defaults: UserDefaults = .standard, arguments: [String] = ProcessInfo.processInfo.arguments) {
        // A JSON value doesn't survive NSArgumentDomain's plist parsing, so read the raw argument.
        let argJSON = arguments.firstIndex(of: "-" + Self.stubKey).flatMap { i in
            arguments.indices.contains(i + 1) ? arguments[i + 1] : nil
        }
        if let json = defaults.string(forKey: Self.stubKey) ?? argJSON,
           let r = try? JSONDecoder().decode(FeedbackThreadsResponse.self, from: Data(json.utf8)) {
            threads = r.threads
            stub = true
        } else {
            stub = false
        }
    }

    /// Fetch threads. Throttled unless `force`, and skipped entirely for a guest
    /// who has never sent feedback from this device.
    func refresh(signedInAs userID: Int?, force: Bool = false) async {
        if stub { return }
        let key = FeedbackKey.current
        let owner = "\(userID.map(String.init) ?? "guest")|\(key ?? "")"
        if owner != lastOwner {
            // Signed in or out: never show one owner's threads to the next.
            threads = []
            lastFetch = nil
            lastOwner = owner
        }
        guard userID != nil || key != nil else { threads = []; return }
        if !force, let last = lastFetch, Date().timeIntervalSince(last) < Self.throttle { return }
        guard !loading else { return }
        loading = true
        defer { loading = false }
        do {
            let r = try await APIClient.shared.feedbackThreads(clientKey: key)
            guard owner == lastOwner else { return }   // owner changed mid-flight
            threads = r.threads
            unavailable = false
            lastFetch = Date()
        } catch let e as APIError where e.code == "HTTP_404" {
            unavailable = true
            lastFetch = Date()
        } catch {
            // Offline or a hiccup: keep what we have, try again next time.
        }
    }

    func markRead(_ id: Int) async {
        guard let i = threads.firstIndex(where: { $0.id == id }), threads[i].unread > 0 else { return }
        threads[i].unread = 0
        if stub { return }
        try? await APIClient.shared.markFeedbackRead(id: id, clientKey: FeedbackKey.current)
    }

    func sendFollowUp(_ text: String, to id: Int) async throws {
        let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        if stub {
            guard let i = threads.firstIndex(where: { $0.id == id }) else { return }
            let nextID = (threads.flatMap(\.messages).map(\.id).max() ?? 0) + 1
            threads[i].messages.append(FeedbackMessage(id: nextID, author: "user", body: body, createdAt: Date().timeIntervalSince1970))
            threads[i].status = "open"
            threads[i].updatedAt = Date().timeIntervalSince1970
            return
        }
        let fresh = try await APIClient.shared.sendFeedbackReply(id: id, message: body, clientKey: FeedbackKey.current)
        apply(fresh)
    }

    /// A new feedback was just sent: show it right away on the next refresh.
    func didSubmit(signedInAs userID: Int?) async {
        await refresh(signedInAs: userID, force: true)
    }

    func apply(_ fresh: FeedbackThread) {
        if let i = threads.firstIndex(where: { $0.id == fresh.id }) {
            threads.remove(at: i)
        }
        threads.insert(fresh, at: 0)
    }
}

/// "刚刚 / 3 分钟前 / 今天 14:20 / 9月12日 14:20" in the app's language.
func bbFeedbackTime(_ epoch: TimeInterval, now: Date = Date()) -> String {
    let date = Date(timeIntervalSince1970: epoch)
    let diff = now.timeIntervalSince(date)
    let en = BBLang.isEN
    if diff < 60 { return en ? "Just now" : "刚刚" }
    if diff < 3600 { return en ? "\(Int(diff / 60)) min ago" : "\(Int(diff / 60)) 分钟前" }
    let f = DateFormatter()
    f.locale = Locale(identifier: en ? "en_US" : "zh_CN")
    if Calendar.current.isDate(date, inSameDayAs: now) {
        f.dateFormat = "HH:mm"
        return (en ? "Today " : "今天 ") + f.string(from: date)
    }
    f.setLocalizedDateFormatFromTemplate(Calendar.current.isDate(date, equalTo: now, toGranularity: .year) ? "MMMd HH:mm" : "yMMMd")
    return f.string(from: date)
}
