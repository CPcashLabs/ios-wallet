import BackendAPI
import SwiftUI

struct ReceiveAddressDeleteView: View {
    @ObservedObject var receiveStore: ReceiveStore

    var body: some View {
        AdaptiveReader { widthClass in
            SafeAreaScreen(backgroundStyle: .globalImage) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Address Deletion Notes")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(ThemeTokens.title)
                                Text("The backend currently supports invalidation and regeneration only, not physical deletion. You can regenerate the same address type below.")
                                    .font(.system(size: 13))
                                    .foregroundStyle(ThemeTokens.secondary)
                            }
                            .padding(14)
                        }

                        if filteredInvalidItems.isEmpty {
                            EmptyStateView(asset: "bill_no_data", title: "No invalid addresses")
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(deleteRows) { row in
                                    self.row(row.item)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, widthClass.horizontalPadding)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Delete Address")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await receiveStore.loadReceiveAddresses(validity: .invalid)
            }
        }
    }

    private var filteredInvalidItems: [TraceOrderItem] {
        let source = receiveStore.receiveRecentInvalid
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

    private var deleteRows: [ReceiveDeleteRow] {
        let seeds = filteredInvalidItems.map { item in
            StableRowID.make(
                item.orderSn,
                item.receiveAddress,
                fallback: "receive-delete-row"
            )
        }
        let ids = StableRowID.uniqued(seeds)
        return Array(zip(filteredInvalidItems, ids)).map { pair in
            ReceiveDeleteRow(id: pair.1, item: pair.0)
        }
    }

    private func row(_ item: TraceOrderItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.orderSn ?? "-")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(ThemeTokens.secondary)

            Text(item.receiveAddress ?? "-")
                .font(.system(size: 13))
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(ThemeTokens.title)

            HStack {
                Text("Status: Invalid")
                    .font(.system(size: 12))
                    .foregroundStyle(ThemeTokens.secondary)
                Spacer()
                Button("Regenerate") {
                    Task {
                        if (item.orderType ?? "").uppercased().contains("LONG") {
                            await receiveStore.createLongTraceOrder()
                        } else {
                            await receiveStore.createShortTraceOrder()
                        }
                    }
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(ThemeTokens.cpPrimary)
            }
        }
        .padding(12)
        .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct ReceiveDeleteRow: Identifiable {
    let id: String
    let item: TraceOrderItem
}
