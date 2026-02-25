import SwiftUI

struct ReceiveAddressEditView: View {
    @ObservedObject var receiveStore: ReceiveStore
    let orderSN: String

    @Environment(\.dismiss) private var dismiss
    @State private var submitting = false

    var body: some View {
        SafeAreaScreen(backgroundStyle: .globalImage) {
            VStack(spacing: 14) {
                SectionCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Address Settings")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(ThemeTokens.title)
                        Text("Order No.")
                            .font(.system(size: 12))
                            .foregroundStyle(ThemeTokens.secondary)
                        Text(orderSN)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(ThemeTokens.title)
                            .textSelection(.enabled)
                    }
                    .padding(14)
                }

                Text("After setting this address as default, new receipts will use it first.")
                    .font(.system(size: 13))
                    .foregroundStyle(ThemeTokens.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    submitting = true
                    Task {
                        await receiveStore.markTraceOrder(orderSN: orderSN)
                        submitting = false
                        dismiss()
                    }
                } label: {
                    Text(submitting ? "Submitting..." : "Set as default receive address")
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
        .navigationTitle("Edit Address")
        .navigationBarTitleDisplayMode(.inline)
    }
}
