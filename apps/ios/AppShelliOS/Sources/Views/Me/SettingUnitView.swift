import BackendAPI
import SwiftUI

struct SettingUnitView: View {
    @ObservedObject var meStore: MeStore

    @State private var currentCurrency = ""

    var body: some View {
        AdaptiveReader { widthClass in
            SafeAreaScreen(backgroundStyle: .globalImage) {
                Group {
                    if meStore.isLoading(.meSettingsRates) {
                        ProgressView("加载中...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            SectionCard {
                                ForEach(currencyRows) { row in
                                    let item = row.item
                                    Button {
                                        currentCurrency = item.currency ?? ""
                                    } label: {
                                        HStack {
                                            Text(item.currency ?? "-")
                                                .font(.system(size: widthClass.bodySize + 1))
                                                .foregroundStyle(ThemeTokens.title)
                                            Spacer()
                                            if currentCurrency == item.currency {
                                                Image("settings_radio_checked")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 20, height: 20)
                                            }
                                        }
                                        .frame(minHeight: widthClass.metrics.listRowMinHeight)
                                        .padding(.horizontal, 14)
                                    }
                                    .buttonStyle(.plain)

                                    if row.index < currencyRows.count - 1 {
                                        Divider().padding(.leading, 14)
                                    }
                                }
                            }
                            .padding(.horizontal, widthClass.horizontalPadding)
                            .padding(.vertical, 12)
                        }
                    }
                }
            }
            .navigationTitle("货币单位")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        if !currentCurrency.isEmpty {
                            meStore.saveCurrencyUnit(currency: currentCurrency)
                        }
                    }
                }
            }
            .task {
                await meStore.loadExchangeRates()
                if currentCurrency.isEmpty {
                    currentCurrency = meStore.selectedCurrency
                }
            }
        }
    }

    private var currencyRows: [CurrencyRow] {
        let seeds = meStore.exchangeRates.map { item in
            StableRowID.make(
                item.currency,
                item.symbol,
                fallback: "currency-row"
            )
        }
        let ids = StableRowID.uniqued(seeds)
        return Array(zip(meStore.exchangeRates, ids).enumerated()).map { index, pair in
            CurrencyRow(id: pair.1, index: index, item: pair.0)
        }
    }
}

private struct CurrencyRow: Identifiable {
    let id: String
    let index: Int
    let item: ExchangeRateItem
}
