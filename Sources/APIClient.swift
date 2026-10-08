import Foundation

struct APIError: Error, LocalizedError {
    let code: String
    let message: String
    var errorDescription: String? { message }
}

// Type-erases any Encodable so we can take an optional body parameter.
struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void
    init(_ wrapped: Encodable) { encodeFunc = { try wrapped.encode(to: $0) } }
    func encode(to encoder: Encoder) throws { try encodeFunc(encoder) }
}

// Talks to the existing PHP backend. Auth is the PHP session cookie — URLSession
// stores/sends it automatically (this is why native works where WKWebView didn't).
final class APIClient {
    static let shared = APIClient()

    private let base = "https://budgetbuddy.cn/api.php?r="
    private let session: URLSession

    private let sessionKey = "bb_session_cookie"

    private init() {
        let cfg = URLSessionConfiguration.default
        cfg.httpCookieStorage = HTTPCookieStorage.shared
        cfg.httpCookieAcceptPolicy = .always
        cfg.httpShouldSetCookies = true
        cfg.timeoutIntervalForRequest = 20
        session = URLSession(configuration: cfg)
        restoreSessionCookie()   // stay logged in across app launches
    }

    // PHP's session cookie is session-scoped (dropped on app quit). Persist its
    // value so the user stays logged in across launches while the server session
    // is still valid. (For a long-lived "remember me", switch to a token later.)
    private func saveSessionCookie() {
        guard let url = URL(string: "https://budgetbuddy.cn"),
              let c = HTTPCookieStorage.shared.cookies(for: url)?.first(where: { $0.name == "bb_session" })
        else { return }
        Keychain.set(c.value, for: sessionKey)
    }

    private func restoreSessionCookie() {
        var stored = Keychain.get(sessionKey)
        if stored == nil, let legacy = UserDefaults.standard.string(forKey: sessionKey), !legacy.isEmpty {
            // One-time migration (v1.5.3): sessions used to be kept in UserDefaults.
            Keychain.set(legacy, for: sessionKey)
            UserDefaults.standard.removeObject(forKey: sessionKey)
            stored = legacy
        }
        guard let value = stored, !value.isEmpty else { return }
        let props: [HTTPCookiePropertyKey: Any] = [
            .name: "bb_session",
            .value: value,
            .domain: "budgetbuddy.cn",
            .path: "/",
            .secure: "TRUE",
            .expires: Date(timeIntervalSinceNow: 60 * 60 * 24 * 30)
        ]
        if let cookie = HTTPCookie(properties: props) {
            HTTPCookieStorage.shared.setCookie(cookie)
        }
    }

    func clearSessionCookie() {
        Keychain.delete(sessionKey)
        UserDefaults.standard.removeObject(forKey: sessionKey)   // legacy slot
        if let url = URL(string: "https://budgetbuddy.cn") {
            HTTPCookieStorage.shared.cookies(for: url)?
                .filter { $0.name == "bb_session" }
                .forEach { HTTPCookieStorage.shared.deleteCookie($0) }
        }
    }

    private func request<T: Decodable>(_ method: String,
                                       _ path: String,
                                       body: Encodable? = nil,
                                       timeout: TimeInterval? = nil,
                                       decode: T.Type) async throws -> T {
        guard let url = URL(string: base + path) else {
            throw APIError(code: "BAD_URL", message: "无效地址")
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let timeout = timeout { req.timeoutInterval = timeout }   // AI needs more headroom than the 20s default
        if let body = body {
            req.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }

        let data: Data
        let resp: URLResponse
        do {
            (data, resp) = try await session.data(for: req)
        } catch {
            DiagLog.shared.log("API \(method) \(path) ✗ 网络错误")
            throw APIError(code: "NETWORK", message: "无法连接服务器，请检查网络")
        }

        let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            DiagLog.shared.log("API \(method) \(path) ✗ HTTP \(status)")
            if let e = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw APIError(code: e.error.code, message: e.error.message)
            }
            throw APIError(code: "HTTP_\(status)", message: "请求失败".tr + " (\(status))")
        }
        do {
            let value = try JSONDecoder().decode(T.self, from: data)
            DiagLog.shared.log("API \(method) \(path) → \(status)")
            return value
        } catch {
            DiagLog.shared.log("API \(method) \(path) ✗ 解析失败")
            throw APIError(code: "DECODE", message: "数据解析失败")
        }
    }

    // MARK: Auth
    func register(identifier: String, password: String, nickname: String, ageGroup: String, code: String) async throws -> User {
        struct Req: Encodable { let identifier, password, nickname, ageGroup, code: String }
        let r: UserResponse = try await request("POST", "/auth/register",
            body: Req(identifier: identifier, password: password, nickname: nickname, ageGroup: ageGroup, code: code),
            decode: UserResponse.self)
        guard let u = r.user else { throw APIError(code: "NO_USER", message: "注册失败") }
        saveSessionCookie()
        return u
    }

    // Verification code for register / password-reset (delivered by email or SMS server-side).
    func sendCode(identifier: String, purpose: String) async throws -> SendCodeResult {
        struct Req: Encodable { let identifier, purpose: String }
        return try await request("POST", "/auth/send-code",
            body: Req(identifier: identifier, purpose: purpose),
            decode: SendCodeResult.self)
    }

    func resetPassword(identifier: String, code: String, password: String) async throws -> User {
        struct Req: Encodable { let identifier, code, password: String }
        let r: UserResponse = try await request("POST", "/auth/reset-password",
            body: Req(identifier: identifier, code: code, password: password),
            decode: UserResponse.self)
        guard let u = r.user else { throw APIError(code: "NO_USER", message: "重置失败") }
        saveSessionCookie()
        return u
    }

    func login(identifier: String, password: String) async throws -> User {
        struct Req: Encodable { let identifier, password: String }
        let r: UserResponse = try await request("POST", "/auth/login",
            body: Req(identifier: identifier, password: password),
            decode: UserResponse.self)
        guard let u = r.user else { throw APIError(code: "NO_USER", message: "登录失败") }
        saveSessionCookie()
        return u
    }

    func logout() async throws {
        defer { clearSessionCookie() }
        _ = try await request("POST", "/auth/logout", decode: OkResponse.self)
    }

    func deleteAccount(password: String) async throws {
        struct Req: Encodable { let password: String }
        _ = try await request("POST", "/auth/delete", body: Req(password: password), decode: OkResponse.self)
        clearSessionCookie()
    }

    func me() async throws -> User? {
        try await request("GET", "/auth/me", decode: UserResponse.self).user
    }

    // MARK: Feedback (guest-friendly one-tap submission; server rate-limits by IP)
    // images: up to 3 base64 JPEGs (no data: prefix). Older servers ignore the
    // field, so a client that sends screenshots still submits fine against them.
    // v1.6.2: also sends the platform and, for guests only, this device's feedback key so
    // replies can find their way back (backend 4.9). Feedback sent while signed in belongs to
    // the account alone — tying it to the device would let the next person on this phone
    // read it after sign-out. Older servers ignore both fields.
    func sendFeedback(message: String, diagnostics: String, images: [String] = [], clientKey: String?) async throws {
        struct Req: Encodable { let message, diagnostics: String; let images: [String]; let clientKey: String?; let platform: String }
        _ = try await request("POST", "/feedback",
                              body: Req(message: message, diagnostics: diagnostics, images: images,
                                        clientKey: clientKey, platform: "ios"),
                              decode: FeedbackSubmitResponse.self)
    }

    // Replies to feedback. POST so the device key stays out of URLs and logs.
    func feedbackThreads(clientKey: String?) async throws -> FeedbackThreadsResponse {
        struct Req: Encodable { let clientKey: String? }
        return try await request("POST", "/feedback/threads", body: Req(clientKey: clientKey),
                                 decode: FeedbackThreadsResponse.self)
    }

    func markFeedbackRead(id: Int, clientKey: String?) async throws {
        struct Req: Encodable { let id: Int; let clientKey: String? }
        _ = try await request("POST", "/feedback/read", body: Req(id: id, clientKey: clientKey), decode: OkResponse.self)
    }

    func sendFeedbackReply(id: Int, message: String, clientKey: String?) async throws -> FeedbackThread {
        struct Req: Encodable { let id: Int; let message: String; let clientKey: String? }
        return try await request("POST", "/feedback/reply", body: Req(id: id, message: message, clientKey: clientKey),
                                 decode: FeedbackReplyResponse.self).thread
    }

    // MARK: State
    func loadState() async throws -> AppState {
        try await request("GET", "/state", decode: StateResponse.self).appState
    }

    func saveState(_ state: AppState) async throws {
        struct Req: Encodable { let appState: AppState }
        _ = try await request("PUT", "/state", body: Req(appState: state), decode: OkResponse.self)
    }

    // MARK: AI
    // The upstream provider is usually ~3s but occasionally returns a fast canned
    // fallback (source=="fallback") or spikes past the 20s default. Give AI calls 45s of
    // headroom and retry up to twice on a transient network/5xx/fallback result — the
    // jitter is intermittent, so a 2nd or 3rd try almost always lands a real answer. Only
    // after all attempts fail do we surface an error, so callers can show an honest
    // "AI 忙，请重试" message instead of passing canned text off as a real AI answer.
    func aiChat(_ message: String) async throws -> String {
        struct Req: Encodable { let message: String; let context: [String: String] }
        var lastError: Error = APIError(code: "AI_BUSY", message: "AI 暂时繁忙，请稍后再试")
        let maxAttempts = 3
        for attempt in 0..<maxAttempts {
            let isLast = attempt == maxAttempts - 1
            do {
                let r = try await request("POST", "/ai/chat",
                    body: Req(message: message, context: [:]),
                    timeout: 45,
                    decode: AIResponse.self)
                if r.source == "fallback" {
                    lastError = APIError(code: "AI_FALLBACK", message: "AI 暂时繁忙，请稍后再试")
                    if isLast { throw lastError }
                    try? await Task.sleep(nanoseconds: 600_000_000); continue
                }
                return r.reply
            } catch let e as APIError where e.code == "NETWORK" || e.code.hasPrefix("HTTP_5") {
                lastError = e
                if isLast { throw e }
                try? await Task.sleep(nanoseconds: 600_000_000)
            }
        }
        throw lastError
    }

    // MARK: Update check — static version.json at the web root (no auth, no cookie)
    func appVersion() async throws -> AppVersionInfo {
        guard let url = URL(string: "https://budgetbuddy.cn/version.json") else {
            throw APIError(code: "BAD_URL", message: "无效地址")
        }
        var req = URLRequest(url: url)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, _) = try await session.data(for: req)
        return try JSONDecoder().decode(AppVersionInfo.self, from: data)
    }
}
