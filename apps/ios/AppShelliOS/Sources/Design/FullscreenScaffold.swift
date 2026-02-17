import SwiftUI

enum FullscreenBackgroundStyle {
    case globalImage
    case solid(Color)
}

struct FullscreenScaffold<Content: View>: View {
    let backgroundStyle: FullscreenBackgroundStyle
    let hideNavigationBar: Bool
    @ViewBuilder let content: () -> Content

    init(
        backgroundStyle: FullscreenBackgroundStyle = .globalImage,
        hideNavigationBar: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.backgroundStyle = backgroundStyle
        self.hideNavigationBar = hideNavigationBar
        self.content = content
    }

    init(
        background: Color,
        hideNavigationBar: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        backgroundStyle = .solid(background)
        self.hideNavigationBar = hideNavigationBar
        self.content = content
    }

    var body: some View {
        ZStack {
            backgroundLayer

            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .modifier(FullscreenNavigationModifier(hideNavigationBar: hideNavigationBar))
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        switch backgroundStyle {
        case .globalImage:
            GlobalFullscreenBackground()
        case let .solid(color):
            color.ignoresSafeArea(.all)
        }
    }
}

private struct FullscreenNavigationModifier: ViewModifier {
    let hideNavigationBar: Bool

    func body(content: Content) -> some View {
        if hideNavigationBar {
            content
                .toolbar(.hidden, for: .navigationBar)
        } else {
            content
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(ThemeTokens.groupBackground, for: .navigationBar)
        }
    }
}
