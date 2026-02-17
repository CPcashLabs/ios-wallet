import BackendAPI
import SwiftUI
import UIKit

struct ReceiveCardView: View {
    let order: TraceOrderItem?
    let traceDetail: TraceShowDetail?
    let payChain: String
    let sendCoinName: String
    let minAmount: Double
    let maxAmount: Double
    let qrSide: CGFloat
    let onGenerate: () -> Void
    let onShare: () -> Void
    let onTxLogs: () -> Void
    let onCopyAddress: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if showUpdateBanner {
                HStack(spacing: 8) {
                    Text("地址即将失效")
                        .font(.system(size: 12))
                        .foregroundStyle(ThemeTokens.title)
                    Button("生成地址") {
                        onGenerate()
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ThemeTokens.cpPrimary)
                }
                .frame(maxWidth: .infinity, minHeight: 28)
                .background(ThemeTokens.softSurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            if let qrValue = qrAddress, !qrValue.isEmpty {
                qrSection(address: qrValue)
                addressSection(address: qrValue)
                actionButtons(address: qrValue)
                minimumSection
                txLogsSection
            } else {
                emptySection
            }
        }
        .padding(16)
        .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func qrSection(address: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(ThemeTokens.qrBackground)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.black.opacity(0.12), lineWidth: 1))
            QRCodeView(value: address, side: qrSide)
        }
        .frame(width: qrSide + 16, height: qrSide + 16)
    }

    private func addressSection(address: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("地址")
                    .font(.system(size: 14))
                    .foregroundStyle(ThemeTokens.title)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ThemeTokens.tertiary)
            }
            Text(formatAddress(address))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(ThemeTokens.title)
                .lineLimit(2)
                .truncationMode(.middle)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ThemeTokens.softSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onTapGesture {
            UIPasteboard.general.string = address
            onCopyAddress()
        }
    }

    private func actionButtons(address: String) -> some View {
        HStack(spacing: 10) {
            button(title: "分享", action: onShare)
            button(title: "复制") {
                UIPasteboard.general.string = address
                onCopyAddress()
            }
        }
    }

    private var minimumSection: some View {
        VStack(spacing: 8) {
            if let expiry = expiryText {
                HStack {
                    Text("有效期")
                        .font(.system(size: 14))
                        .foregroundStyle(ThemeTokens.secondary)
                    Spacer()
                    Text(expiry)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ThemeTokens.title)
                }
            }
            HStack {
                Text("最低收款金额")
                    .font(.system(size: 14))
                    .foregroundStyle(ThemeTokens.secondary)
                Spacer()
                Text("\(format(minAmount)) \(sendCoinName)")
                    .font(.system(size: 14))
                    .foregroundStyle(ThemeTokens.title)
            }
            if maxAmount > 0 {
                HStack {
                    Text("最高收款金额")
                        .font(.system(size: 14))
                        .foregroundStyle(ThemeTokens.secondary)
                    Spacer()
                    Text("\(format(maxAmount)) \(sendCoinName)")
                        .font(.system(size: 14))
                        .foregroundStyle(ThemeTokens.title)
                }
            }
        }
    }

    private var txLogsSection: some View {
        Button {
            onTxLogs()
        } label: {
            HStack(spacing: 10) {
                Image("me_bill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                Text("Transaction records")
                    .font(.system(size: 16))
                    .foregroundStyle(ThemeTokens.title)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ThemeTokens.tertiary)
            }
            .padding(.top, 10)
            .overlay(alignment: .top) {
                Divider()
            }
        }
        .buttonStyle(.plain)
    }

    private var emptySection: some View {
        VStack(spacing: 12) {
            Text("暂无收款地址")
                .font(.system(size: 14))
                .foregroundStyle(ThemeTokens.secondary)
            button(title: "生成地址", action: onGenerate)
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
    }

    private func button(title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.system(size: 15, weight: .medium))
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(ThemeTokens.cpPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: 21, style: .continuous)
                    .stroke(ThemeTokens.cpPrimary.opacity(0.38), lineWidth: 1)
            )
            .contentShape(Rectangle())
            .buttonStyle(.pressFeedback)
    }

    private var qrAddress: String? {
        let address = traceDetail?.depositAddress
            ?? traceDetail?.receiveAddress
            ?? order?.depositAddress
            ?? order?.receiveAddress
            ?? order?.address
        if let address, !address.isEmpty {
            return address
        }
        return nil
    }

    private var showUpdateBanner: Bool {
        let expiredAt = traceDetail?.expiredAt ?? order?.expiredAt
        guard let expiredAt else { return false }
        let threshold: TimeInterval = 10 * 60 * 1000
        let nowMS = Date().timeIntervalSince1970 * 1000
        return Double(expiredAt) < (nowMS + threshold)
    }

    private var expiryText: String? {
        let expiredAt = traceDetail?.expiredAt ?? order?.expiredAt
        guard let expiredAt else { return nil }
        return DateTextFormatter.yearMonthDayMinute(fromTimestamp: expiredAt, fallback: "-")
    }

    private func formatAddress(_ value: String) -> String {
        AddressFormatter.shortened(value, leading: 6, trailing: 6, threshold: 14)
    }

    private func format(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}
