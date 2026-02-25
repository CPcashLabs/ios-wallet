import SwiftUI

struct AboutView: View {
    var body: some View {
        SafeAreaScreen(backgroundStyle: .globalImage) {
            ScrollView {
                VStack(spacing: 14) {
                    Image("me_about")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .padding(.top, 20)

                    Text("CPcash Wallet")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(ThemeTokens.title)

                    Text("Version 0.1.0")
                        .font(.system(size: 13))
                        .foregroundStyle(ThemeTokens.secondary)

                    SectionCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("CPCash is a wallet app for cross-chain transfer scenarios. This page shows basic information and support entry points.")
                                .font(.system(size: 14))
                                .foregroundStyle(ThemeTokens.secondary)
                            Text("Website: https://cp.cash")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(ThemeTokens.title)
                        }
                        .padding(14)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
