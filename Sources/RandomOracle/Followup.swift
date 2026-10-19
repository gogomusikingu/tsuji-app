import Foundation
import UserNotifications

/// "What happened afterwards?" — a local reminder a few days after opening the book.
/// iPhone only; the Mac prototype runs without an app bundle, which notifications require.
enum Followup {
    static let defaultDelay: TimeInterval = 3 * 24 * 60 * 60

    static func schedule(for entry: JournalEntry, lang: AppLanguage) {
        #if os(iOS)
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let l = L10n(lang: lang)
            let content = UNMutableNotificationContent()
            content.title = l.followupTitle
            content.body = l.followupBody
            // Override for testing, e.g. TSUJI_FOLLOWUP_SECONDS=10
            let delay = ProcessInfo.processInfo.environment["TSUJI_FOLLOWUP_SECONDS"].flatMap(TimeInterval.init) ?? defaultDelay
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            center.add(UNNotificationRequest(identifier: entry.id.uuidString, content: content, trigger: trigger))
        }
        #endif
    }
}
