import SwiftUI

struct SafeAreaScreen<Content: View, BottomInset: View>: View {
    let backgroundStyle: FullscreenBackgroundStyle
    @ViewBuilder let content: () -> Content
    let bottomInset: (() -> BottomInset)?

    init(
        backgroundStyle: FullscreenBackgroundStyle = .globalImage,
        @ViewBuilder content: @escaping () -> Content
    ) where BottomInset == EmptyView {
        self.backgroundStyle = backgroundStyle
        self.content = content
        bottomInset = nil
    }

    init(
        backgroundStyle: FullscreenBackgroundStyle = .globalImage,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder bottomInset: @escaping () -> BottomInset
    ) {
        self.backgroundStyle = backgroundStyle
        self.content = content
        self.bottomInset = bottomInset
    }

    var body: some View {
        let scaffold = FullscreenScaffold(backgroundStyle: backgroundStyle) {
            content()
        }

        if let bottomInset {
            scaffold
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    bottomInset()
                }
        } else {
            scaffold
        }
    }
}
