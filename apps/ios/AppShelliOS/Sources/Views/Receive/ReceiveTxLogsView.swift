import BackendAPI
import SwiftUI

struct ReceiveTxLogsView: View {
    @ObservedObject var state: AppState
    let orderSN: String

    var body: some View {
        AdaptiveReader { widthClass in
            Group {
                if state.isLoading("receive.children") && state.receiveTraceChildren.isEmpty {
                    ProgressView("加载收款记录...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if state.receiveTraceChildren.isEmpty {
                    EmptyStateView(asset: "bill_no_data", title: "暂无记录")
                        .padding(.horizontal, widthClass.horizontalPadding)
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(Array(state.receiveTraceChildren.enumerated()), id: \.offset) { _, item in
                                row(item)
                            }
                        }
                        .padding(.horizontal, widthClass.horizontalPadding)
                        .padding(.vertical, 12)
                    }
                    .refreshable {
                        await state.loadReceiveTraceChildren(orderSN: orderSN)
                    }
                }
            }
            .background(Color.clear)
            .navigationTitle("收款记录")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await state.loadReceiveTraceChildren(orderSN: orderSN)
            }
        }
    }

    private func row(_ item: TraceChildItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.orderSn ?? "-")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(ThemeTokens.secondary)
            Text("地址: \(item.receiveAddress ?? "-")")
                .font(.system(size: 13))
                .foregroundStyle(ThemeTokens.title)
                .lineLimit(1)
                .truncationMode(.middle)
            Text("到账: \(item.recvActualAmount?.description ?? "-")")
                .font(.system(size: 12))
                .foregroundStyle(ThemeTokens.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
