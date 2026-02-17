import BackendAPI
import Combine
import Foundation

@MainActor
final class MeStore: ObservableObject {
    private let appState: AppState
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var profile: UserProfile?
    @Published private(set) var messageList: [MessageItem]
    @Published private(set) var messagePage: Int
    @Published private(set) var messageLastPage: Bool
    @Published private(set) var addressBooks: [AddressBookItem]
    @Published private(set) var billList: [OrderSummary]
    @Published private(set) var billStats: BillStatisticsSummary?
    @Published private(set) var billAddressAggList: [BillAddressAggregateItem]
    @Published private(set) var billCurrentPage: Int
    @Published private(set) var billLastPage: Bool
    @Published private(set) var exchangeRates: [ExchangeRateItem]
    @Published private(set) var selectedCurrency: String
    @Published private(set) var transferEmailNotify: Bool
    @Published private(set) var rewardEmailNotify: Bool
    @Published private(set) var receiptEmailNotify: Bool
    @Published private(set) var backupWalletNotify: Bool
    @Published private(set) var billAddressFilter: String?

    init(appState: AppState) {
        self.appState = appState
        profile = appState.meProfile
        messageList = appState.messageList
        messagePage = appState.messagePage
        messageLastPage = appState.messageLastPage
        addressBooks = appState.addressBooks
        billList = appState.billList
        billStats = appState.billStats
        billAddressAggList = appState.billAddressAggList
        billCurrentPage = appState.billCurrentPage
        billLastPage = appState.billLastPage
        exchangeRates = appState.exchangeRates
        selectedCurrency = appState.selectedCurrency
        transferEmailNotify = appState.transferEmailNotify
        rewardEmailNotify = appState.rewardEmailNotify
        receiptEmailNotify = appState.receiptEmailNotify
        backupWalletNotify = appState.backupWalletNotify
        billAddressFilter = appState.billAddressFilter

        bind()
    }

    func loadMeRootData() async {
        await appState.loadMeRootData()
    }

    func loadMessages(page: Int, append: Bool) async {
        await appState.loadMessages(page: page, append: append)
    }

    func loadAddressBooks() async {
        await appState.loadAddressBooks()
    }

    func loadBillList(filter: BillFilter, append: Bool = false) async {
        await appState.loadBillList(filter: filter, append: append)
    }

    func loadBillStatistics(range: BillTimeRange) async {
        await appState.loadBillStatistics(range: range)
    }

    func loadBillAddressAggregate(range: BillTimeRange, page: Int = 1, perPage: Int = 50) async {
        await appState.loadBillAddressAggregate(range: range, page: page, perPage: perPage)
    }

    func billRangeForPreset(_ preset: BillPresetRange, selectedMonth: Date = Date()) -> BillTimeRange {
        appState.billRangeForPreset(preset, selectedMonth: selectedMonth)
    }

    func updateNickname(_ nickname: String) async {
        await appState.updateNickname(nickname)
    }

    func updateAvatar(fileData: Data, fileName: String = "avatar.jpg", mimeType: String = "image/jpeg") async {
        await appState.updateAvatar(fileData: fileData, fileName: fileName, mimeType: mimeType)
    }

    func setBillAddressFilter(_ address: String?) {
        appState.setBillAddressFilter(address)
    }

    func isLoading(_ key: LoadKey) -> Bool {
        appState.isLoading(key)
    }

    func errorMessage(_ key: LoadKey) -> String? {
        appState.errorMessage(key)
    }

    func loadExchangeRates() async {
        await appState.loadExchangeRates()
    }

    func saveCurrencyUnit(currency: String) {
        appState.saveCurrencyUnit(currency: currency)
    }

    func setTransferEmailNotify(_ enable: Bool) async {
        await appState.setTransferEmailNotify(enable)
    }

    func setRewardEmailNotify(_ enable: Bool) async {
        await appState.setRewardEmailNotify(enable)
    }

    func setReceiptEmailNotify(_ enable: Bool) async {
        await appState.setReceiptEmailNotify(enable)
    }

    func setBackupWalletNotify(_ enable: Bool) async {
        await appState.setBackupWalletNotify(enable)
    }

    private func bind() {
        appState.$meProfile
            .sink { [weak self] in self?.profile = $0 }
            .store(in: &cancellables)

        appState.$messageList
            .sink { [weak self] in self?.messageList = $0 }
            .store(in: &cancellables)

        appState.$messagePage
            .sink { [weak self] in self?.messagePage = $0 }
            .store(in: &cancellables)

        appState.$messageLastPage
            .sink { [weak self] in self?.messageLastPage = $0 }
            .store(in: &cancellables)

        appState.$addressBooks
            .sink { [weak self] in self?.addressBooks = $0 }
            .store(in: &cancellables)

        appState.$billList
            .sink { [weak self] in self?.billList = $0 }
            .store(in: &cancellables)

        appState.$billStats
            .sink { [weak self] in self?.billStats = $0 }
            .store(in: &cancellables)

        appState.$billAddressAggList
            .sink { [weak self] in self?.billAddressAggList = $0 }
            .store(in: &cancellables)

        appState.$billCurrentPage
            .sink { [weak self] in self?.billCurrentPage = $0 }
            .store(in: &cancellables)

        appState.$billLastPage
            .sink { [weak self] in self?.billLastPage = $0 }
            .store(in: &cancellables)

        appState.$exchangeRates
            .sink { [weak self] in self?.exchangeRates = $0 }
            .store(in: &cancellables)

        appState.$selectedCurrency
            .sink { [weak self] in self?.selectedCurrency = $0 }
            .store(in: &cancellables)

        appState.$transferEmailNotify
            .sink { [weak self] in self?.transferEmailNotify = $0 }
            .store(in: &cancellables)

        appState.$rewardEmailNotify
            .sink { [weak self] in self?.rewardEmailNotify = $0 }
            .store(in: &cancellables)

        appState.$receiptEmailNotify
            .sink { [weak self] in self?.receiptEmailNotify = $0 }
            .store(in: &cancellables)

        appState.$backupWalletNotify
            .sink { [weak self] in self?.backupWalletNotify = $0 }
            .store(in: &cancellables)

        appState.$billAddressFilter
            .sink { [weak self] in self?.billAddressFilter = $0 }
            .store(in: &cancellables)
    }
}
