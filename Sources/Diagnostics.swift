import Foundation
import UIKit

// Lightweight in-app diagnostics: a rolling log of API calls / errors + an uncaught-exception
// catcher. The 问题反馈 screen assembles these into a shareable report so a user can send a
// problem for debugging. (Full crash symbolication still comes from TestFlight / App Store Connect.)

final class DiagLog {
    static let shared = DiagLog()
    private let lock = NSLock()
    private var lines: [String] = []
    private let maxLines = 250
    private let fmt: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MM-dd HH:mm:ss"
        return f
    }()

    func log(_ msg: String) {
        let line = "[\(fmt.string(from: Date()))] \(msg)"
        lock.lock()
        lines.append(line)
        if lines.count > maxLines { lines.removeFirst(lines.count - maxLines) }
        lock.unlock()
    }
    func recent() -> String { lock.lock(); defer { lock.unlock() }; return lines.joined(separator: "\n") }
    func clear() { lock.lock(); lines.removeAll(); lock.unlock() }
}

private func budgetBuddyUncaughtExceptionHandler(_ exception: NSException) {
    let crash = "崩溃: \(exception.name.rawValue)\n原因: \(exception.reason ?? "—")\n"
        + exception.callStackSymbols.prefix(24).joined(separator: "\n")
    let report = crash + "\n\n--- 崩溃前日志 ---\n" + DiagLog.shared.recent()
    try? report.write(to: Diagnostics.crashFileURL, atomically: true, encoding: .utf8)
}

enum Diagnostics {
    static var crashFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("bb_last_crash.txt")
    }

    // Call once at app launch.
    static func start() {
        DiagLog.shared.log("启动 · v\(appVersion()) · \(deviceLine())")
        NSSetUncaughtExceptionHandler(budgetBuddyUncaughtExceptionHandler)
    }

    static func lastCrash() -> String? {
        guard let s = try? String(contentsOf: crashFileURL, encoding: .utf8), !s.isEmpty else { return nil }
        return s
    }
    static func clearLastCrash() { try? FileManager.default.removeItem(at: crashFileURL) }

    static func appVersion() -> String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }
    static func deviceLine() -> String { "\(deviceModel()) · iOS \(UIDevice.current.systemVersion)" }
    static func deviceModel() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        return withUnsafePointer(to: &sysinfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }
    }
}
