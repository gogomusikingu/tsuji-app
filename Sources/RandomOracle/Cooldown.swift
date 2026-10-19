import Foundation

/// Enforces "no second draw": the book opens once a day. The rest of the day is for
/// going back over that one verse in writing.
struct Cooldown {
    static let defaultInterval: TimeInterval = 24 * 60 * 60

    let interval: TimeInterval
    let defaults: UserDefaults
    private let key = "lastDrawAt"

    init(defaults: UserDefaults = .standard, interval: TimeInterval? = nil) {
        self.defaults = defaults
        // Override for testing, e.g. RANDOM_ORACLE_COOLDOWN=10 swift run
        let env = ProcessInfo.processInfo.environment["RANDOM_ORACLE_COOLDOWN"].flatMap(TimeInterval.init)
        self.interval = interval ?? env ?? Self.defaultInterval
    }

    func remaining(now: Date = Date()) -> TimeInterval {
        guard let last = defaults.object(forKey: key) as? Date else { return 0 }
        return max(0, interval - now.timeIntervalSince(last))
    }

    func markDrawn(now: Date = Date()) { defaults.set(now, forKey: key) }

    static func format(_ seconds: TimeInterval) -> String {
        let s = Int(seconds.rounded(.up))
        return String(format: "%d:%02d:%02d", s / 3600, s % 3600 / 60, s % 60)
    }
}
