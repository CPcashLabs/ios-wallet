import SwiftUI

struct AdaptiveMetrics: Equatable {
    let horizontalPadding: CGFloat
    let cardCornerRadius: CGFloat
    let buttonHeight: CGFloat
    let listRowMinHeight: CGFloat
    let titleSize: CGFloat
    let bodySize: CGFloat
    let footnoteSize: CGFloat
    let maxContentWidth: CGFloat
}

extension AdaptiveMetrics {
    static let compact = AdaptiveMetrics(
        horizontalPadding: 12,
        cardCornerRadius: 12,
        buttonHeight: 46,
        listRowMinHeight: 52,
        titleSize: 16,
        bodySize: 13,
        footnoteSize: 12,
        maxContentWidth: 360
    )

    static let regular = AdaptiveMetrics(
        horizontalPadding: 16,
        cardCornerRadius: 14,
        buttonHeight: 48,
        listRowMinHeight: 54,
        titleSize: 17,
        bodySize: 14,
        footnoteSize: 12,
        maxContentWidth: 390
    )

    static let plus = AdaptiveMetrics(
        horizontalPadding: 18,
        cardCornerRadius: 16,
        buttonHeight: 50,
        listRowMinHeight: 56,
        titleSize: 18,
        bodySize: 15,
        footnoteSize: 13,
        maxContentWidth: 460
    )

    static let max = AdaptiveMetrics(
        horizontalPadding: 20,
        cardCornerRadius: 18,
        buttonHeight: 52,
        listRowMinHeight: 58,
        titleSize: 19,
        bodySize: 15,
        footnoteSize: 13,
        maxContentWidth: 820
    )
}
