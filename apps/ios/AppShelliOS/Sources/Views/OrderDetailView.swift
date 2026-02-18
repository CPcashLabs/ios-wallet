import BackendAPI
import SwiftUI
import UIKit

struct OrderDetailView: View {
    @ObservedObject var meStore: MeStore
    @ObservedObject var uiStore: UIStore
    let orderSN: String

    var body: some View {
        AdaptiveReader { widthClass in
            FullscreenScaffold(backgroundStyle: .globalImage) {
                ScrollView {
                    VStack(spacing: 12) {
                        if let detail = meStore.selectedOrderDetail {
                            amountCard(detail: detail, widthClass: widthClass)
                            detailCard(detail: detail, widthClass: widthClass)
                        } else {
                            ProgressView("加载中...")
                                .frame(maxWidth: .infinity, minHeight: 220)
                                .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: widthClass.metrics.cardCornerRadius, style: .continuous))
                        }
                    }
                    .padding(.horizontal, widthClass.horizontalPadding)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("订单详情")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await meStore.loadOrderDetail(orderSN: orderSN)
            }
        }
    }

    private func amountCard(detail: OrderDetail, widthClass: DeviceWidthClass) -> some View {
        VStack(spacing: 8) {
            Text(statusTitle(detail.status))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(statusColor(detail.status))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(statusColor(detail.status).opacity(0.12), in: Capsule())

            Text(primaryAmount(detail))
                .font(.system(size: widthClass.titleSize + 10, weight: .bold))
                .foregroundStyle(ThemeTokens.title)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: widthClass.metrics.cardCornerRadius, style: .continuous))
    }

    private func detailCard(detail: OrderDetail, widthClass: DeviceWidthClass) -> some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 10) {
                row(
                    title: "对手账户",
                    value: reciprocalAddress(detail),
                    copyValue: reciprocalAddress(detail)
                )
                row(title: "网络", value: networkText(detail))
                row(
                    title: "金额",
                    value: primaryAmount(detail).replacingOccurrences(of: "+", with: "").replacingOccurrences(of: "-", with: "")
                )
                if let fee = detail.sendFeeAmount?.doubleValue, fee > 0 {
                    row(title: "手续费", value: "\(formatAmount(fee)) \(detail.sendCoinName ?? detail.sendCoinCode ?? "USDT")")
                }
                if let createdAt = detail.createdAt {
                    row(title: "创建时间", value: formatTimestamp(createdAt))
                }
                if let receivedAt = detail.recvActualReceivedAt, receivedAt > 0 {
                    row(title: "收款时间", value: formatTimestamp(receivedAt))
                }
                row(title: "订单号", value: detail.orderSn ?? orderSN, copyValue: detail.orderSn ?? orderSN)
                if let txid = detail.txid, !txid.isEmpty {
                    row(title: "TXID", value: txid, copyValue: txid)
                }
                if let note = detail.note, !note.isEmpty {
                    row(title: "备注", value: note)
                }
            }
            .padding(14)
        }
    }

    private func row(title: String, value: String, copyValue: String? = nil) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(ThemeTokens.secondary)
                .frame(width: 76, alignment: .leading)
            Text(value)
                .font(.system(size: 14))
                .foregroundStyle(ThemeTokens.title)
                .textSelection(.enabled)
                .lineLimit(4)
                .truncationMode(.middle)
            if let copyValue, !copyValue.isEmpty {
                Button {
                    UIPasteboard.general.string = copyValue
                    uiStore.showInfoToast("已复制")
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ThemeTokens.cpPrimary)
                }
                .buttonStyle(.pressFeedback)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func reciprocalAddress(_ detail: OrderDetail) -> String {
        if isReceiveType(detail.orderType) {
            return detail.paymentAddress ?? detail.receiveAddress ?? "-"
        }
        return detail.receiveAddress ?? detail.paymentAddress ?? "-"
    }

    private func primaryAmount(_ detail: OrderDetail) -> String {
        let receive = isReceiveType(detail.orderType)
        let amount = receive ? jsonNumber(detail.recvAmount) : jsonNumber(detail.sendAmount)
        let coin = receive ? (detail.recvCoinName ?? detail.recvCoinCode ?? "USDT") : (detail.sendCoinName ?? detail.sendCoinCode ?? "USDT")
        return "\(receive ? "+" : "-")\(formatAmount(amount)) \(coin)"
    }

    private func networkText(_ detail: OrderDetail) -> String {
        let send = detail.sendChainName ?? "-"
        let recv = detail.recvChainName ?? "-"
        if send == recv {
            return send
        }
        return "\(send) -> \(recv)"
    }

    private func statusTitle(_ status: Int?) -> String {
        switch status {
        case 4:
            return "已完成"
        case 3:
            return "待确认"
        case 2, 1, 5, 0:
            return "处理中"
        case -2:
            return "已取消"
        case -5:
            return "失败"
        default:
            return "未知状态"
        }
    }

    private func statusColor(_ status: Int?) -> Color {
        switch status {
        case 4:
            return ThemeTokens.success
        case -2, -5:
            return ThemeTokens.danger
        default:
            return ThemeTokens.cpPrimary
        }
    }

    private func isReceiveType(_ orderType: String?) -> Bool {
        let type = (orderType ?? "").uppercased()
        return ["RECEIPT", "RECEIPT_FIXED", "RECEIPT_NORMAL", "TRACE", "TRACE_CHILD", "TRACE_LONG_TERM", "SEND_RECEIVE", "SEND_TOKEN_RECEIVE"].contains(type)
    }

    private func jsonNumber(_ value: JSONValue?) -> Double {
        if let v = value?.doubleValue {
            return v
        }
        if let text = value?.stringValue, let v = Double(text) {
            return v
        }
        return 0
    }

    private func formatAmount(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    private func formatTimestamp(_ timestamp: Int) -> String {
        DateTextFormatter.yearMonthDayMinute(fromTimestamp: timestamp, fallback: "-")
    }
}
