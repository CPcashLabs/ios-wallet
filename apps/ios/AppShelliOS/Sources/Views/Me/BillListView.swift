import BackendAPI
import SwiftUI

private enum BillTab: String, CaseIterable {
    case all = "全部"
    case receipt = "收款"
    case payment = "转账"

    var orderType: String? {
        switch self {
        case .all:
            return nil
        case .receipt:
            return "RECEIPT"
        case .payment:
            return "PAYMENT"
        }
    }
}

struct BillListView: View {
    @ObservedObject var meStore: MeStore
    @ObservedObject var uiStore: UIStore
    var onShowStatistics: (() -> Void)? = nil
    var onSelectOrder: ((String) -> Void)? = nil

    @State private var selectedTab: BillTab = .all
    @State private var showFilterSheet = false
    @State private var showMoreSheet = false
    @State private var filterDraft = BillFilterDraft()
    @State private var isLoadingMore = false

    var body: some View {
        AdaptiveReader { widthClass in
            SafeAreaScreen(backgroundStyle: .globalImage) {
                VStack(spacing: 0) {
                    topBar(widthClass: widthClass)

                    if meStore.isLoading(.meBillList) && meStore.billList.isEmpty {
                        skeletonList(widthClass: widthClass)
                            .padding(.horizontal, widthClass.horizontalPadding)
                            .padding(.top, 14)
                    } else if meStore.billList.isEmpty {
                        EmptyStateView(asset: "bill_no_data", title: "暂无数据")
                            .padding(.horizontal, widthClass.horizontalPadding)
                            .padding(.top, 30)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(groupedKeys, id: \.self) { key in
                                    sectionCard(title: key, items: groupedMap[key] ?? [], widthClass: widthClass)
                                }

                                if !meStore.billLastPage {
                                    HStack {
                                        Spacer()
                                        if isLoadingMore {
                                            ProgressView()
                                        } else {
                                            Text("上拉加载更多")
                                                .font(.system(size: 12))
                                                .foregroundStyle(ThemeTokens.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                    .onAppear {
                                        Task { await loadMoreIfNeeded() }
                                    }
                                } else {
                                    Text("没有更多了")
                                        .font(.system(size: 12))
                                        .foregroundStyle(ThemeTokens.secondary)
                                        .padding(.vertical, 8)
                                }
                            }
                            .padding(.horizontal, widthClass.horizontalPadding)
                            .padding(.vertical, 12)
                        }
                        .scrollDismissesKeyboard(.interactively)
                    }
                }
            }
            .navigationTitle("账单")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showMoreSheet = true
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .buttonStyle(.pressFeedback)
                }
            }
            .confirmationDialog("更多操作", isPresented: $showMoreSheet, titleVisibility: .visible) {
                Button("统计") {
                    onShowStatistics?()
                }
                Button("导出交易记录") {
                    uiStore.showInfoToast("导出功能开发中")
                }
                Button("标签管理") {
                    uiStore.showInfoToast("标签管理开发中")
                }
            }
            .sheet(isPresented: $showFilterSheet) {
                BillFilterSheetView(draft: $filterDraft) {
                    Task { await reload(reset: true) }
                }
                .presentationDetents([.medium, .large])
            }
            .task(id: reloadTriggerKey) {
                await reload(reset: true)
            }
        }
    }

    private func topBar(widthClass: DeviceWidthClass) -> some View {
        HStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(BillTab.allCases, id: \.self) { tab in
                        Button {
                            selectedTab = tab
                        } label: {
                            Text(tab.rawValue)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(selectedTab == tab ? ThemeTokens.cpPrimary : ThemeTokens.title)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(ThemeTokens.cardBackground, in: Capsule())
                        }
                        .buttonStyle(.pressFeedback)
                    }
                }
            }

            Button {
                showFilterSheet = true
            } label: {
                HStack(spacing: 4) {
                    Text("筛选")
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(filterDraft == BillFilterDraft() ? ThemeTokens.secondary : ThemeTokens.cpPrimary)
            }
            .buttonStyle(.pressFeedback)
        }
        .padding(.horizontal, widthClass.horizontalPadding)
        .padding(.top, 8)
        .overlay(alignment: .bottomLeading) {
            if let address = meStore.billAddressFilter, !address.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                    Text(shortAddress(address))
                    Button {
                        meStore.setBillAddressFilter(nil)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(ThemeTokens.cpPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(ThemeTokens.cpPrimary.opacity(0.12))
                )
                .padding(.top, 44)
                .padding(.leading, widthClass.horizontalPadding)
            }
        }
    }

    private func sectionCard(title: String, items: [OrderSummary], widthClass: DeviceWidthClass) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ThemeTokens.title)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("支出(USDT) \(formatSectionAmount(sectionExpense(items)))")
                        .font(.system(size: widthClass.footnoteSize))
                        .foregroundStyle(ThemeTokens.secondary)
                    Text("收入(USDT) \(formatSectionAmount(sectionIncome(items)))")
                        .font(.system(size: widthClass.footnoteSize))
                        .foregroundStyle(ThemeTokens.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Divider()

            let rows = sectionRows(items)
            ForEach(rows) { row in
                billRow(row.item, widthClass: widthClass)
                if row.index < rows.count - 1 {
                    Divider().padding(.leading, 60)
                }
            }
        }
        .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: widthClass.metrics.cardCornerRadius, style: .continuous))
    }

    private func billRow(_ item: OrderSummary, widthClass: DeviceWidthClass) -> some View {
        Button {
            if let sn = item.orderSn {
                onSelectOrder?(sn)
            }
        } label: {
            HStack(spacing: 12) {
                rowAvatar(item)

                VStack(alignment: .leading, spacing: 3) {
                    Text(orderTypeTitle(item.orderType))
                        .font(.system(size: widthClass.bodySize + 1, weight: .semibold))
                        .foregroundStyle(ThemeTokens.title)
                    Text(counterpartyText(item))
                        .font(.system(size: widthClass.footnoteSize))
                        .foregroundStyle(ThemeTokens.secondary)
                        .lineLimit(1)
                    Text(timeText(item.createdAt))
                        .font(.system(size: 11))
                        .foregroundStyle(ThemeTokens.tertiary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(amountText(item))
                        .font(.system(size: widthClass.bodySize + 1, weight: .semibold))
                        .foregroundStyle(isReceiveType(item) ? ThemeTokens.success : ThemeTokens.title)
                        .lineLimit(1)
                    if let abnormalStatus = abnormalStatusText(item.status) {
                        Text(abnormalStatus)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(statusColor(item.status))
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
            .padding(.horizontal, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressFeedback)
    }

    private func rowAvatar(_ item: OrderSummary) -> some View {
        AddressSeedAvatar(
            size: 32,
            address: counterpartyAddress(item) ?? "-",
            avatarURL: item.avatar
        )
    }

    private func skeletonList(widthClass: DeviceWidthClass) -> some View {
        VStack(spacing: 12) {
            ForEach(0 ..< 3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: widthClass.metrics.cardCornerRadius)
                    .fill(ThemeTokens.cardBackground)
                    .frame(height: 132)
                    .overlay(alignment: .leading) {
                        VStack(alignment: .leading, spacing: 10) {
                            RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.18)).frame(width: 120, height: 12)
                            RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.15)).frame(width: 220, height: 10)
                            RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.12)).frame(width: 180, height: 10)
                        }
                        .padding(12)
                    }
            }
        }
    }

    private func reload(reset: Bool) async {
        let range: BillTimeRange?
        if let preset = filterDraft.rangePreset {
            range = meStore.billRangeForPreset(preset)
        } else {
            range = nil
        }
        let page = reset ? 1 : max(1, meStore.billCurrentPage + 1)
        let filter = BillFilter(
            page: page,
            perPage: 20,
            orderType: selectedTab.orderType,
            orderTypeList: filterDraft.showCompletedOnly ? ["COMPLETED"] : [],
            otherAddress: meStore.billAddressFilter,
            categoryIds: filterDraft.categoryIds,
            range: range
        )
        await meStore.loadBillList(filter: filter, append: !reset)
    }

    private func loadMoreIfNeeded() async {
        guard !meStore.billLastPage else { return }
        guard !isLoadingMore else { return }
        isLoadingMore = true
        await reload(reset: false)
        isLoadingMore = false
    }

    private var groupedMap: [String: [OrderSummary]] {
        Dictionary(grouping: meStore.billList) { item in
            monthKey(item.createdAt)
        }
    }

    private var groupedKeys: [String] {
        groupedMap.keys.sorted(by: >)
    }

    private var reloadTriggerKey: String {
        "\(selectedTab.rawValue)|\(meStore.billAddressFilter ?? "")"
    }

    private func monthKey(_ timestamp: Int?) -> String {
        DateTextFormatter.yearMonth(fromTimestamp: timestamp, fallback: "未知月份")
    }

    private func timeText(_ timestamp: Int?) -> String {
        DateTextFormatter.yearMonthDayMinute(fromTimestamp: timestamp, fallback: "-")
    }

    private func orderTypeTitle(_ orderType: String?) -> String {
        switch (orderType ?? "").uppercased() {
        case "RECEIPT", "RECEIPT_FIXED", "RECEIPT_NORMAL", "TRACE", "TRACE_CHILD", "TRACE_LONG_TERM":
            return "收款"
        case "PAYMENT", "PAYMENT_NORMAL":
            return "转账"
        default:
            return "交易"
        }
    }

    private func isReceiveType(_ item: OrderSummary) -> Bool {
        let type = (item.orderType ?? "").uppercased()
        if type.isEmpty {
            return selectedTab == .receipt
        }
        return ["RECEIPT", "RECEIPT_FIXED", "RECEIPT_NORMAL", "TRACE", "TRACE_CHILD", "TRACE_LONG_TERM"].contains(type)
    }

    private func amountText(_ item: OrderSummary) -> String {
        let receive = isReceiveType(item)
        let amount = receive ? jsonDouble(item.recvAmount) : jsonDouble(item.sendAmount)
        let coin = receive ? (item.recvCoinName ?? "USDT") : (item.sendCoinName ?? "USDT")
        let sign = receive ? "+" : "-"
        return "\(sign)\(formatSectionAmount(amount)) \(coin)"
    }

    private func counterpartyText(_ item: OrderSummary) -> String {
        shortAddress(counterpartyAddress(item) ?? "-")
    }

    private func counterpartyAddress(_ item: OrderSummary) -> String? {
        if isReceiveType(item) {
            return item.paymentAddress ?? item.receiveAddress
        }
        return item.receiveAddress ?? item.paymentAddress
    }

    private func sectionExpense(_ items: [OrderSummary]) -> Double {
        items.reduce(0) { partial, item in
            partial + (isReceiveType(item) ? 0 : jsonDouble(item.sendAmount))
        }
    }

    private func sectionIncome(_ items: [OrderSummary]) -> Double {
        items.reduce(0) { partial, item in
            partial + (isReceiveType(item) ? jsonDouble(item.recvAmount) : 0)
        }
    }

    private func jsonDouble(_ value: JSONValue?) -> Double {
        if let value = value?.doubleValue { return value }
        if let text = value?.stringValue, let parsed = Double(text) { return parsed }
        return 0
    }

    private func formatSectionAmount(_ value: Double) -> String {
        if value == 0 { return "0.00" }
        return String(format: "%.2f", value)
    }

    private func shortAddress(_ value: String) -> String {
        AddressFormatter.shortened(value, leading: 6, trailing: 4, threshold: 14)
    }

    private func abnormalStatusText(_ status: Int?) -> String? {
        guard let status else { return nil }
        switch status {
        case 1:
            return "待处理"
        case 2:
            return "处理中"
        case -5, -4, -3, -2, -1, 0:
            return "失败"
        default:
            return nil
        }
    }

    private func statusColor(_ status: Int?) -> Color {
        switch status ?? 0 {
        case 2:
            return ThemeTokens.warning
        case 1:
            return ThemeTokens.secondary
        default:
            return ThemeTokens.danger
        }
    }

    private func sectionRows(_ items: [OrderSummary]) -> [BillSectionRow] {
        Array(items.enumerated()).map { index, item in
            let createdSeed = item.createdAt.map(String.init) ?? "row"
            let seed = item.orderSn ?? createdSeed
            return BillSectionRow(id: "\(seed)-\(index)", index: index, item: item)
        }
    }

}

private struct BillSectionRow: Identifiable {
    let id: String
    let index: Int
    let item: OrderSummary
}

#Preview("BillListView") {
    NavigationStack {
        let appState = AppState()
        BillListView(meStore: MeStore(appState: appState), uiStore: UIStore(appState: appState))
    }
}
