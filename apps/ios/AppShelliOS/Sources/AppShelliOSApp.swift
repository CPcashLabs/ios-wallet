import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@main
struct AppShelliOSApp: App {
    init() {
        configureNavigationBarAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    private func configureNavigationBarAppearance() {
        #if canImport(UIKit)
        let background = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.09, green: 0.10, blue: 0.12, alpha: 1)
                : UIColor(red: 246 / 255, green: 247 / 255, blue: 249 / 255, alpha: 1)
        }
        let titleColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.92)
                : UIColor.black.withAlphaComponent(0.82)
        }
        let tintColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.92)
                : UIColor.black.withAlphaComponent(0.82)
        }

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = background
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: titleColor]
        appearance.largeTitleTextAttributes = [.foregroundColor: titleColor]

        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        navBar.compactAppearance = appearance
        navBar.compactScrollEdgeAppearance = appearance
        navBar.tintColor = tintColor
        #endif
    }
}
