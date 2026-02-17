import SwiftUI

struct EmptyStateView: View {
    let asset: String
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 10) {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: 110, height: 80)
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(ThemeTokens.secondary)
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(ThemeTokens.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }
}
