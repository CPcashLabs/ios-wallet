import BackendAPI
import Foundation

@MainActor
final class BillUseCase {
    private unowned let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func loadBillList(filter: BillFilter, append: Bool) async {
        await appState.loadBillListImpl(filter: filter, append: append)
    }

    func setBillAddressFilter(_ address: String?) {
        appState.setBillAddressFilterImpl(address)
    }

    func loadBillStatistics(range: BillTimeRange) async {
        await appState.loadBillStatisticsImpl(range: range)
    }

    func loadBillAddressAggregate(range: BillTimeRange, page: Int, perPage: Int) async {
        await appState.loadBillAddressAggregateImpl(range: range, page: page, perPage: perPage)
    }

    func billRangeForPreset(_ preset: BillPresetRange, selectedMonth: Date) -> BillTimeRange {
        appState.billRangeForPresetImpl(preset, selectedMonth: selectedMonth)
    }
}
