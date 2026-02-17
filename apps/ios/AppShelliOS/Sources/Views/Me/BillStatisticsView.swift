import BackendAPI
import SwiftUI

private enum StatsPreset: String, CaseIterable {
    case today = "Today"
    case yesterday = "Yesterday"
    case last7Days = "Last 7 Days"
    case monthly = "Monthly"

    var billPreset: BillPresetRange {
        switch self {
        case .today:
            return .today
        case .yesterday:
            return .yesterday
        case .last7Days:
            return .last7Days
        case .monthly:
            return .monthly
        }
    }
}

struct BillStatisticsView: View {
    @ObservedObject var state: AppState
    var onAddressTap: ((String) -> Void)? = nil

    @State private var preset: StatsPreset = .today
    @State private var selectedMonth = Date()

    var body: some View {
        AdaptiveReader { widthClass in
            FullscreenScaffold(backgroundStyle: .globalImage) {
                ScrollView {
                    VStack(spacing: 12) {
                        presetBar

                        VStack(alignment: .leading, spacing: 14) {
                            if preset == .monthly {
                                DatePicker(
                                    "月份",
                                    selection: $selectedMonth,
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            summaryMetrics(widthClass: widthClass)

                            Divider()

                            addressTable(widthClass: widthClass)
                        }
                        .padding(14)
                        .background(ThemeTokens.cardBackground, in: RoundedRectangle(cornerRadius: widthClass.metrics.cardCornerRadius, style: .continuous))
                    }
                    .padding(.horizontal, widthClass.horizontalPadding)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("统计")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await reload()
            }
            .onChange(of: preset) { _, _ in
                Task { await reload() }
            }
            .onChange(of: selectedMonth) { _, _ in
                if preset == .monthly {
                    Task { await reload() }
                }
            }
        }
    }

    private var presetBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(StatsPreset.allCases, id: \.self) { item in
                    Button {
                        preset = item
                    } label: {
                        Text(item.rawValue)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(preset == item ? ThemeTokens.cpPrimary : ThemeTokens.title)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(ThemeTokens.cardBackground, in: Capsule())
                    }
                    .buttonStyle(.pressFeedback)
                }
            }
        }
    }

    private func summaryMetrics(widthClass: DeviceWidthClass) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("仅统计已完成交易")
                .font(.system(size: widthClass.footnoteSize))
                .foregroundStyle(ThemeTokens.secondary)

            HStack(spacing: 30) {
                metricItem("支出(USDT)", valueText(state.billStats?.paymentAmount), widthClass: widthClass)
                metricItem("收入(USDT)", valueText(state.billStats?.receiptAmount), widthClass: widthClass)
            }
            HStack(spacing: 30) {
                metricItem("手续费(USDT)", valueText(state.billStats?.fee), widthClass: widthClass)
                metricItem("交易数", String(state.billStats?.transactions ?? 0), widthClass: widthClass)
            }
        }
    }

    private func addressTable(widthClass: DeviceWidthClass) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("交易对象")
                    .font(.system(size: widthClass.footnoteSize, weight: .medium))
                Spacer()
                Text("支出")
                    .font(.system(size: widthClass.footnoteSize, weight: .medium))
                    .frame(width: 76, alignment: .trailing)
                Text("收入")
                    .font(.system(size: widthClass.footnoteSize, weight: .medium))
                    .frame(width: 76, alignment: .trailing)
            }
            .foregroundStyle(ThemeTokens.secondary)
            .padding(.horizontal, 2)
            .padding(.vertical, 10)

            Divider()

            if state.isLoading("me.bill.aggregate") {
                ProgressView("加载中")
                    .padding(.vertical, 22)
            } else if state.billAddressAggList.isEmpty {
                EmptyStateView(asset: "bill_no_data", title: "暂无数据")
                    .padding(.vertical, 16)
            } else {
                ForEach(Array(state.billAddressAggList.enumerated()), id: \.offset) { index, item in
                    Button {
                        if let onAddressTap, let address = item.adversaryAddress {
                            onAddressTap(address)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            rowAvatar(item)
                            Text(item.name ?? shortAddress(item.adversaryAddress ?? "-"))
                                .font(.system(size: 13))
                                .foregroundStyle(ThemeTokens.title)
                                .lineLimit(1)
                            Spacer()
                            Text(valueText(item.paymentAmount))
                                .font(.system(size: 12))
                                .foregroundStyle(ThemeTokens.secondary)
                                .frame(width: 76, alignment: .trailing)
                            Text(valueText(item.receiptAmount))
                                .font(.system(size: 12))
                                .foregroundStyle(ThemeTokens.secondary)
                                .frame(width: 76, alignment: .trailing)
                        }
                        .padding(.vertical, 11)
                        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.pressFeedback)

                    if index < state.billAddressAggList.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

    private func rowAvatar(_ item: BillAddressAggregateItem) -> some View {
        AddressSeedAvatar(
            size: 30,
            address: item.adversaryAddress ?? item.name ?? "A",
            avatarURL: item.avatar
        )
    }

    private func metricItem(_ title: String, _ value: String, widthClass: DeviceWidthClass) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: widthClass.footnoteSize))
                .foregroundStyle(ThemeTokens.secondary)
            Text(value)
                .font(.system(size: widthClass.titleSize + 2, weight: .bold))
                .foregroundStyle(ThemeTokens.title)
                .lineLimit(1)
        }
    }

    private func reload() async {
        let range = state.billRangeForPreset(preset.billPreset, selectedMonth: selectedMonth)
        await state.loadBillStatistics(range: range)
        await state.loadBillAddressAggregate(range: range)
    }

    private func shortAddress(_ value: String) -> String {
        guard value.count > 14 else { return value }
        return "\(value.prefix(8))...\(value.suffix(4))"
    }

    private func valueText(_ value: JSONValue?) -> String {
        guard let value else { return "0.00" }
        if let number = value.doubleValue {
            return String(format: "%.2f", number)
        }
        return value.description
    }
}
