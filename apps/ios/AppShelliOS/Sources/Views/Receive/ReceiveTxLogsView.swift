import BackendAPI
import SwiftUI

struct ReceiveTxLogsView: View {
    @ObservedObject var receiveStore: ReceiveStore
    let orderSN: String

    var body: some View {
        AdaptiveReader { widthClass in
            SafeAreaScreen(backgroundStyle: .globalImage) {
                Group {
                    if receiveStore.isLoading(.receiveChildren) && receiveStore.receiveTraceChildren.isEmpty {
                        ProgressView("LoadReceive Records...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if receiveStore.receiveTraceChildren.isEmpty {
                        EmptyStateView(asset: "bill_no_data", title: "No records")
                            .padding(.horizontal, widthClass.horizontalPadding)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(txRows) { row in
                                    self.row(row.item)
                                }
                            }
                            .padding(.horizontal, widthClass.horizontalPadding)
                            .padding(.vertical, 12)
                        }
                        .refreshable {
                            await receiveStore.loadReceiveTraceChildren(orderSN: orderSN)
                        }
                    }
                }
            }
            .navigationTitle("Receive Records")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await receiveStore.loadReceiveTraceChildren(orderSN: orderSN)
            }
        }
    }

    private var txRows: [ReceiveTxRow] {
        let seeds = receiveStore.receiveTraceChildren.map { item in
            StableRowID.make(
                item.orderSn,
                item.receiveAddress,
                fallback: "receive-tx-row"
            )
        }
        let ids = StableRowID.uniqued(seeds)
        return Array(zip(receiveStore.receiveTraceChildren, ids)).map { pair in
            ReceiveTxRow(id: pair.1, item: pair.0)
        }
    }

    private func row(_ item: TraceChildItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.orderSn ?? "-")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(ThemeTokens.secondary)
            Text("Address: \(item.receiveAddress ?? "-")")
                .font(.system(size: 13))
                .foregroundStyle(ThemeTokens.title)
                .lineLimit(1)
                .truncationMode(.middle)
            Text("Received: \(item.recvActualAmount?.description ?? "-")")
                .font(.system(size: 12))
                .foregroundStyle(ThemeTokens.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct ReceiveTxRow: Identifiable {
    let id: String
    let item: TraceChildItem
}
