import SwiftUI

struct ToastView: View {
    let toast: ToastState?

    var body: some View {
        VStack {
            if let toast {
                HStack(spacing: 8) {
                    Image(systemName: iconName(for: toast.theme))
                        .font(.system(size: 14, weight: .semibold))
                    Text(toast.message)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(2)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(backgroundColor(for: toast.theme), in: Capsule())
                .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 4)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .animation(.easeInOut(duration: 0.2), value: toast?.id)
        .allowsHitTesting(false)
    }

    private func backgroundColor(for theme: ToastTheme) -> Color {
        switch theme {
        case .success:
            return Color.green.opacity(0.86)
        case .error:
            return Color.red.opacity(0.9)
        case .info:
            return ThemeTokens.cpPrimary.opacity(0.9)
        }
    }

    private func iconName(for theme: ToastTheme) -> String {
        switch theme {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.circle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
}
