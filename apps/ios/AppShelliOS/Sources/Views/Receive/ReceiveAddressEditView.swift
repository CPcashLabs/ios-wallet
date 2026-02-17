import SwiftUI

struct ReceiveAddressEditView: View {
    @ObservedObject var state: AppState
    let orderSN: String

    @Environment(\.dismiss) private var dismiss
    @State private var submitting = false

    var body: some View {
        SafeAreaScreen(backgroundStyle: .globalImage) {
            VStack(spacing: 14) {
                SectionCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("地址设置")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(ThemeTokens.title)
                        Text("订单号")
                            .font(.system(size: 12))
                            .foregroundStyle(ThemeTokens.secondary)
                        Text(orderSN)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(ThemeTokens.title)
                            .textSelection(.enabled)
                    }
                    .padding(14)
                }

                Text("将该地址设置为默认后，新收款会优先使用此地址。")
                    .font(.system(size: 13))
                    .foregroundStyle(ThemeTokens.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    submitting = true
                    Task {
                        await state.markTraceOrder(orderSN: orderSN)
                        submitting = false
                        dismiss()
                    }
                } label: {
                    Text(submitting ? "提交中..." : "设为默认收款地址")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .foregroundStyle(.white)
                        .background(ThemeTokens.cpPrimary, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
                .disabled(submitting)
                .opacity(submitting ? 0.65 : 1)

                Spacer()
            }
            .padding(16)
        }
        .navigationTitle("编辑地址")
        .navigationBarTitleDisplayMode(.inline)
    }
}
