import Foundation
import Combine

@MainActor
final class AppStore: ObservableObject {
    enum Phase { case loading, auth, app }

    @Published var phase: Phase = .loading
    @Published var user: User?
    @Published var state = AppState()
    @Published var errorMessage: String?
    @Published var onboarded: Bool = UserDefaults.standard.bool(forKey: "onboarded")
    @Published var update: UpdatePrompt?

    private let api = APIClient.shared

    func finishOnboarding() {
        onboarded = true
        UserDefaults.standard.set(true, forKey: "onboarded")
    }

    // Verify the session cookie on launch.
    func boot() async {
        do {
            if let u = try await api.me() {
                user = u
                state = (try? await api.loadState()) ?? AppState()
                phase = .app
            } else {
                phase = .auth
            }
        } catch {
            phase = .auth
        }
        await checkUpdate()
    }

    // Auto-check for a newer build (silent no-op if version.json is unreachable).
    func checkUpdate() async {
        guard let info = try? await api.appVersion() else { return }
        let current = Int(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0") ?? 0
        let url = info.url ?? "https://budgetbuddy.cn"
        if current < (info.minBuild ?? 0) {
            update = UpdatePrompt(note: info.note ?? "请更新到最新版本后继续使用。", url: url, force: true)
        } else if current < (info.latestBuild ?? 0) {
            update = UpdatePrompt(note: info.note ?? "发现新版本，建议更新以获得更好体验。", url: url, force: false)
        }
    }

    func register(identifier: String, password: String, nickname: String, code: String) async -> Bool {
        do {
            user = try await api.register(identifier: identifier, password: password, nickname: nickname, ageGroup: "", code: code)
            state = (try? await api.loadState()) ?? AppState()
            phase = .app
            return true
        } catch {
            errorMessage = (error as? APIError)?.message ?? "注册失败，请重试"
            return false
        }
    }

    // Request a verification code (returns devCode when email/SMS isn't configured yet).
    func sendCode(identifier: String, purpose: String) async -> SendCodeResult? {
        do { return try await api.sendCode(identifier: identifier, purpose: purpose) }
        catch { errorMessage = (error as? APIError)?.message ?? "验证码发送失败"; return nil }
    }

    func resetPassword(identifier: String, code: String, password: String) async -> Bool {
        do {
            user = try await api.resetPassword(identifier: identifier, code: code, password: password)
            state = (try? await api.loadState()) ?? AppState()
            phase = .app
            return true
        } catch {
            errorMessage = (error as? APIError)?.message ?? "重置失败，请重试"
            return false
        }
    }

    func login(identifier: String, password: String) async -> Bool {
        do {
            user = try await api.login(identifier: identifier, password: password)
            state = (try? await api.loadState()) ?? AppState()
            phase = .app
            return true
        } catch {
            errorMessage = (error as? APIError)?.message ?? "登录失败，请重试"
            return false
        }
    }

    func logout() async {
        try? await api.logout()
        user = nil
        state = AppState()
        phase = .auth
    }

    func deleteAccount(password: String) async -> Bool {
        do {
            try await api.deleteAccount(password: password)
            user = nil
            state = AppState()
            phase = .auth
            return true
        } catch {
            errorMessage = (error as? APIError)?.message ?? "删除失败，请重试"
            return false
        }
    }

    // MARK: Transactions
    @discardableResult
    func addTransaction(amount: Double, cat: String, note: String, kind: String, reflect: Reflect? = nil) async -> String {
        let label = note.isEmpty ? (CATS[cat]?.zh ?? "") : note
        let tx = Transaction(
            id: "tx" + UUID().uuidString.prefix(12).lowercased(),
            kind: kind,
            cat: cat,
            note: label,
            amount: amount,
            ts: ISO8601DateFormatter().string(from: Date()),
            reflect: reflect
        )
        state.transactions.insert(tx, at: 0)
        await save()
        return tx.id
    }

    // attach a reflection to an existing transaction (used by the optional post-save prompt)
    func setReflect(_ id: String, _ reflect: Reflect) {
        if let i = state.transactions.firstIndex(where: { $0.id == id }) {
            state.transactions[i].reflect = reflect
            Task { await save() }
        }
    }

    func deleteTransaction(_ id: String) async {
        state.transactions.removeAll { $0.id == id }
        await save()
    }

    // MARK: Progress (persisted into app_state, synced with the web app)
    func markGameComplete(_ id: String) {
        guard !state.gameProgress.contains(id) else { return }
        state.gameProgress.append(id)
        Task { await save() }
    }
    func setLessonDone(_ id: String, _ done: Bool) {
        if done {
            if !state.lessonProgress.contains(id) { state.lessonProgress.append(id) }
        } else {
            state.lessonProgress.removeAll { $0 == id }
        }
        Task { await save() }
    }
    func isGameDone(_ id: String) -> Bool { state.gameProgress.contains(id) }
    func isLessonDone(_ id: String) -> Bool { state.lessonProgress.contains(id) }

    // MARK: Profile
    var displayName: String {
        if case let .object(o)? = state.extras["userProfile"],
           case let .string(n)? = o["name"], !n.isEmpty { return n }
        return user?.nickname ?? "同学"
    }
    func updateNickname(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        user?.nickname = trimmed
        var prof: [String: JSONValue] = [:]
        if case let .object(o)? = state.extras["userProfile"] { prof = o }
        prof["name"] = .string(trimmed)
        state.extras["userProfile"] = .object(prof)   // matches the web (app_state.userProfile.name)
        Task { await save() }
    }
    func resetData() {
        state.transactions = []
        state.gameProgress = []
        state.lessonProgress = []
        state.challenges = []
        Task { await save() }
    }

    // MARK: Challenges (persisted into app_state.challenges, synced with the web)
    private var todayKey: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
    var activeChallenges: [ChallengeInstance] { state.challenges.filter { $0.status == "active" } }
    var completedChallenges: [ChallengeInstance] { state.challenges.filter { $0.status == "done" } }
    var recommendedDefs: [ChallengeDef] {
        let taken = Set(state.challenges.map { $0.defId })
        return ChallengeDefStore.all.filter { !taken.contains($0.id) }
    }
    var activeChallengeCount: Int { activeChallenges.count }
    func challengeCheckedToday(_ inst: ChallengeInstance) -> Bool { inst.checkDays.contains(todayKey) }

    func startChallenge(_ defId: String) {
        guard !state.challenges.contains(where: { $0.defId == defId && $0.status != "abandoned" }) else { return }
        var next = state
        next.challenges.append(ChallengeInstance(
            id: "ch" + UUID().uuidString.prefix(10).lowercased(),
            defId: defId, status: "active", startDay: todayKey, checkDays: []))
        state = next
        Task { await save() }
    }
    func checkInChallenge(_ instId: String) {
        let today = todayKey
        var next = state
        for i in next.challenges.indices where next.challenges[i].id == instId && next.challenges[i].status == "active" {
            if next.challenges[i].checkDays.contains(today) { return }
            next.challenges[i].checkDays.append(today)
            let need = ChallengeDefStore.find(next.challenges[i].defId)?.days ?? 1
            if next.challenges[i].checkDays.count >= need { next.challenges[i].status = "done" }
        }
        state = next
        Task { await save() }
    }

    // MARK: Derived counts
    var storiesCompleted: Int { state.gameProgress.count }
    var lessonsCompleted: Int { state.lessonProgress.count }
    var codexUnlocked: Int { CodexStore.all.filter { state.gameProgress.contains($0.story ?? "") }.count }
    var outCount: Int { state.transactions.filter { $0.kind == "out" }.count }
    var recordDays: Int {
        Set(state.transactions.map { Int(parseTS($0.ts).timeIntervalSince1970 / 86400) }).count
    }

    // Best-effort persist to the backend (keeps local copy if offline).
    private func save() async {
        try? await api.saveState(state)
    }

    // Derived numbers
    var monthOut: Double {
        let now = Date()
        return state.transactions
            .filter { $0.kind == "out" && isSameMonth($0.ts, now) }
            .reduce(0) { $0 + $1.amount }
    }
    var todayOut: Double {
        state.transactions
            .filter { $0.kind == "out" && isToday($0.ts) }
            .reduce(0) { $0 + $1.amount }
    }
    var monthIn: Double {
        let now = Date()
        return state.transactions
            .filter { $0.kind == "in" && isSameMonth($0.ts, now) }
            .reduce(0) { $0 + $1.amount }
    }
    var monthNet: Double { monthIn - monthOut }
    var totalNet: Double {
        state.transactions.reduce(0) { $0 + ($1.kind == "in" ? $1.amount : -$1.amount) }
    }
}
