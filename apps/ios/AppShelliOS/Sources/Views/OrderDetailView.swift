import BackendAPI
import SwiftUI
import UIKit

private struct OrderDetailLine: Identifiable {
    let id: String
    let title: String
    let value: String
    let copyValue: String?
}

struct OrderDetailView: View {
    @ObservedObject var meStore: MeStore
    @ObservedObject var uiStore: UIStore
    let orderSN: String

    @State private var isLoading = true

    var body: some View {
        AdaptiveReader { widthClass in
            FullscreenScaffold(backgroundStyle: .globalImage) {
                ScrollView {
                    VStack(spacing: 12) {
                        if isLoading, meStore.selectedOrderDetail == nil {
                            loadingSkeleton(widthClass: widthClass)
                        } else if let detail = meStore.selectedOrderDetail {
                            summaryCard(detail: detail, widthClass: widthClass)

                            detailSection(
                                title: "Transaction Info",
                                symbol: "doc.text.magnifyingglass",
                                rows: transactionRows(detail),
                                widthClass: widthClass,
                                accessibilityID: A11yID.OrderDetail.transactionCard
                            )

                            detailSection(
                                title: "Address Info",
                                symbol: "person.2",
                                rows: addressRows(detail),
                                widthClass: widthClass,
                                accessibilityID: A11yID.OrderDetail.addressCard
                            )

                            detailSection(
                                title: "On-chain Info",
                                symbol: "link",
                                rows: chainRows(detail),
                                widthClass: widthClass,
                                accessibilityID: A11yID.OrderDetail.chainCard
                            )

                            detailSection(
                                title: "Time and Notes",
                                symbol: "clock",
                                rows: timeRows(detail),
                                widthClass: widthClass,
                                accessibilityID: A11yID.OrderDetail.timeCard
                            )
                        } else {
                            emptyState(widthClass: widthClass)
                        }
                    }
                    .padding(.horizontal, widthClass.horizontalPadding)
                    .padding(.vertical, 12)
                }
                .accessibilityIdentifier(A11yID.OrderDetail.root)
                .refreshable {
                    await reload()
                }
            }
            .navigationTitle("Order Details")
            .navigationBarTitleDisplayMode(.inline)
            .task(id: orderSN) {
                await reload()
            }
        }
        .accessibilityIdentifier(A11yID.OrderDetail.root)
    }

    private func reload() async {
        isLoading = true
        await meStore.loadOrderDetail(orderSN: orderSN)
        isLoading = false
    }

    private func loadingSkeleton(widthClass: DeviceWidthClass) -> some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: widthClass.metrics.cardCornerRadius)
                .fill(ThemeTokens.cardBackground)
                .frame(height: 158)
                .overlay(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 10) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.18)).frame(width: 86, height: 12)
                        RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.16)).frame(width: 180, height: 28)
                        RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.14)).frame(width: 220, height: 14)
                    }
                    .padding(16)
                }

            ForEach(0 ..< 3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: widthClass.metrics.cardCornerRadius)
                    .fill(ThemeTokens.cardBackground)
                    .frame(height: 168)
                    .overlay(alignment: .topLeading) {
                        VStack(alignment: .leading, spacing: 10) {
                            RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.18)).frame(width: 90, height: 14)
                            RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.14)).frame(height: 12)
                            RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.14)).frame(height: 12)
                            RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.14)).frame(height: 12)
                        }
                        .padding(16)
                    }
            }
        }
        .redacted(reason: .placeholder)
    }

    private func emptyState(widthClass: DeviceWidthClass) -> some View {
        VStack(spacing: 14) {
            EmptyStateView(asset: "bill_no_data", title: "No order details")
            Button("Retry") {
                Task {
                    await reload()
                }
            }
            .font(.system(size: widthClass.bodySize, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: widthClass.metrics.buttonHeight)
            .background(ThemeTokens.cpPrimary, in: Capsule())
            .buttonStyle(.pressFeedback)
        }
        .padding(.top, 52)
        .accessibilityIdentifier(A11yID.OrderDetail.empty)
    }

    private func summaryCard(detail: OrderDetail, widthClass: DeviceWidthClass) -> some View {
        let color = statusColor(detail.status)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label {
                    Text(statusTitle(detail.status))
                        .font(.system(size: 13, weight: .semibold))
                } icon: {
                    Image(systemName: statusSymbol(detail.status))
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(color)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(color.opacity(0.12), in: Capsule())

                Spacer()

                Text(directionTitle(detail))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ThemeTokens.secondary)
            }

            Text(primaryAmount(detail))
                .font(.system(size: widthClass.titleSize + 11, weight: .bold))
                .foregroundStyle(ThemeTokens.title)
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Text(secondaryAmountText(detail))
                .font(.system(size: widthClass.footnoteSize))
                .foregroundStyle(ThemeTokens.secondary)
                .lineLimit(2)

            HStack(spacing: 8) {
                chip(title: "Network", value: networkText(detail))
                chip(title: "Order No.", value: shortOrderSN(detail.orderSn ?? orderSN))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: widthClass.metrics.cardCornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.12), ThemeTokens.cardBackground],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: widthClass.metrics.cardCornerRadius, style: .continuous)
                .stroke(color.opacity(0.22), lineWidth: 1)
        )
        .accessibilityIdentifier(A11yID.OrderDetail.summaryCard)
    }

    private func chip(title: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .foregroundStyle(ThemeTokens.secondary)
            Text(value)
                .foregroundStyle(ThemeTokens.title)
        }
        .font(.system(size: 11, weight: .medium))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(ThemeTokens.softSurface, in: Capsule())
    }

    private func detailSection(
        title: String,
        symbol: String,
        rows: [OrderDetailLine],
        widthClass: DeviceWidthClass,
        accessibilityID: String
    ) -> some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 7) {
                    Image(systemName: symbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(ThemeTokens.cpPrimary)
                    Text(title)
                        .font(.system(size: widthClass.bodySize + 1, weight: .semibold))
                        .foregroundStyle(ThemeTokens.title)
                }
                .padding(.bottom, 12)

                if rows.isEmpty {
                    Text("No data")
                        .font(.system(size: 13))
                        .foregroundStyle(ThemeTokens.secondary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                        detailRow(row, showDivider: index < rows.count - 1, widthClass: widthClass)
                    }
                }
            }
            .padding(14)
        }
        .accessibilityIdentifier(accessibilityID)
    }

    private func detailRow(_ row: OrderDetailLine, showDivider: Bool, widthClass: DeviceWidthClass) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                Text(row.title)
                    .font(.system(size: widthClass.footnoteSize))
                    .foregroundStyle(ThemeTokens.secondary)
                    .frame(width: 82, alignment: .leading)

                Text(row.value)
                    .font(.system(size: widthClass.bodySize))
                    .foregroundStyle(ThemeTokens.title)
                    .lineLimit(4)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let copyValue = row.copyValue {
                    Button {
                        UIPasteboard.general.string = copyValue
                        uiStore.showInfoToast("Copied")
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(ThemeTokens.cpPrimary)
                    }
                    .buttonStyle(.pressFeedback)
                }
            }
            .padding(.vertical, 10)

            if showDivider {
                Divider()
            }
        }
    }

    private func transactionRows(_ detail: OrderDetail) -> [OrderDetailLine] {
        var rows: [OrderDetailLine] = []
        rows.append(line(title: "Order Type", value: directionTitle(detail)))
        rows.append(line(title: "Order Status", value: statusTitle(detail.status)))
        rows.append(line(title: "Transaction Network", value: networkText(detail)))
        rows.append(line(title: "Send Amount", value: amountText(detail.sendActualAmount ?? detail.sendAmount, detail.sendCoinName ?? detail.sendCoinCode ?? "USDT")))
        rows.append(line(title: "Received Amount", value: amountText(detail.recvActualAmount ?? detail.recvAmount, detail.recvCoinName ?? detail.recvCoinCode ?? "USDT")))
        if let fee = displayFee(detail) {
            rows.append(line(title: "Fee", value: fee))
        }
        return rows
    }

    private func addressRows(_ detail: OrderDetail) -> [OrderDetailLine] {
        var rows: [OrderDetailLine] = []
        var seen = Set<String>()

        appendAddressRow(&rows, &seen, title: "My Address", value: ownAddress(detail))
        appendAddressRow(&rows, &seen, title: "Counterparty Address", value: reciprocalAddress(detail))
        appendAddressRow(&rows, &seen, title: "Deposit Address", value: detail.depositAddress)
        appendAddressRow(&rows, &seen, title: "Relay Address", value: detail.transferAddress)

        return rows
    }

    private func chainRows(_ detail: OrderDetail) -> [OrderDetailLine] {
        var rows: [OrderDetailLine] = []
        if let txid = normalized(detail.txid) {
            rows.append(line(title: "TxID", value: txid, copyValue: txid))
        }
        if let contract = normalized(detail.sendCoinContract) {
            rows.append(line(title: "Token Contract", value: contract, copyValue: contract))
        }
        if let multisigAddress = normalized(detail.multisigWalletAddress) {
            rows.append(line(title: "Multisig Address", value: multisigAddress, copyValue: multisigAddress))
        }
        if let multisigName = normalized(detail.multisigWalletName) {
            rows.append(line(title: "Multisig Name", value: multisigName))
        }
        return rows
    }

    private func timeRows(_ detail: OrderDetail) -> [OrderDetailLine] {
        var rows: [OrderDetailLine] = []
        if let createdAt = detail.createdAt {
            rows.append(line(title: "Created At", value: formatTimestamp(createdAt)))
        }
        if let receivedAt = detail.recvActualReceivedAt, receivedAt > 0 {
            rows.append(line(title: "Completed At", value: formatTimestamp(receivedAt)))
        }
        rows.append(line(title: "Order No.", value: detail.orderSn ?? orderSN, copyValue: detail.orderSn ?? orderSN))
        if let note = normalized(detail.note) {
            rows.append(line(title: "Note", value: note))
        }
        return rows
    }

    private func line(title: String, value: String, copyValue: String? = nil) -> OrderDetailLine {
        OrderDetailLine(id: "\(title):\(value)", title: title, value: value, copyValue: copyValue)
    }

    private func appendAddressRow(_ rows: inout [OrderDetailLine], _ seen: inout Set<String>, title: String, value: String?) {
        guard let normalizedValue = normalized(value) else { return }
        let key = normalizedValue.lowercased()
        guard !seen.contains(key) else { return }
        seen.insert(key)
        rows.append(line(title: title, value: normalizedValue, copyValue: normalizedValue))
    }

    private func ownAddress(_ detail: OrderDetail) -> String? {
        if isReceiveType(detail.orderType) {
            return detail.receiveAddress ?? detail.paymentAddress
        }
        return detail.paymentAddress ?? detail.receiveAddress
    }

    private func reciprocalAddress(_ detail: OrderDetail) -> String? {
        if isReceiveType(detail.orderType) {
            return detail.paymentAddress ?? detail.receiveAddress
        }
        return detail.receiveAddress ?? detail.paymentAddress
    }

    private func primaryAmount(_ detail: OrderDetail) -> String {
        let receive = isReceiveType(detail.orderType)
        let amount = receive ? jsonNumber(detail.recvActualAmount ?? detail.recvAmount) : jsonNumber(detail.sendActualAmount ?? detail.sendAmount)
        let coin = receive ? (detail.recvCoinName ?? detail.recvCoinCode ?? "USDT") : (detail.sendCoinName ?? detail.sendCoinCode ?? "USDT")
        let sign = receive ? "+" : "-"
        return "\(sign)\(formatAmount(amount)) \(coin)"
    }

    private func secondaryAmountText(_ detail: OrderDetail) -> String {
        let send = amountText(detail.sendActualAmount ?? detail.sendAmount, detail.sendCoinName ?? detail.sendCoinCode ?? "USDT")
        let receive = amountText(detail.recvActualAmount ?? detail.recvAmount, detail.recvCoinName ?? detail.recvCoinCode ?? "USDT")
        return "Sent \(send) · Received \(receive)"
    }

    private func amountText(_ value: JSONValue?, _ coin: String) -> String {
        let number = jsonNumber(value)
        return "\(formatAmount(number)) \(coin)"
    }

    private func displayFee(_ detail: OrderDetail) -> String? {
        let fee = jsonNumber(detail.sendActualFeeAmount ?? detail.sendFeeAmount ?? detail.sendEstimateFeeAmount)
        guard fee > 0 else { return nil }
        let coin = detail.sendCoinName ?? detail.sendCoinCode ?? "USDT"
        return "\(formatAmount(fee)) \(coin)"
    }

    private func directionTitle(_ detail: OrderDetail) -> String {
        isReceiveType(detail.orderType) ? "Receive Order" : "Transfer Order"
    }

    private func shortOrderSN(_ value: String) -> String {
        AddressFormatter.shortened(value, leading: 6, trailing: 4, threshold: 14)
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
            return "Completed"
        case 3:
            return "Pending Confirmation"
        case 2, 1, 5, 0:
            return "Processing"
        case -2:
            return "Cancelled"
        case -5:
            return "Failed"
        default:
            return "Unknown status"
        }
    }

    private func statusColor(_ status: Int?) -> Color {
        switch status {
        case 4:
            return ThemeTokens.success
        case -2, -5:
            return ThemeTokens.danger
        case 3:
            return ThemeTokens.warning
        default:
            return ThemeTokens.cpPrimary
        }
    }

    private func statusSymbol(_ status: Int?) -> String {
        switch status {
        case 4:
            return "checkmark.seal.fill"
        case -2, -5:
            return "xmark.octagon.fill"
        case 3:
            return "clock.badge.exclamationmark.fill"
        default:
            return "arrow.triangle.2.circlepath.circle.fill"
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

    private func normalized(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func formatAmount(_ value: Double) -> String {
        let raw = String(format: "%.6f", value)
        let noTrailingZeros = raw.replacingOccurrences(
            of: #"(\.\d*?[1-9])0+$"#,
            with: "$1",
            options: .regularExpression
        )
        let noTrailingDotZero = noTrailingZeros.replacingOccurrences(
            of: #"\.0+$"#,
            with: "",
            options: .regularExpression
        )
        return noTrailingDotZero
    }

    private func formatTimestamp(_ timestamp: Int) -> String {
        DateTextFormatter.yearMonthDayMinute(fromTimestamp: timestamp, fallback: "-")
    }
}
