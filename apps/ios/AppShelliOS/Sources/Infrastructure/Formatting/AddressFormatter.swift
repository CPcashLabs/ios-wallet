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

enum AddressInputParser {
    static func sanitize(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func normalizeScannedAddress(
        _ raw: String,
        isPotentialAddress: (String) -> Bool
    ) -> String {
        let compact = sanitize(raw)
        guard !compact.isEmpty else { return "" }

        if let queryStart = compact.firstIndex(of: "?"),
           let parsed = URLComponents(string: String(compact[..<queryStart])),
           let addressFromPath = parsed.path.split(separator: "/").last
        {
            let candidate = sanitize(String(addressFromPath))
            if isPotentialAddress(candidate) {
                return candidate
            }
        }

        if let components = URLComponents(string: compact), let queryItems = components.queryItems,
           let addressQuery = queryItems.first(where: { $0.name.lowercased() == "address" })?.value
        {
            let candidate = sanitize(addressQuery)
            if isPotentialAddress(candidate) {
                return candidate
            }
        }

        if let evm = compact.range(of: "(0x|0X)[a-fA-F0-9]{40}", options: .regularExpression) {
            return sanitize(String(compact[evm]))
        }
        if let tron = compact.range(of: "T[a-zA-Z0-9]{33}", options: .regularExpression) {
            return sanitize(String(compact[tron]))
        }

        var value = compact
        if let schemeRange = value.range(of: "ethereum:", options: [.caseInsensitive, .anchored]) {
            value = String(value[schemeRange.upperBound...])
        } else if let schemeRange = value.range(of: "tron:", options: [.caseInsensitive, .anchored]) {
            value = String(value[schemeRange.upperBound...])
        }
        if let queryIndex = value.firstIndex(of: "?") {
            value = String(value[..<queryIndex])
        }
        if let chainIndex = value.firstIndex(of: "@") {
            value = String(value[..<chainIndex])
        }
        return sanitize(value)
    }
}
