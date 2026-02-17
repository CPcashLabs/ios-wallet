import SwiftUI

struct TopSafeAreaHeaderScaffold<Header: View, Content: View>: View {
    let backgroundStyle: FullscreenBackgroundStyle
    let headerBackground: Color
    let headerHeight: CGFloat
    @ViewBuilder let header: () -> Header
    @ViewBuilder let content: () -> Content

    init(
        backgroundStyle: FullscreenBackgroundStyle = .globalImage,
        headerBackground: Color = ThemeTokens.groupBackground.opacity(0.96),
        headerHeight: CGFloat = 52,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.backgroundStyle = backgroundStyle
        self.headerBackground = headerBackground
        self.headerHeight = headerHeight
        self.header = header
        self.content = content
    }

    var body: some View {
        FullscreenScaffold(backgroundStyle: backgroundStyle, hideNavigationBar: true) {
            content()
                .safeAreaInset(edge: .top, spacing: 0) {
                    header()
                        .frame(maxWidth: .infinity, minHeight: headerHeight)
                        .padding(.horizontal, 16)
                        .background(headerBackground)
                }
        }
    }
}
