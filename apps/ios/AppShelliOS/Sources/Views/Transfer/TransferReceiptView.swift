import SwiftUI

struct TransferReceiptView: View {
    @ObservedObject var transferStore: TransferStore
    let onDone: () -> Void
    let onViewOrder: (String) -> Void

    var body: some View {
        AdaptiveReader { widthClass in
            FullscreenScaffold(backgroundStyle: .globalImage) {
                VStack(spacing: 14) {
                    Spacer(minLength: 20)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 62))
                        .foregroundStyle(ThemeTokens.success)

                    Text("Payment successful")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(ThemeTokens.title)

                    infoCard(widthClass: widthClass)

                    Spacer()

                    VStack(spacing: 10) {
                        Button {
                            if let orderSN = transferStore.transferDraft.orderSN, !orderSN.isEmpty {
                                onViewOrder(orderSN)
                            } else {
                                transferStore.showInfoToast("Current transaction has no order number")
                            }
                        } label: {
                            Text("View Order")
                                .font(.system(size: widthClass.bodySize + 1, weight: .semibold))
                                .foregroundStyle(ThemeTokens.cpPrimary)
                                .frame(maxWidth: .infinity, minHeight: widthClass.metrics.buttonHeight)
                                .background(ThemeTokens.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: widthClass.metrics.buttonHeight / 2)
                                        .stroke(ThemeTokens.cpPrimary.opacity(0.5), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: widthClass.metrics.buttonHeight / 2))
                        }
                        .buttonStyle(.pressFeedback)

                        Button {
                            onDone()
                        } label: {
                            Text("Done")
                                .font(.system(size: widthClass.bodySize + 1, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: widthClass.metrics.buttonHeight)
                                .background(ThemeTokens.cpPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: widthClass.metrics.buttonHeight / 2))
                        }
                        .buttonStyle(.pressFeedback)
                        .accessibilityIdentifier(A11yID.Transfer.receiptDoneButton)
                    }
                    .padding(.horizontal, widthClass.horizontalPadding)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Transfer Receipt")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func infoCard(widthClass: DeviceWidthClass) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            row("TxHash", transferStore.lastTxHash)
            row("OrderSN", transferStore.transferDraft.orderSN ?? "-")
            row("Amount", "\(transferStore.transferDraft.amountText) \(transferStore.transferDomainState.selectedSendCoinName)")
            row("To", shortAddress(transferStore.transferDraft.recipientAddress))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: widthClass.metrics.cardCornerRadius, style: .continuous))
        .padding(.horizontal, widthClass.horizontalPadding)
    }

    private func row(_ name: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.system(size: 12))
                .foregroundStyle(ThemeTokens.secondary)
            Text(value)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(ThemeTokens.title)
                .lineLimit(2)
                .truncationMode(.middle)
                .textSelection(.enabled)
        }
    }

    private func shortAddress(_ value: String) -> String {
        AddressFormatter.shortened(value, leading: 8, trailing: 6, threshold: 14)
    }
}
