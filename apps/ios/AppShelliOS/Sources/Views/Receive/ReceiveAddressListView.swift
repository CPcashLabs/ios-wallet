import BackendAPI
import SwiftUI

struct ReceiveAddressListView: View {
    @ObservedObject var receiveStore: ReceiveStore
    let validity: ReceiveAddressValidityState
    var onNavigate: ((ReceiveRoute) -> Void)? = nil

    var body: some View {
        AdaptiveReader { widthClass in
            SafeAreaScreen(backgroundStyle: .globalImage) {
                Group {
                    if isLoading && items.isEmpty {
                        ProgressView("Loading...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if items.isEmpty {
                        EmptyStateView(asset: "bill_no_data", title: "No addresses")
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
                            await receiveStore.loadReceiveAddresses(validity: validity)
                        }
                    }
                }
            }
            .navigationTitle(validity == .valid ? "Valid Addresses" : "Invalid Addresses")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await receiveStore.loadReceiveAddresses(validity: validity)
            }
        }
    }

    private var items: [TraceOrderItem] {
        let source = validity == .valid ? receiveStore.receiveRecentValid : receiveStore.receiveRecentInvalid
        return source.filter { item in
            let orderType = (item.orderType ?? "").uppercased()
            switch receiveStore.receiveDomainState.activeTab {
            case .individuals:
                return !orderType.contains("LONG")
            case .business:
                return orderType.contains("LONG")
            }
        }
    }

    private var isLoading: Bool {
        receiveStore.isLoading(validity == .valid ? .receiveHome : .receiveInvalid)
    }

    private var addressRows: [ReceiveAddressRow] {
        let seeds = items.map { item in
            StableRowID.make(
                item.orderSn,
                item.address,
                item.receiveAddress,
                fallback: "receive-address-row"
            )
        }
        let ids = StableRowID.uniqued(seeds)
        return Array(zip(items, ids)).map { pair in
            ReceiveAddressRow(id: pair.1, item: pair.0)
        }
    }

    private func itemCard(_ item: TraceOrderItem) -> some View {
        let actionOrderSN = resolvedActionOrderSN(item)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.orderSn ?? "-")
                    .font(.system(size: 12, design: .monospaced))
                    .lineLimit(1)
                Spacer()
                if item.isMarked == true {
                    Text("Default")
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
                Text("Status: \(statusText(item.status))")
                if let expiredAt = item.expiredAt {
                    Text("Expires: \(formatTimestamp(expiredAt))")
                }
            }
            .font(.system(size: 12))
            .foregroundStyle(ThemeTokens.secondary)

            HStack(spacing: 8) {
                if validity == .valid, let orderSN = actionOrderSN {
                    actionButton("Set as Default", id: actionID(orderSN: orderSN, action: "default")) {
                        Task {
                            await receiveStore.markTraceOrder(
                                orderSN: orderSN,
                                sendCoinCode: item.sendCoinCode,
                                recvCoinCode: item.recvCoinCode,
                                orderType: item.orderType
                            )
                        }
                    }
                    actionButton("records", id: actionID(orderSN: orderSN, action: "logs")) {
                        onNavigate?(.txLogs(orderSN: orderSN))
                    }
                    actionButton("Share", id: actionID(orderSN: orderSN, action: "share")) {
                        onNavigate?(.share(orderSN: orderSN))
                    }
                } else if let orderType = item.orderType, let orderSN = actionOrderSN {
                    actionButton("Regenerate", id: actionID(orderSN: orderSN, action: "regenerate")) {
                        Task {
                            if orderType.uppercased().contains("LONG") {
                                await receiveStore.createLongTraceOrder()
                            } else {
                                await receiveStore.createShortTraceOrder()
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("receive.address.row.\(item.orderSn ?? item.address ?? "unknown")")
    }

    private func actionButton(_ title: String, id: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(ThemeTokens.cpPrimary)
            .background(ThemeTokens.cpPrimary.opacity(0.12), in: Capsule())
            .buttonStyle(.plain)
            .accessibilityIdentifier(id)
    }

    private func actionID(orderSN: String, action: String) -> String {
        A11yID.Receive.addressListActionPrefix + orderSN + "." + action
    }

    private func resolvedActionOrderSN(_ item: TraceOrderItem) -> String? {
        for candidate in [item.orderSn, item.receiveAddress, item.address] {
            let value = candidate?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !value.isEmpty {
                return value
            }
        }
        return nil
    }

    private func statusText(_ value: Int?) -> String {
        switch value ?? -1 {
        case 1:
            return "Valid"
        case 2:
            return "Processing"
        default:
            return "Invalid"
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
