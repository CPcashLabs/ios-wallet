import SwiftUI

struct MePlaceholderView: View {
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "hammer")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(ThemeTokens.cpPrimary)
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(ThemeTokens.title)
            Text(description)
                .font(.system(size: 13))
                .foregroundStyle(ThemeTokens.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
