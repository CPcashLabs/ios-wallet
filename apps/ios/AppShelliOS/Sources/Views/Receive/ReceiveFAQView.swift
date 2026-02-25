import SwiftUI

struct ReceiveFAQView: View {
    var body: some View {
        SafeAreaScreen(backgroundStyle: .globalImage) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    faqCard(question: "What is the validity period of a receiving address?", answer: "Addresses can receive funds within their validity period. After expiration, regenerate the address to avoid incorrect fund routing.")
                    faqCard(question: "What is the difference between personal and business modes?", answer: "Personal mode is for temporary receiving, business mode is for long-term fixed receiving.")
                    faqCard(question: "Why are only BTT network assets supported?", answer: "The current iOS MVP integration scope only covers BTT/BTT_TEST.")
                }
                .padding(16)
            }
        }
        .navigationTitle("Receive FAQ")
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
