import SwiftUI

struct ReceiveBusinessStartView: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("经营收款地址尚未创建")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(ThemeTokens.title)
            Text("创建后可长期收款，并支持地址失效管理")
                .font(.system(size: 12))
                .foregroundStyle(ThemeTokens.secondary)
                .multilineTextAlignment(.center)

            Button("开始创建") {
                onStart()
            }
            .font(.system(size: 14, weight: .semibold))
            .frame(maxWidth: .infinity, minHeight: 40)
            .foregroundStyle(.white)
            .background(ThemeTokens.cpPrimary, in: RoundedRectangle(cornerRadius: 20))
        }
        .padding(16)
        .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
