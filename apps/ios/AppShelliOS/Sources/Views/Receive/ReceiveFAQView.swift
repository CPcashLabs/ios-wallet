import SwiftUI

struct ReceiveFAQView: View {
    var body: some View {
        SafeAreaScreen(backgroundStyle: .globalImage) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    faqCard(question: "什么是收款地址有效期？", answer: "有效期内的地址可用于收款。地址失效后需要重新生成，避免过期资金流向错误。")
                    faqCard(question: "个人与经营模式有什么区别？", answer: "个人模式适合临时收款，经营模式适合长期固定收款。")
                    faqCard(question: "为什么只支持 BTT 网络资产？", answer: "当前 iOS MVP 与后端联调范围仅覆盖 BTT/BTT_TEST。")
                }
                .padding(16)
            }
        }
        .navigationTitle("收款 FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func faqCard(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(ThemeTokens.title)
            Text(answer)
                .font(.system(size: 13))
                .foregroundStyle(ThemeTokens.secondary)
        }
        .padding(14)
        .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
