import BackendAPI
import SwiftUI

struct ReceiveAddressListView: View {
    @ObservedObject var state: AppState
    let validity: ReceiveAddressValidityState
    var onNavigate: ((ReceiveRoute) -> Void)? = nil

    var body: some View {
        AdaptiveReader { widthClass in
            SafeAreaScreen(backgroundStyle: .globalImage) {
                Group {
                    if isLoading && items.isEmpty {
                        ProgressView("正在加载...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if items.isEmpty {
                        EmptyStateView(asset: "bill_no_data", title: "暂无地址")
                            .padding(.horizontal, widthClass.horizontalPadding)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(addressRows) { row in
                                    itemCard(row.item)
                                }
                            }
                            .padding(.horizontal, widthClass.horizontalPadding)
                            .padding(.vertical, 12)
                        }
                        .refreshable {
                            await state.loadReceiveAddresses(validity: validity)
                        }
                    }
                }
            }
            .navigationTitle(validity == .valid ? "有效地址" : "失效地址")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await state.loadReceiveAddresses(validity: validity)
            }
        }
    }

    private var items: [TraceOrderItem] {
        let source = validity == .valid ? state.receiveRecentValid : state.receiveRecentInvalid
        return source.filter { item in
            let orderType = (item.orderType ?? "").uppercased()
            switch state.receiveDomainState.activeTab {
            case .individuals:
                return !orderType.contains("LONG")
            case .business:
                return orderType.contains("LONG")
            }
        }
    }

    private var isLoading: Bool {
        state.isLoading(validity == .valid ? "receive.home" : "receive.invalid")
    }

    private var addressRows: [ReceiveAddressRow] {
        Array(items.enumerated()).map { index, item in
            let seed = item.orderSn ?? item.address ?? "receive"
            return ReceiveAddressRow(id: "\(seed)-\(index)", item: item)
        }
    }

    private func itemCard(_ item: TraceOrderItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.orderSn ?? "-")
                    .font(.system(size: 12, design: .monospaced))
                    .lineLimit(1)
                Spacer()
                if item.isMarked == true {
                    Text("默认")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(ThemeTokens.cpPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .overlay(Capsule().stroke(ThemeTokens.cpPrimary, lineWidth: 1))
                }
            }
            .foregroundStyle(ThemeTokens.secondary)

            Text(item.address ?? item.receiveAddress ?? "-")
                .font(.system(size: 13))
                .foregroundStyle(ThemeTokens.title)
                .lineLimit(1)
                .truncationMode(.middle)

            HStack(spacing: 10) {
                Text("状态: \(statusText(item.status))")
                if let expiredAt = item.expiredAt {
                    Text("到期: \(formatTimestamp(expiredAt))")
                }
            }
            .font(.system(size: 12))
            .foregroundStyle(ThemeTokens.secondary)

            HStack(spacing: 8) {
                if validity == .valid, let orderSN = item.orderSn {
                    actionButton("设为默认") {
                        Task {
                            await state.markTraceOrder(
                                orderSN: orderSN,
                                sendCoinCode: item.sendCoinCode,
                                recvCoinCode: item.recvCoinCode,
                                orderType: item.orderType
                            )
                        }
                    }
                    actionButton("记录") {
                        onNavigate?(.txLogs(orderSN: orderSN))
                    }
                    actionButton("分享") {
                        onNavigate?(.share(orderSN: orderSN))
                    }
                } else if let orderType = item.orderType {
                    actionButton("重新生成") {
                        Task {
                            if orderType.uppercased().contains("LONG") {
                                await state.createLongTraceOrder()
                            } else {
                                await state.createShortTraceOrder()
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func actionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(ThemeTokens.cpPrimary)
            .background(ThemeTokens.cpPrimary.opacity(0.12), in: Capsule())
            .buttonStyle(.plain)
    }

    private func statusText(_ value: Int?) -> String {
        switch value ?? -1 {
        case 1:
            return "有效"
        case 2:
            return "处理中"
        default:
            return "失效"
        }
    }

    private func formatTimestamp(_ milliseconds: Int) -> String {
        DateTextFormatter.yearMonthDay(fromTimestamp: milliseconds, fallback: "-")
    }
}

private struct ReceiveAddressRow: Identifiable {
    let id: String
    let item: TraceOrderItem
}
