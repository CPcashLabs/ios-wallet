import SwiftUI

struct ContentView: View {
    @StateObject private var state = AppState()
    @AppStorage("settings.darkMode") private var darkMode = false

    var body: some View {
        ZStack(alignment: .top) {
            GlobalFullscreenBackground()

            Group {
                switch state.rootScreen {
                case .login:
                    LoginView(state: state)
                case .home:
                    HomeShellView(state: state)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            ToastView(toast: state.toast)
                .padding(.top, 8)
                .padding(.horizontal, 16)
        }
        .task {
            state.boot()
        }
        .preferredColorScheme(darkMode ? .dark : .light)
    }
}
