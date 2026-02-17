import BackendAPI
import SwiftUI

struct ReceiveAddressDeleteView: View {
    @ObservedObject var state: AppState

    var body: some View {
        AdaptiveReader { widthClass in
            SafeAreaScreen(backgroundStyle: .globalImage) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("地址删除说明")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(ThemeTokens.title)
                                Text("当前后端仅提供失效与重建机制，不提供物理删除。你可以在下方直接重建同类型收款地址。")
                                    .font(.system(size: 13))
                                    .foregroundStyle(ThemeTokens.secondary)
                            }
                            .padding(14)
                        }

                        if filteredInvalidItems.isEmpty {
                            EmptyStateView(asset: "bill_no_data", title: "暂无失效地址")
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
            .navigationTitle("删除地址")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await state.loadReceiveAddresses(validity: .invalid)
            }
        }
    }

    private var filteredInvalidItems: [TraceOrderItem] {
        let source = state.receiveRecentInvalid
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
                Text("状态: 失效")
                    .font(.system(size: 12))
                    .foregroundStyle(ThemeTokens.secondary)
                Spacer()
                Button("重新生成") {
                    Task {
                        if (item.orderType ?? "").uppercased().contains("LONG") {
                            await state.createLongTraceOrder()
                        } else {
                            await state.createShortTraceOrder()
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
