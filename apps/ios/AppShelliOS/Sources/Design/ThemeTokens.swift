import SwiftUI
import UIKit

enum ThemeTokens {
    static let cpPrimary = Color(red: 22 / 255, green: 119 / 255, blue: 1)
    static let cpGold = Color(red: 238 / 255, green: 184 / 255, blue: 36 / 255)
    static let pageBackground = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.07, green: 0.08, blue: 0.10, alpha: 1)
            : UIColor(red: 243 / 255, green: 243 / 255, blue: 243 / 255, alpha: 1)
    })
    static let groupBackground = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.09, green: 0.10, blue: 0.12, alpha: 1)
            : UIColor(red: 246 / 255, green: 247 / 255, blue: 249 / 255, alpha: 1)
    })
    static let cardBackground = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(red: 0.12, green: 0.13, blue: 0.16, alpha: 1) : .white
    })
    static let elevatedCard = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(red: 0.15, green: 0.16, blue: 0.20, alpha: 1) : UIColor.white
    })
    static let softSurface = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.08)
            : UIColor.black.withAlphaComponent(0.04)
    })
    static let qrBackground = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(red: 0.18, green: 0.19, blue: 0.22, alpha: 1) : .white
    })
    static let homeTopGradient = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.15, blue: 0.24, alpha: 1)
            : UIColor(red: 210 / 255, green: 228 / 255, blue: 1, alpha: 1)
    })
    static let divider = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.10) : UIColor.black.withAlphaComponent(0.08)
    })
    static let title = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.92) : UIColor.black.withAlphaComponent(0.82)
    })
    static let secondary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.68) : UIColor.black.withAlphaComponent(0.55)
    })
    static let tertiary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.50) : UIColor.black.withAlphaComponent(0.4)
    })
    static let success = Color(red: 0.16, green: 0.72, blue: 0.39)
    static let warning = Color(red: 0.89, green: 0.45, blue: 0.09)
    static let danger = Color(red: 0.94, green: 0.29, blue: 0.25)
    static let inputBackground = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(red: 0.16, green: 0.17, blue: 0.20, alpha: 1) : .white
    })
}

extension Color {
    init(hex: String, fallback: Color = ThemeTokens.cpPrimary) {
        let value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        guard value.count == 6, let rgb = Int(value, radix: 16) else {
            self = fallback
            return
        }
        let red = Double((rgb >> 16) & 0xFF) / 255
        let green = Double((rgb >> 8) & 0xFF) / 255
        let blue = Double(rgb & 0xFF) / 255
        self = Color(red: red, green: green, blue: blue)
    }
}
