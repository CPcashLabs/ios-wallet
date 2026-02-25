import Foundation

enum DateTextFormatter {
    private static let yearMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter
    }()

    private static let yearMonthDayMinuteFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()

    private static let yearMonthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let yearMonthDaySecondFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    static func yearMonth(fromTimestamp timestamp: Int?, fallback: String = "Unknown month") -> String {
        guard let date = date(fromTimestamp: timestamp) else { return fallback }
        return yearMonthFormatter.string(from: date)
    }

    static func yearMonthDayMinute(fromTimestamp timestamp: Int?, fallback: String = "-") -> String {
        guard let date = date(fromTimestamp: timestamp) else { return fallback }
        return yearMonthDayMinuteFormatter.string(from: date)
    }

    static func yearMonthDay(fromTimestamp timestamp: Int?, fallback: String = "-") -> String {
        guard let date = date(fromTimestamp: timestamp) else { return fallback }
        return yearMonthDayFormatter.string(from: date)
    }

    static func yearMonthDaySecond(fromTimestamp timestamp: Int?, fallback: String = "-") -> String {
        guard let date = date(fromTimestamp: timestamp) else { return fallback }
        return yearMonthDaySecondFormatter.string(from: date)
    }

    static func date(fromTimestamp timestamp: Int?) -> Date? {
        guard let timestamp else { return nil }
        let seconds: TimeInterval = timestamp > 1_000_000_000_000
            ? TimeInterval(timestamp) / 1000
            : TimeInterval(timestamp)
        return Date(timeIntervalSince1970: seconds)
    }
}
