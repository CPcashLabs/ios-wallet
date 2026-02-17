import SwiftUI

struct ContentView: View {
    @StateObject private var appStore = AppStore()
    @AppStorage("settings.darkMode") private var darkMode = false

    var body: some View {
        ZStack(alignment: .top) {
            GlobalFullscreenBackground()

            Group {
                switch appStore.rootScreen {
                case .login:
                    LoginView(state: appStore.appState)
                case .home:
                    HomeShellView(appStore: appStore)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            ToastView(toast: appStore.toast)
                .padding(.top, 8)
                .padding(.horizontal, 16)
        }
        .task {
            appStore.boot()
        }
        .preferredColorScheme(darkMode ? .dark : .light)
    }
}
