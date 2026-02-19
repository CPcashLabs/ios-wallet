import SwiftUI

struct TransferConfirmView: View {
    @ObservedObject var transferStore: TransferStore
    let onSuccess: () -> Void

    @State private var lastTapAt: Date?

    var body: some View {
        AdaptiveReader { widthClass in
            SafeAreaScreen(backgroundStyle: .globalImage) {
                ScrollView {
                    VStack(spacing: 12) {
                        summaryCard(widthClass: widthClass)
                    }
                    .padding(.horizontal, widthClass.horizontalPadding)
                    .padding(.top, 14)
                    .padding(.bottom, 16)
                }
            } bottomInset: {
                bottomButton(widthClass: widthClass)
            }
            .navigationTitle("确认转账")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func summaryCard(widthClass: DeviceWidthClass) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Spacer()
                Text(totalAmountText)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(ThemeTokens.title)
                Spacer()
            }

            Text(transferStore.transferDomainState.selectedPayChain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(ThemeTokens.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .frame(maxWidth: .infinity, alignment: .center)

            row("To", recipientText)
            row("Amount receiving", amountReceivingText)
            if let fee = feeText {
                row("Fee", fee)
            }
            row("Payment Method", "Balance")
            if !noteText.isEmpty {
                row("Transfer Note", noteText)
            }

            if transferStore.transferDraft.mode == .proxy {
                row("OrderSN", transferStore.transferDraft.orderSN ?? "-")
            }
        }
        .padding(14)
        .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: widthClass.metrics.cardCornerRadius, style: .continuous))
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(ThemeTokens.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(ThemeTokens.title)
                .multilineTextAlignment(.trailing)
                .lineLimit(3)
                .truncationMode(.middle)
        }
    }

    private func bottomButton(widthClass: DeviceWidthClass) -> some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                guard !transferStore.isLoading(.transferPay) else { return }
                let now = Date()
                if let lastTapAt, now.timeIntervalSince(lastTapAt) < 2 {
                    return
                }
                self.lastTapAt = now
                Task {
                    let ok = await transferStore.executeTransferPayment()
                    if ok {
                        onSuccess()
                    }
                }
            } label: {
                HStack {
                    Spacer()
                    if transferStore.isLoading(.transferPay) {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Confirm")
                            .font(.system(size: widthClass.bodySize + 2, weight: .semibold))
                            .foregroundStyle(Color.white)
                    }
                    Spacer()
                }
                .frame(height: widthClass.metrics.buttonHeight)
                .background(ThemeTokens.cpPrimary)
                .clipShape(RoundedRectangle(cornerRadius: widthClass.metrics.buttonHeight / 2, style: .continuous))
                .padding(.horizontal, widthClass.horizontalPadding)
                .padding(.top, 10)
                .padding(.bottom, 10)
            }
            .buttonStyle(.pressFeedback)
            .disabled(transferStore.isLoading(.transferPay))
            .accessibilityIdentifier(A11yID.Transfer.confirmButton)
        }
        .frame(maxWidth: .infinity)
        .background(ThemeTokens.groupBackground.opacity(0.95))
    }

    private var noteText: String {
        transferStore.transferDraft.note
    }

    private var recipientText: String {
        if let detail = transferStore.transferDraft.orderDetail,
           let to = detail.receiveAddress ?? detail.depositAddress,
           !to.isEmpty {
            return shortAddress(to)
        }
        return shortAddress(transferStore.transferDraft.recipientAddress)
    }

    private var amountReceivingText: String {
        if let detail = transferStore.transferDraft.orderDetail,
           let recv = detail.recvEstimateAmount?.description ?? detail.recvAmount?.description {
            return "\(recv) \(detail.recvCoinName ?? transferStore.transferDomainState.selectedRecvCoinName)"
        }
        return "\(transferStore.transferDraft.amountText) \(transferStore.transferDomainState.selectedRecvCoinName)"
    }

    private var totalAmountText: String {
        if let detail = transferStore.transferDraft.orderDetail,
           let send = detail.sendEstimateAmount?.description ?? detail.sendAmount?.description {
            return "\(send) \(detail.sendCoinName ?? transferStore.transferDomainState.selectedSendCoinName)"
        }
        return "\(transferStore.transferDraft.amountText) \(transferStore.transferDomainState.selectedSendCoinName)"
    }

    private var feeText: String? {
        guard let detail = transferStore.transferDraft.orderDetail,
              let fee = detail.sendEstimateFeeAmount?.description,
              fee != "0", !fee.isEmpty else {
            return nil
        }
        return "+ \(fee) \(detail.sendCoinName ?? transferStore.transferDomainState.selectedSendCoinName)"
    }

    private func shortAddress(_ value: String) -> String {
        AddressFormatter.shortened(value, leading: 8, trailing: 6, threshold: 14)
    }
}
