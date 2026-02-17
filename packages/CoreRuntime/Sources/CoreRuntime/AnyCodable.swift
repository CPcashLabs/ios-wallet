import Foundation

public struct AnyCodable: Codable, Hashable {
    public let value: AnyHashable

    public init<T: Hashable & Sendable>(_ value: T) {
        self.value = AnyHashable(value)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            self.value = AnyHashable(intValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self.value = AnyHashable(doubleValue)
        } else if let boolValue = try? container.decode(Bool.self) {
            self.value = AnyHashable(boolValue)
        } else if let stringValue = try? container.decode(String.self) {
            self.value = AnyHashable(stringValue)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported AnyCodable value"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value.base {
        case let v as Int:
            try container.encode(v)
        case let v as Double:
            try container.encode(v)
        case let v as Bool:
            try container.encode(v)
        case let v as String:
            try container.encode(v)
        default:
            let context = EncodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Unsupported AnyCodable value"
            )
            throw EncodingError.invalidValue(value, context)
        }
    }
}
