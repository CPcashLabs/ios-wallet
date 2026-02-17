import Foundation

enum AddressFormatter {
    static func shortened(_ value: String, leading: Int = 6, trailing: Int = 4, threshold: Int = 12) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > threshold else { return trimmed }
        guard leading > 0, trailing > 0 else { return trimmed }
        guard trimmed.count > (leading + trailing) else { return trimmed }
        return "\(trimmed.prefix(leading))...\(trimmed.suffix(trailing))"
    }
}
