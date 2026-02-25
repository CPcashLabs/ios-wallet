import SwiftUI

struct ReceiveBusinessStartView: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("Business receiving address has not been created")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(ThemeTokens.title)
            Text("After creation, you can receive long-term and manage address invalidation")
                .font(.system(size: 12))
                .foregroundStyle(ThemeTokens.secondary)
                .multilineTextAlignment(.center)

            Button("Start Creating") {
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
