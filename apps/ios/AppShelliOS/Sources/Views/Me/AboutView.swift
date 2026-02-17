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

                    Text("版本 0.1.0")
                        .font(.system(size: 13))
                        .foregroundStyle(ThemeTokens.secondary)

                    SectionCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("CPCash 是面向跨链转账场景的钱包应用。本页面用于展示基础信息与支持入口。")
                                .font(.system(size: 14))
                                .foregroundStyle(ThemeTokens.secondary)
                            Text("官网：https://cp.cash")
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
        .navigationTitle("关于")
        .navigationBarTitleDisplayMode(.inline)
    }
}
