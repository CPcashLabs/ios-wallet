import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum DeviceWidthClass {
    case compact
    case regular
    case plus
    case max

    init(width: CGFloat) {
        if width <= 375 {
            self = .compact
        } else if width <= 414 {
            self = .regular
        } else if width <= 430 {
            self = .plus
        } else {
            self = .max
        }
    }

    var horizontalPadding: CGFloat {
        metrics.horizontalPadding
    }

    var titleSize: CGFloat {
        metrics.titleSize
    }

    var bodySize: CGFloat {
        metrics.bodySize
    }

    var footnoteSize: CGFloat {
        metrics.footnoteSize
    }

    var metrics: AdaptiveMetrics {
        switch self {
        case .compact:
            return .compact
        case .regular:
            return .regular
        case .plus:
            return .plus
        case .max:
            return .max
        }
    }
}

struct AdaptiveReader<Content: View>: View {
    let content: (DeviceWidthClass) -> Content

    var body: some View {
        GeometryReader { proxy in
            let widthClass = DeviceWidthClass(width: proxy.size.width)
            let constrainedWidth = resolvedMaxWidth(for: widthClass, containerWidth: proxy.size.width)
            content(widthClass)
                .frame(maxWidth: constrainedWidth, maxHeight: .infinity, alignment: .top)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private func resolvedMaxWidth(for widthClass: DeviceWidthClass, containerWidth: CGFloat) -> CGFloat? {
        #if canImport(UIKit)
        if UIDevice.current.userInterfaceIdiom == .phone {
            return nil
        }
        #endif
        return min(widthClass.metrics.maxContentWidth, containerWidth)
    }
}
