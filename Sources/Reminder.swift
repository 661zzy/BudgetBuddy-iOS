import Foundation
import SwiftUI
import UserNotifications

// v1.5.3: an opt-in daily nudge ("today's story"). Local notification only —
// no server, no APNs, nothing leaves the device. Off by default; the user turns
// it on from 我的 or from the card shown after finishing a story, and can turn
// it off in the same place.
enum BBReminder {
    static let enabledKey = "bb.reminder.enabled"
    static let hourKey = "bb.reminder.hour"
    static let offeredKey = "bb.reminder.offered.v1"
    static let notifId = "bb.daily.story"
    static let defaultHour = 20

    static var enabled: Bool { UserDefaults.standard.bool(forKey: enabledKey) }
    static var hour: Int {
        let h = UserDefaults.standard.integer(forKey: hourKey)
        return (1...23).contains(h) ? h : defaultHour
    }
    static var offered: Bool { UserDefaults.standard.bool(forKey: offeredKey) }
    static func markOffered() { UserDefaults.standard.set(true, forKey: offeredKey) }

    /// Turn on: asks permission the first time, then schedules. `completion`
    /// reports whether it actually stuck (false = permission denied).
    static func enable(hour h: Int = BBReminder.hour, completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                guard granted else {
                    UserDefaults.standard.set(false, forKey: enabledKey)
                    completion(false); return
                }
                UserDefaults.standard.set(true, forKey: enabledKey)
                UserDefaults.standard.set(h, forKey: hourKey)
                schedule(hour: h)
                completion(true)
            }
        }
    }

    static func disable() {
        UserDefaults.standard.set(false, forKey: enabledKey)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notifId])
    }

    /// Re-issue the pending request (idempotent). Called on foreground so a
    /// language switch or a revoked permission never leaves a stale schedule.
    static func resync() {
        guard enabled else { return }
        UNUserNotificationCenter.current().getNotificationSettings { s in
            DispatchQueue.main.async {
                switch s.authorizationStatus {
                case .authorized, .provisional, .ephemeral: schedule(hour: hour)
                default: UserDefaults.standard.set(false, forKey: enabledKey)
                }
            }
        }
    }

    private static func schedule(hour h: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notifId])
        let content = UNMutableNotificationContent()
        content.title = "今天的故事等你来选".tr
        content.body = "三分钟，做一个不花真钱的选择。".tr
        content.sound = .default
        var dc = DateComponents(); dc.hour = h; dc.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        center.add(UNNotificationRequest(identifier: notifId, content: content, trigger: trigger))
    }
}

// The 我的 row. Styled like ProfileView.rowLabel, with a switch instead of a chevron.
struct ReminderToggleRow: View {
    @State private var on = BBReminder.enabled
    @State private var denied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 13) {
                Image(systemName: "bell").font(.system(size: 18)).foregroundColor(.bbInk2).frame(width: 24)
                Text("每日故事提醒".tr).foregroundColor(.bbInk)
                Spacer(minLength: 0)
                if on { Text("每天 20:00".tr).font(.caption).foregroundColor(.bbInk2) }
                Toggle("", isOn: $on).labelsHidden().tint(.bbGreen)
                    .accessibilityIdentifier("profile.reminder")
            }
            if denied {
                Text("通知权限已关闭，请到系统设置里允许".tr)
                    .font(.caption2).foregroundColor(.bbRed).padding(.leading, 37)
            }
        }
        .padding(.vertical, 11).padding(.horizontal, 2)
        .overlay(Rectangle().fill(Color.bbLine).frame(height: 1), alignment: .bottom)
        .onChange(of: on) { v in
            if v {
                BBReminder.enable { ok in
                    denied = !ok
                    if !ok { on = false }
                }
            } else {
                denied = false
                BBReminder.disable()
            }
        }
    }
}
