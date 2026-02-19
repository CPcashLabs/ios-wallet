import SwiftUI

struct ContentView: View {
    @StateObject private var appStore: AppStore
    @AppStorage("settings.darkMode") private var darkMode = false

    init() {
        if let store = UITestBootstrap.makeAppStore(arguments: ProcessInfo.processInfo.arguments) {
            _appStore = StateObject(wrappedValue: store)
        } else {
            _appStore = StateObject(wrappedValue: AppStore())
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            GlobalFullscreenBackground()

            Group {
                switch appStore.rootScreen {
                case .login:
                    LoginView(sessionStore: appStore.sessionStore, uiStore: appStore.uiStore)
                case .home:
                    HomeShellView(appStore: appStore)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            ToastView(toast: appStore.toast)
                .padding(.horizontal, 16)
        }
        .accessibilityIdentifier(A11yID.App.contentRoot)
        .task {
            appStore.boot()
        }
        .preferredColorScheme(darkMode ? .dark : .light)
    }
}
