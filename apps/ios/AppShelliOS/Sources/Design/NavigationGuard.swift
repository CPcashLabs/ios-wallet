import Foundation

@MainActor
final class NavigationGuard: ObservableObject {
    private var lastTriggerAt: [String: Date] = [:]

    func allow(_ key: String, cooldown: TimeInterval = 0.45) -> Bool {
        let now = Date()
        if let last = lastTriggerAt[key], now.timeIntervalSince(last) < cooldown {
            return false
        }
        lastTriggerAt[key] = now
        return true
    }

    func reset(_ key: String? = nil) {
        if let key {
            lastTriggerAt[key] = nil
        } else {
            lastTriggerAt.removeAll()
        }
    }
}
