#if canImport(SwiftUI)
import SwiftUI

public typealias ModuleView = AnyView
#else
public struct ModuleView: CustomStringConvertible, Sendable {
    public let description: String

    public init(_ description: String) {
        self.description = description
    }
}
#endif
